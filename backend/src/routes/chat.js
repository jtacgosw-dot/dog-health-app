const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { chatRateLimit } = require('../middleware/rateLimit');
const { generateAIResponse } = require('../services/openai');
const supabase = require('../services/supabase');
const { body, validationResult } = require('express-validator');

/**
 * POST /api/chat
 * Send a message and get AI response
 */
router.post('/',
  authenticateToken,
  chatRateLimit,
  [
    body('message').notEmpty().withMessage('Message is required'),
    body('conversationId').optional({ values: 'null' }).isUUID().withMessage('Invalid conversation ID'),
    body('dogId').optional({ values: 'null' }).isUUID().withMessage('Invalid dog ID')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

            const { message, conversationId, dogId, dogProfile: clientDogProfile, healthLogs: clientHealthLogs, images, carePlanContext } = req.body;
            const userId = req.user.id;

      let currentConversationId = conversationId;

      if (!currentConversationId) {
        const { data: newConversation, error: convError } = await supabase
          .from('conversations')
          .insert([{
            user_id: userId,
            dog_id: dogId || null
          }])
          .select()
          .single();

        if (convError) {
          console.error('Conversation creation error:', convError);
          throw new Error(`Failed to create conversation: ${convError.message}`);
        }

        currentConversationId = newConversation.id;
      }

      const { data: conversation, error: convCheckError } = await supabase
        .from('conversations')
        .select('*')
        .eq('id', currentConversationId)
        .eq('user_id', userId)
        .single();

      if (convCheckError || !conversation) {
        return res.status(403).json({ error: 'Conversation not found or access denied' });
      }

      const { error: userMsgError } = await supabase
        .from('messages')
        .insert([{
          conversation_id: currentConversationId,
          role: 'user',
          content: message
        }]);

      if (userMsgError) {
        console.error('User message save error:', userMsgError);
        throw new Error(`Failed to save user message: ${userMsgError.message}`);
      }

            let dogProfile = null;
            let healthLogs = null;

            // Use client-provided dog profile and health logs if available (from local SwiftData)
            // This allows the AI to have context even without Supabase sync
            if (clientDogProfile) {
              dogProfile = {
                name: clientDogProfile.name,
                breed: clientDogProfile.breed,
                age: clientDogProfile.age,
                weight: clientDogProfile.weight,
                health_concerns: clientDogProfile.healthConcerns,
                allergies: clientDogProfile.allergies
              };
            }

            if (clientHealthLogs && clientHealthLogs.length > 0) {
              healthLogs = clientHealthLogs.map(log => ({
                log_type: log.logType,
                timestamp: log.timestamp,
                notes: log.notes,
                meal_type: log.mealType,
                amount: log.amount,
                duration: log.duration,
                mood_level: log.moodLevel,
                symptom_type: log.symptomType,
                severity_level: log.severityLevel,
                digestion_quality: log.digestionQuality,
                activity_type: log.activityType,
                supplement_name: log.supplementName,
                dosage: log.dosage,
                appointment_type: log.appointmentType,
                location: log.location,
                grooming_type: log.groomingType,
                treat_name: log.treatName,
                water_amount: log.waterAmount
              }));
            }

            // Fall back to database queries if client didn't provide data
            if (!dogProfile && conversation.dog_id) {
              const { data: dog } = await supabase
                .from('dogs')
                .select('*')
                .eq('id', conversation.dog_id)
                .single();
              dogProfile = dog;
            }

            if (!healthLogs && conversation.dog_id) {
              // Fetch recent health logs (last 30 days) for comprehensive AI context
              const thirtyDaysAgo = new Date();
              thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

              const { data: logs } = await supabase
                .from('health_logs')
                .select('*')
                .eq('dog_id', conversation.dog_id)
                .eq('user_id', userId)
                .gte('timestamp', thirtyDaysAgo.toISOString())
                .order('timestamp', { ascending: false })
                .limit(100);

              healthLogs = logs;
            }

      // Log image info for debugging (without logging actual base64 data)
      if (images && images.length > 0) {
        console.log(`Chat request includes ${images.length} image(s), first image length: ${images[0]?.length || 0} chars`);
      }

      const aiResponse = await generateAIResponse(message, currentConversationId, dogProfile, healthLogs, images, carePlanContext);

      const { data: assistantMessage, error: aiMsgError } = await supabase
        .from('messages')
        .insert([{
          conversation_id: currentConversationId,
          role: 'assistant',
          content: aiResponse.content,
          tokens_used: aiResponse.tokensUsed,
          model_used: aiResponse.model
        }])
        .select()
        .single();

      if (aiMsgError) {
        console.error('AI message save error:', aiMsgError);
        throw new Error(`Failed to save AI response: ${aiMsgError.message}`);
      }

      // Update conversation's updated_at timestamp so chat history shows correct time
      await supabase
        .from('conversations')
        .update({ updated_at: new Date().toISOString() })
        .eq('id', currentConversationId);

      await supabase
        .from('usage_analytics')
        .insert([{
          user_id: userId,
          event_type: 'chat_message_sent',
          event_data: {
            conversation_id: currentConversationId,
            tokens_used: aiResponse.tokensUsed
          }
        }]);

      // Auto-generate title for new conversations (first message)
      // Check if this is a new conversation without a custom title
      const { data: convForTitle, error: titleCheckError } = await supabase
        .from('conversations')
        .select('title')
        .eq('id', currentConversationId)
        .single();

      if (titleCheckError) {
        console.log('[Chat] Error checking conversation title:', titleCheckError);
      }

      console.log('[Chat] Current title for conversation', currentConversationId, ':', convForTitle?.title);

      // Generate title if: no title, null title, empty title, or default titles
      const needsTitle = !convForTitle?.title ||
                         convForTitle.title === '' ||
                         convForTitle.title === 'Chat' ||
                         convForTitle.title === 'New Chat' ||
                         convForTitle.title === 'New Conversation';

      if (needsTitle) {
        // Generate a short title from the user's first message
        const titleWords = message.split(' ').slice(0, 5).join(' ');
        const autoTitle = titleWords.length > 30 ? titleWords.substring(0, 30) + '...' : titleWords;

        console.log('[Chat] Generating auto-title:', autoTitle);

        const { error: titleUpdateError } = await supabase
          .from('conversations')
          .update({ title: autoTitle })
          .eq('id', currentConversationId);

        if (titleUpdateError) {
          console.error('[Chat] Failed to update conversation title:', titleUpdateError);
        } else {
          console.log('[Chat] Successfully updated conversation title to:', autoTitle);
        }
      }

      res.status(200).json({
        success: true,
        conversationId: currentConversationId,
        message: {
          id: assistantMessage.id,
          role: 'assistant',
          content: aiResponse.content,
          createdAt: assistantMessage.created_at
        }
      });
    } catch (error) {
      console.error('Chat error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to process message',
        message: error.message
      });
    }
  }
);

/**
 * GET /api/chat/conversations
 * Get user's conversations
 */
router.get('/conversations',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;
      const { limit = 20, offset = 0 } = req.query;

      const { data: conversations, error } = await supabase
        .from('conversations')
        .select(`
          id,
          title,
          created_at,
          updated_at,
          is_pinned,
          is_archived,
          dog_id,
          dogs (
            id,
            name,
            breed
          ),
          messages (
            id,
            content,
            role,
            created_at
          )
        `)
        .eq('user_id', userId)
        .eq('is_archived', false)
        .order('updated_at', { ascending: false })
        .range(offset, offset + limit - 1);

      if (error) {
        throw new Error('Failed to fetch conversations');
      }

      // Filter out conversations with no messages and add message count + preview
      const conversationsWithMessages = (conversations || [])
        .filter(conv => conv.messages && conv.messages.length > 0)
        .map(conv => {
          // Sort messages by created_at to get the last one
          const sortedMessages = conv.messages.sort((a, b) =>
            new Date(b.created_at) - new Date(a.created_at)
          );
          const lastMessage = sortedMessages[0];

          return {
            ...conv,
            messageCount: conv.messages.length,
            lastMessagePreview: lastMessage ? lastMessage.content.substring(0, 100) : null,
            lastMessageRole: lastMessage ? lastMessage.role : null,
            lastMessageCreatedAt: lastMessage ? lastMessage.created_at : null,
            messages: undefined // Remove the messages array to reduce payload
          };
        });

      res.status(200).json({
        success: true,
        conversations: conversationsWithMessages
      });
    } catch (error) {
      console.error('Fetch conversations error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch conversations',
        message: error.message
      });
    }
  }
);

/**
 * GET /api/chat/conversations/:id/messages
 * Get messages for a conversation
 */
router.get('/conversations/:id/messages',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;
      const conversationId = req.params.id;
      const { limit = 50, offset = 0 } = req.query;

      const { data: conversation, error: convError } = await supabase
        .from('conversations')
        .select('*')
        .eq('id', conversationId)
        .eq('user_id', userId)
        .single();

      if (convError || !conversation) {
        return res.status(403).json({ error: 'Conversation not found or access denied' });
      }

      const { data: messages, error: msgError } = await supabase
        .from('messages')
        .select('id, role, content, created_at, feedback')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true })
        .range(offset, offset + limit - 1);

      if (msgError) {
        throw new Error('Failed to fetch messages');
      }

      res.status(200).json({
        success: true,
        messages: messages || []
      });
    } catch (error) {
      console.error('Fetch messages error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch messages',
        message: error.message
      });
    }
  }
);

/**
 * DELETE /api/chat/conversations/:id
 * Delete a conversation
 */
router.delete('/conversations/:id',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;
      const conversationId = req.params.id;

      // Verify the conversation belongs to the user
      const { data: conversation, error: convError } = await supabase
        .from('conversations')
        .select('*')
        .eq('id', conversationId)
        .eq('user_id', userId)
        .single();

      if (convError || !conversation) {
        return res.status(403).json({ error: 'Conversation not found or access denied' });
      }

      // Delete all messages in the conversation first
      await supabase
        .from('messages')
        .delete()
        .eq('conversation_id', conversationId);

      // Delete the conversation
      const { error: deleteError } = await supabase
        .from('conversations')
        .delete()
        .eq('id', conversationId);

      if (deleteError) {
        throw new Error('Failed to delete conversation');
      }

      res.status(200).json({
        success: true,
        message: 'Conversation deleted successfully'
      });
    } catch (error) {
      console.error('Delete conversation error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to delete conversation',
        message: error.message
      });
    }
  }
);

/**
 * PATCH /api/chat/conversations/:id
 * Update a conversation (rename)
 */
router.patch('/conversations/:id',
  authenticateToken,
  [
    body('title').optional().isString().withMessage('Title must be a string')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const conversationId = req.params.id;
      const { title } = req.body;

      // Verify the conversation belongs to the user
      const { data: conversation, error: convError } = await supabase
        .from('conversations')
        .select('*')
        .eq('id', conversationId)
        .eq('user_id', userId)
        .single();

      if (convError || !conversation) {
        return res.status(403).json({ error: 'Conversation not found or access denied' });
      }

      // Update the conversation
      const updateData = {};
      if (title !== undefined) {
        updateData.title = title;
      }
      updateData.updated_at = new Date().toISOString();

      const { data: updatedConversation, error: updateError } = await supabase
        .from('conversations')
        .update(updateData)
        .eq('id', conversationId)
        .select()
        .single();

      if (updateError) {
        throw new Error('Failed to update conversation');
      }

      res.status(200).json({
        success: true,
        conversation: updatedConversation
      });
    } catch (error) {
      console.error('Update conversation error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to update conversation',
        message: error.message
      });
    }
  }
);

/**
 * POST /api/chat/messages/:id/feedback
 * Submit feedback for a message
 */
router.post('/messages/:id/feedback',
  authenticateToken,
  [
    body('feedback').isIn(['positive', 'negative']).withMessage('Invalid feedback value'),
    body('comment').optional().isString()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const messageId = req.params.id;
      const { feedback, comment } = req.body;
      const userId = req.user.id;

      const { data: message, error: msgError } = await supabase
        .from('messages')
        .select(`
          id,
          conversation_id,
          conversations!inner (
            user_id
          )
        `)
        .eq('id', messageId)
        .single();

      if (msgError || !message || message.conversations.user_id !== userId) {
        return res.status(403).json({ error: 'Message not found or access denied' });
      }

      const { error: updateError } = await supabase
        .from('messages')
        .update({
          feedback,
          feedback_comment: comment || null
        })
        .eq('id', messageId);

      if (updateError) {
        throw new Error('Failed to update feedback');
      }

      res.status(200).json({
        success: true,
        message: 'Feedback submitted successfully'
      });
    } catch (error) {
      console.error('Submit feedback error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to submit feedback',
        message: error.message
      });
    }
  }
);

module.exports = router;
