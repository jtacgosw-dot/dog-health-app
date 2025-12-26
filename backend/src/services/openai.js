const OpenAI = require('openai');
const supabase = require('./supabase');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

/**
 * Format health logs into a readable summary for the AI
 * @param {Array} logs - Array of health log entries
 * @returns {string} Formatted summary
 */
function formatHealthLogsSummary(logs) {
  if (!logs || logs.length === 0) {
    return 'No recent health logs available.';
  }

  const logsByType = {};
  for (const log of logs) {
    const type = log.log_type || 'Other';
    if (!logsByType[type]) {
      logsByType[type] = [];
    }
    logsByType[type].push(log);
  }

  let summary = '';
  
  // Meals
  if (logsByType['Meals']) {
    const meals = logsByType['Meals'].slice(0, 5);
    summary += `\nRecent Meals (${meals.length} entries):\n`;
    for (const meal of meals) {
      const date = new Date(meal.timestamp).toLocaleDateString();
      summary += `- ${date}: ${meal.meal_type || 'Meal'}${meal.amount ? ` (${meal.amount})` : ''}${meal.notes ? ` - ${meal.notes}` : ''}\n`;
    }
  }

  // Walks/Exercise
  if (logsByType['Walk']) {
    const walks = logsByType['Walk'].slice(0, 5);
    summary += `\nRecent Walks (${walks.length} entries):\n`;
    for (const walk of walks) {
      const date = new Date(walk.timestamp).toLocaleDateString();
      summary += `- ${date}: ${walk.duration ? `${walk.duration} minutes` : 'Walk'}${walk.notes ? ` - ${walk.notes}` : ''}\n`;
    }
  }

  // Symptoms
  if (logsByType['Symptom']) {
    const symptoms = logsByType['Symptom'].slice(0, 5);
    summary += `\nRecent Symptoms (${symptoms.length} entries):\n`;
    for (const symptom of symptoms) {
      const date = new Date(symptom.timestamp).toLocaleDateString();
      const severity = symptom.severity_level !== null ? ` (severity: ${symptom.severity_level}/5)` : '';
      summary += `- ${date}: ${symptom.symptom_type || 'Symptom'}${severity}${symptom.notes ? ` - ${symptom.notes}` : ''}\n`;
    }
  }

  // Digestion
  if (logsByType['Digestion']) {
    const digestion = logsByType['Digestion'].slice(0, 5);
    summary += `\nRecent Digestion (${digestion.length} entries):\n`;
    for (const entry of digestion) {
      const date = new Date(entry.timestamp).toLocaleDateString();
      summary += `- ${date}: ${entry.digestion_quality || 'Digestion log'}${entry.notes ? ` - ${entry.notes}` : ''}\n`;
    }
  }

  // Mood
  if (logsByType['Mood']) {
    const moods = logsByType['Mood'].slice(0, 5);
    summary += `\nRecent Mood (${moods.length} entries):\n`;
    for (const mood of moods) {
      const date = new Date(mood.timestamp).toLocaleDateString();
      const level = mood.mood_level !== null ? ` (level: ${mood.mood_level}/5)` : '';
      summary += `- ${date}: Mood${level}${mood.notes ? ` - ${mood.notes}` : ''}\n`;
    }
  }

  // Water
  if (logsByType['Water']) {
    const water = logsByType['Water'].slice(0, 5);
    summary += `\nRecent Water Intake (${water.length} entries):\n`;
    for (const entry of water) {
      const date = new Date(entry.timestamp).toLocaleDateString();
      summary += `- ${date}: ${entry.water_amount || 'Water'}${entry.notes ? ` - ${entry.notes}` : ''}\n`;
    }
  }

  // Supplements
  if (logsByType['Supplements']) {
    const supplements = logsByType['Supplements'].slice(0, 5);
    summary += `\nRecent Supplements (${supplements.length} entries):\n`;
    for (const supp of supplements) {
      const date = new Date(supp.timestamp).toLocaleDateString();
      summary += `- ${date}: ${supp.supplement_name || 'Supplement'}${supp.dosage ? ` (${supp.dosage})` : ''}${supp.notes ? ` - ${supp.notes}` : ''}\n`;
    }
  }

  // Treats
  if (logsByType['Treat']) {
    const treats = logsByType['Treat'].slice(0, 5);
    summary += `\nRecent Treats (${treats.length} entries):\n`;
    for (const treat of treats) {
      const date = new Date(treat.timestamp).toLocaleDateString();
      summary += `- ${date}: ${treat.treat_name || 'Treat'}${treat.notes ? ` - ${treat.notes}` : ''}\n`;
    }
  }

  // Grooming
  if (logsByType['Grooming']) {
    const grooming = logsByType['Grooming'].slice(0, 5);
    summary += `\nRecent Grooming (${grooming.length} entries):\n`;
    for (const entry of grooming) {
      const date = new Date(entry.timestamp).toLocaleDateString();
      summary += `- ${date}: ${entry.grooming_type || 'Grooming'}${entry.notes ? ` - ${entry.notes}` : ''}\n`;
    }
  }

  // Appointments
  if (logsByType['Upcoming Appointments']) {
    const appointments = logsByType['Upcoming Appointments'].slice(0, 5);
    summary += `\nUpcoming Appointments (${appointments.length} entries):\n`;
    for (const appt of appointments) {
      const date = new Date(appt.timestamp).toLocaleDateString();
      summary += `- ${date}: ${appt.appointment_type || 'Appointment'}${appt.location ? ` at ${appt.location}` : ''}${appt.notes ? ` - ${appt.notes}` : ''}\n`;
    }
  }

  // Notes
  if (logsByType['Notes']) {
    const notes = logsByType['Notes'].slice(0, 5);
    summary += `\nRecent Notes (${notes.length} entries):\n`;
    for (const note of notes) {
      const date = new Date(note.timestamp).toLocaleDateString();
      summary += `- ${date}: ${note.notes || 'Note'}\n`;
    }
  }

  // Playtime
  if (logsByType['Playtime']) {
    const playtime = logsByType['Playtime'].slice(0, 5);
    summary += `\nRecent Playtime (${playtime.length} entries):\n`;
    for (const play of playtime) {
      const date = new Date(play.timestamp).toLocaleDateString();
      summary += `- ${date}: ${play.activity_type || 'Playtime'}${play.duration ? ` (${play.duration} min)` : ''}${play.notes ? ` - ${play.notes}` : ''}\n`;
    }
  }

  return summary || 'No recent health logs available.';
}

/**
 * Generate AI response for dog health query
 * @param {string} userMessage - User's message
 * @param {string} conversationId - Conversation ID for context
 * @param {object} dogProfile - Dog's profile information
 * @param {Array} healthLogs - Recent health logs for the dog
 * @returns {Promise<object>} AI response with content and metadata
 */
async function generateAIResponse(userMessage, conversationId, dogProfile = null, healthLogs = null) {
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

    let systemPrompt = `You are a knowledgeable and caring dog health assistant. Your role is to provide helpful guidance and educational information about dog health, behavior, and care. You have access to the user's health logs for their pet, which you should reference when relevant to provide personalized advice.

IMPORTANT GUIDELINES:
- You are NOT a veterinarian and cannot provide medical diagnoses
- Always recommend consulting a veterinarian for serious health concerns
- Provide educational information and general guidance
- Be empathetic and supportive
- Ask clarifying questions when needed
- If symptoms sound serious (difficulty breathing, severe pain, bleeding, etc.), strongly recommend immediate veterinary care
- When the user asks about their pet's health, reference the health logs to provide context-aware responses
- Look for patterns in the health logs (e.g., recurring symptoms, changes in behavior, diet correlations)

Your responses should be:
- Clear and easy to understand
- Practical and actionable
- Supportive and non-judgmental
- Focused on the dog's wellbeing
- Personalized based on the pet's health history when available`;

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

    // Add health logs context
    if (healthLogs && healthLogs.length > 0) {
      const healthLogsSummary = formatHealthLogsSummary(healthLogs);
      systemPrompt += `\n\nRecent Health Logs (last 7 days):\n${healthLogsSummary}`;
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
