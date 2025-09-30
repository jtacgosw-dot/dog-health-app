const express = require('express');
const OpenAI = require('openai');
const supabase = require('../utils/supabase');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const SAFETY_DISCLAIMER = "\n\n⚠️ **Important Safety Notice**: This information is for general guidance only and is not a substitute for professional veterinary advice. If your dog is showing serious symptoms, experiencing an emergency, or you have urgent concerns about their health, please contact your veterinarian or an emergency animal hospital immediately.";

const SYSTEM_PROMPT = `You are a helpful assistant providing general information about dog health, care, nutrition, and wellness. You should:

1. Provide helpful, accurate, and safe information about dog health topics
2. Be friendly and supportive to concerned pet owners
3. Always emphasize the importance of professional veterinary care for serious issues
4. Suggest when symptoms warrant immediate veterinary attention
5. Focus on general care, prevention, and wellness tips
6. Never diagnose specific medical conditions
7. Always recommend consulting a veterinarian for medical concerns

Remember: You are providing general information only, not medical advice. Always encourage users to consult with qualified veterinary professionals for their dog's health needs.`;

router.post('/', authenticateToken, async (req, res) => {
  try {
    const { message, conversationHistory = [] } = req.body;
    const userId = req.user.userId;

    const { data: entitlement, error: entitlementError } = await supabase
      .from('entitlements')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (entitlementError || !entitlement || !entitlement.is_active) {
      return res.status(403).json({ 
        error: 'Active subscription required',
        requiresSubscription: true
      });
    }

    const isActive = entitlement.is_active && 
      (!entitlement.renews_at || new Date(entitlement.renews_at) > new Date());

    if (!isActive) {
      await supabase
        .from('entitlements')
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .eq('user_id', userId);

      return res.status(403).json({ 
        error: 'Subscription expired',
        requiresSubscription: true
      });
    }

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({ 
        error: 'Message is required and must be a non-empty string' 
      });
    }

    if (!process.env.OPENAI_API_KEY) {
      return res.status(500).json({ 
        error: 'OpenAI API key not configured' 
      });
    }

    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...conversationHistory.slice(-10),
      { role: 'user', content: message }
    ];

    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: messages,
      max_tokens: 500,
      temperature: 0.7,
    });

    const aiResponse = completion.choices[0].message.content;
    const responseWithDisclaimer = aiResponse + SAFETY_DISCLAIMER;

    res.json({
      response: responseWithDisclaimer,
      timestamp: new Date().toISOString(),
      conversationId: req.body.conversationId || null
    });

  } catch (error) {
    console.error('Chat API Error:', error);
    
    if (error.code === 'insufficient_quota') {
      return res.status(402).json({ 
        error: 'OpenAI API quota exceeded. Please check your billing.' 
      });
    }
    
    if (error.code === 'invalid_api_key') {
      return res.status(401).json({ 
        error: 'Invalid OpenAI API key' 
      });
    }

    res.status(500).json({ 
      error: 'Failed to process chat message',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;
