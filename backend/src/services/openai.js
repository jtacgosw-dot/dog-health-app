const OpenAI = require('openai');
const supabase = require('./supabase');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

const RED_FLAG_SYMPTOMS = [
  'difficulty breathing', 'labored breathing', 'choking',
  'seizure', 'convulsion', 'collapse', 'unconscious',
  'severe bleeding', 'blood in stool', 'blood in urine', 'blood in vomit',
  'bloated stomach', 'distended abdomen', 'trying to vomit but can\'t',
  'paralysis', 'can\'t walk', 'can\'t stand',
  'severe pain', 'crying in pain', 'won\'t stop whimpering',
  'poisoning', 'ate chocolate', 'ate xylitol', 'ate grapes', 'ate raisins',
  'heatstroke', 'hypothermia', 'extremely hot', 'extremely cold',
  'eye injury', 'eye popping out',
  'broken bone', 'hit by car', 'trauma'
];

function detectRedFlags(logs, userMessage) {
  const redFlags = [];
  const messageLC = userMessage.toLowerCase();
  
  for (const flag of RED_FLAG_SYMPTOMS) {
    if (messageLC.includes(flag)) {
      redFlags.push(flag);
    }
  }
  
  if (logs && logs.length > 0) {
    const recentSymptoms = logs.filter(l => l.log_type === 'Symptom');
    for (const symptom of recentSymptoms) {
      const notes = (symptom.notes || '').toLowerCase();
      const type = (symptom.symptom_type || '').toLowerCase();
      for (const flag of RED_FLAG_SYMPTOMS) {
        if (notes.includes(flag) || type.includes(flag)) {
          redFlags.push(`${flag} (logged ${new Date(symptom.timestamp).toLocaleDateString()})`);
        }
      }
    }
  }
  
  return [...new Set(redFlags)];
}

function detectPatterns(logs) {
  if (!logs || logs.length < 2) return [];
  
  const patterns = [];
  const logsByType = {};
  
  for (const log of logs) {
    const type = log.log_type || 'Other';
    if (!logsByType[type]) logsByType[type] = [];
    logsByType[type].push(log);
  }
  
  const symptoms = logsByType['Symptom'] || [];
  if (symptoms.length >= 2) {
    const symptomTypes = {};
    for (const s of symptoms) {
      const type = s.symptom_type || 'unknown';
      symptomTypes[type] = (symptomTypes[type] || 0) + 1;
    }
    for (const [type, count] of Object.entries(symptomTypes)) {
      if (count >= 2) {
        patterns.push(`Recurring symptom: ${type} occurred ${count} times`);
      }
    }
  }
  
  const digestion = logsByType['Digestion'] || [];
  const poorDigestion = digestion.filter(d => 
    (d.digestion_quality || '').toLowerCase().includes('poor') ||
    (d.digestion_quality || '').toLowerCase().includes('bad') ||
    (d.notes || '').toLowerCase().includes('diarrhea') ||
    (d.notes || '').toLowerCase().includes('vomit')
  );
  if (poorDigestion.length >= 2) {
    patterns.push(`Digestive issues: ${poorDigestion.length} instances of poor digestion logged`);
  }
  
  const meals = logsByType['Meals'] || [];
  const treats = logsByType['Treat'] || [];
  if ((symptoms.length > 0 || poorDigestion.length > 0) && (meals.length > 0 || treats.length > 0)) {
    const symptomDates = new Set(symptoms.map(s => new Date(s.timestamp).toDateString()));
    const digestionDates = new Set(poorDigestion.map(d => new Date(d.timestamp).toDateString()));
    const problemDates = new Set([...symptomDates, ...digestionDates]);
    
    const foodOnProblemDays = [...meals, ...treats].filter(f => 
      problemDates.has(new Date(f.timestamp).toDateString())
    );
    
    if (foodOnProblemDays.length > 0) {
      const foods = foodOnProblemDays.map(f => f.meal_type || f.treat_name || f.notes || 'food').slice(0, 3);
      patterns.push(`Possible food correlation: symptoms/digestion issues occurred on days with: ${foods.join(', ')}`);
    }
  }
  
  const walks = logsByType['Walk'] || [];
  const playtime = logsByType['Playtime'] || [];
  const totalActivity = walks.length + playtime.length;
  const daysWithLogs = new Set(logs.map(l => new Date(l.timestamp).toDateString())).size;
  
  if (daysWithLogs >= 3 && totalActivity < daysWithLogs * 0.5) {
    patterns.push(`Low activity: Only ${totalActivity} walks/playtime sessions logged over ${daysWithLogs} days`);
  }
  
  const moods = logsByType['Mood'] || [];
  const lowMoods = moods.filter(m => m.mood_level !== null && m.mood_level <= 2);
  if (lowMoods.length >= 2) {
    patterns.push(`Mood concern: ${lowMoods.length} instances of low mood (level 1-2) logged`);
  }
  
  return patterns;
}

function generateHealthSummary(logs) {
  if (!logs || logs.length === 0) return null;
  
  const now = new Date();
  const oneDayAgo = new Date(now - 24 * 60 * 60 * 1000);
  const threeDaysAgo = new Date(now - 3 * 24 * 60 * 60 * 1000);
  
  const last24h = logs.filter(l => new Date(l.timestamp) >= oneDayAgo);
  const last3Days = logs.filter(l => new Date(l.timestamp) >= threeDaysAgo);
  
  const summary = {
    totalLogs: logs.length,
    last24Hours: {
      meals: last24h.filter(l => l.log_type === 'Meals').length,
      walks: last24h.filter(l => l.log_type === 'Walk').length,
      symptoms: last24h.filter(l => l.log_type === 'Symptom').length,
      water: last24h.filter(l => l.log_type === 'Water').length
    },
    last3Days: {
      symptoms: last3Days.filter(l => l.log_type === 'Symptom').length,
      digestionIssues: last3Days.filter(l => 
        l.log_type === 'Digestion' && 
        ((l.digestion_quality || '').toLowerCase().includes('poor') ||
         (l.notes || '').toLowerCase().includes('diarrhea'))
      ).length
    }
  };
  
  return summary;
}

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
 * @param {Array} images - Array of base64 encoded images (optional)
 * @returns {Promise<object>} AI response with content and metadata
 */
async function generateAIResponse(userMessage, conversationId, dogProfile = null, healthLogs = null, images = null) {
  try {
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('role, content')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true })
      .limit(20);

    if (messagesError) {
      console.error('Error fetching conversation history:', messagesError);
    }

    const conversationHistory = messages || [];
    
    const redFlags = detectRedFlags(healthLogs, userMessage);
    const patterns = detectPatterns(healthLogs);
    const healthSummary = generateHealthSummary(healthLogs);

    let systemPrompt = `You are Petly AI, an expert dog health assistant with deep knowledge of canine health, nutrition, behavior, and wellness. You have access to ${dogProfile ? dogProfile.name + "'s" : "the pet's"} complete health logs and should use them to provide highly personalized, intelligent advice.

CORE IDENTITY:
- You are warm, caring, and genuinely invested in the pet's wellbeing
- You speak with confidence but appropriate humility about medical limitations
- You remember and reference the pet's health history naturally in conversation
- You proactively notice patterns and correlations the owner might miss

CRITICAL SAFETY RULES:
- You are NOT a veterinarian and CANNOT diagnose conditions
- For ANY potentially serious symptoms, ALWAYS recommend veterinary consultation
- NEVER delay recommending emergency care for red-flag symptoms
- When uncertain, err on the side of caution and recommend professional evaluation`;

    if (redFlags.length > 0) {
      systemPrompt += `

RED FLAG ALERT - DETECTED SERIOUS SYMPTOMS:
${redFlags.map(f => `- ${f}`).join('\n')}

YOU MUST:
1. Acknowledge these symptoms with appropriate urgency
2. Strongly recommend immediate veterinary care
3. Provide first-aid guidance while they seek help
4. Do NOT downplay or dismiss these concerns`;
    }

    systemPrompt += `

RESPONSE GUIDELINES:
1. ALWAYS reference specific logged data when relevant ("I see ${dogProfile?.name || 'your dog'} had diarrhea on [date]...")
2. Look for and mention patterns ("I notice this is the third time this week...")
3. Ask 1-2 clarifying questions when symptoms are vague
4. Provide actionable next steps, not just information
5. For symptoms, always ask: duration, severity, any changes in behavior/appetite
6. Connect dots between different logs (diet changes -> digestive issues, etc.)
7. Be encouraging about good habits you see in the logs
8. Keep responses conversational but informative (2-4 paragraphs typical)

WHEN TO RECOMMEND VET VISIT:
- Any symptom lasting more than 24-48 hours
- Multiple symptoms occurring together
- Symptoms that are worsening
- Any red-flag symptoms (breathing issues, severe pain, bleeding, etc.)
- Changes in eating/drinking lasting more than a day
- Lethargy combined with other symptoms`;

    if (dogProfile) {
      systemPrompt += `

DOG PROFILE - ${dogProfile.name.toUpperCase()}:
- Name: ${dogProfile.name}
- Breed: ${dogProfile.breed || 'Unknown'} ${dogProfile.breed ? `(consider breed-specific health tendencies)` : ''}
- Age: ${dogProfile.age_years ? `${dogProfile.age_years} years` : 'Unknown'}${dogProfile.age_months ? ` ${dogProfile.age_months} months` : ''} ${dogProfile.age_years >= 7 ? '(senior dog - be mindful of age-related concerns)' : dogProfile.age_years <= 1 ? '(puppy - consider developmental needs)' : ''}
- Weight: ${dogProfile.weight_lbs ? `${dogProfile.weight_lbs} lbs` : 'Unknown'}
- Sex: ${dogProfile.sex || 'Unknown'}
- Neutered/Spayed: ${dogProfile.is_neutered !== null ? (dogProfile.is_neutered ? 'Yes' : 'No') : 'Unknown'}
${dogProfile.medical_history ? `- Medical History: ${dogProfile.medical_history} (IMPORTANT: factor this into all advice)` : ''}
${dogProfile.allergies ? `- Known Allergies: ${dogProfile.allergies} (IMPORTANT: always consider when discussing food/medications)` : ''}
${dogProfile.current_medications ? `- Current Medications: ${dogProfile.current_medications} (IMPORTANT: consider drug interactions)` : ''}`;
    }

    if (patterns.length > 0) {
      systemPrompt += `

DETECTED PATTERNS IN HEALTH LOGS:
${patterns.map(p => `- ${p}`).join('\n')}

You SHOULD mention these patterns naturally in your response when relevant.`;
    }

    if (healthSummary) {
      systemPrompt += `

QUICK HEALTH SUMMARY:
- Total logs in period: ${healthSummary.totalLogs}
- Last 24 hours: ${healthSummary.last24Hours.meals} meals, ${healthSummary.last24Hours.walks} walks, ${healthSummary.last24Hours.symptoms} symptoms, ${healthSummary.last24Hours.water} water logs
- Last 3 days: ${healthSummary.last3Days.symptoms} symptoms, ${healthSummary.last3Days.digestionIssues} digestion issues`;
    }

    if (healthLogs && healthLogs.length > 0) {
      const healthLogsSummary = formatHealthLogsSummary(healthLogs);
      systemPrompt += `

DETAILED HEALTH LOGS (Last 30 days):
${healthLogsSummary}`;
    } else {
      systemPrompt += `

NOTE: No health logs available yet. Encourage the owner to start logging meals, walks, and any symptoms to get personalized insights.`;
    }

    let userContent;
    if (images && images.length > 0) {
      userContent = [
        { type: 'text', text: userMessage }
      ];
      for (const imageBase64 of images) {
        userContent.push({
          type: 'image_url',
          image_url: {
            url: `data:image/jpeg;base64,${imageBase64}`,
            detail: 'auto'
          }
        });
      }
    } else {
      userContent = userMessage;
    }

    const openaiMessages = [
      { role: 'system', content: systemPrompt },
      ...conversationHistory.map(msg => ({
        role: msg.role,
        content: msg.content
      })),
      { role: 'user', content: userContent }
    ];

    const completion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || 'gpt-4o',
      messages: openaiMessages,
      temperature: 0.7,
      max_tokens: 1500
    });

    const aiResponse = completion.choices[0].message.content;
    const tokensUsed = completion.usage.total_tokens;

    return {
      content: aiResponse,
      tokensUsed,
      model: completion.model,
      redFlagsDetected: redFlags.length > 0,
      patternsDetected: patterns
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
  searchKnowledgeBase,
  detectRedFlags,
  detectPatterns
};
