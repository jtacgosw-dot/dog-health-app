const OpenAI = require('openai');
const supabase = require('./supabase');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

/**
 * Generate AI response for dog health query
 * @param {string} userMessage - User's message
 * @param {string} conversationId - Conversation ID for context
 * @param {object} dogProfile - Dog's profile information
 * @returns {Promise<object>} AI response with content and metadata
 */
async function generateAIResponse(userMessage, conversationId, dogProfile = null) {
  try {
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('role, content')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true })
      .limit(20); // Last 20 messages for context

    if (messagesError) {
      console.error('Error fetching conversation history:', messagesError);
    }

    const conversationHistory = messages || [];

    let systemPrompt = `You are a knowledgeable and caring dog health assistant. Your role is to provide helpful guidance and educational information about dog health, behavior, and care.

IMPORTANT GUIDELINES:
- You are NOT a veterinarian and cannot provide medical diagnoses
- Always recommend consulting a veterinarian for serious health concerns
- Provide educational information and general guidance
- Be empathetic and supportive
- Ask clarifying questions when needed
- If symptoms sound serious (difficulty breathing, severe pain, bleeding, etc.), strongly recommend immediate veterinary care

Your responses should be:
- Clear and easy to understand
- Practical and actionable
- Supportive and non-judgmental
- Focused on the dog's wellbeing`;

    if (dogProfile) {
      systemPrompt += `\n\nDog Profile:
- Name: ${dogProfile.name}
- Breed: ${dogProfile.breed || 'Unknown'}
- Age: ${dogProfile.age_years ? `${dogProfile.age_years} years` : 'Unknown'}${dogProfile.age_months ? ` ${dogProfile.age_months} months` : ''}
- Weight: ${dogProfile.weight_lbs ? `${dogProfile.weight_lbs} lbs` : 'Unknown'}
- Sex: ${dogProfile.sex || 'Unknown'}
- Neutered/Spayed: ${dogProfile.is_neutered !== null ? (dogProfile.is_neutered ? 'Yes' : 'No') : 'Unknown'}
${dogProfile.medical_history ? `- Medical History: ${dogProfile.medical_history}` : ''}
${dogProfile.allergies ? `- Allergies: ${dogProfile.allergies}` : ''}
${dogProfile.current_medications ? `- Current Medications: ${dogProfile.current_medications}` : ''}`;
    }

    const openaiMessages = [
      { role: 'system', content: systemPrompt },
      ...conversationHistory.map(msg => ({
        role: msg.role,
        content: msg.content
      })),
      { role: 'user', content: userMessage }
    ];

    const completion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      messages: openaiMessages,
      temperature: 0.7,
      max_tokens: 1000
    });

    const aiResponse = completion.choices[0].message.content;
    const tokensUsed = completion.usage.total_tokens;

    return {
      content: aiResponse,
      tokensUsed,
      model: completion.model
    };
  } catch (error) {
    console.error('OpenAI API error:', error);
    throw new Error('Failed to generate AI response');
  }
}

/**
 * Search knowledge base for relevant information (RAG)
 * @param {string} query - Search query
 * @returns {Promise<Array>} Relevant knowledge base entries
 */
async function searchKnowledgeBase(query) {
  try {
    const embeddingResponse = await openai.embeddings.create({
      model: 'text-embedding-ada-002',
      input: query
    });

    const queryEmbedding = embeddingResponse.data[0].embedding;

    const { data, error } = await supabase.rpc('match_knowledge_base', {
      query_embedding: queryEmbedding,
      match_threshold: 0.7,
      match_count: 5
    });

    if (error) {
      console.error('Knowledge base search error:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('Knowledge base search error:', error);
    return [];
  }
}

module.exports = {
  generateAIResponse,
  searchKnowledgeBase
};
