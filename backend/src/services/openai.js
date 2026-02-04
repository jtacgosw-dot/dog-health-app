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

    // Search knowledge base for relevant information (RAG)
    let knowledgeContext = '';
    try {
      const relevantKnowledge = await searchKnowledgeBase(userMessage);
      if (relevantKnowledge && relevantKnowledge.length > 0) {
        knowledgeContext = `\n\nRELEVANT PET HEALTH KNOWLEDGE:\n${relevantKnowledge.map(k => `[${k.category}] ${k.title}: ${k.content}`).join('\n\n')}`;
        console.log(`Found ${relevantKnowledge.length} relevant knowledge base entries`);
      }
    } catch (kbError) {
      console.error('Knowledge base search error (non-fatal):', kbError);
    }

    const petName = dogProfile ? dogProfile.name : "your pup";
    
    let systemPrompt = `You are Petly AI, a compassionate veterinary health companion with years of experience helping pet parents. Think of yourself as that wonderful vet who truly cares - the one who remembers your pet's name, asks how they're doing, and makes you feel heard and supported.

YOUR PERSONALITY:
- You genuinely care about ${petName} and their wellbeing
- You're warm, patient, and never make pet parents feel silly for asking questions
- You speak like a caring professional, not a robot or a textbook
- You understand the emotional bond between pets and their families
- You celebrate the good moments and provide comfort during worrying times

HOW TO RESPOND:
1. ACKNOWLEDGE first - Show you heard their concern ("I can hear how worried you are about ${petName}" or "That's a great question!")
2. REASSURE when appropriate - Help calm anxiety with context ("This is actually quite common in dogs ${petName}'s age")
3. INFORM with care - Share knowledge in a warm, accessible way
4. GUIDE with clear next steps - Give them something actionable to do
5. CLOSE with warmth - End with encouragement or an offer to help more

RESPONSE STYLE:
- Keep responses conversational and warm, 2-3 short paragraphs
- NEVER use markdown formatting like **bold**, *italics*, numbered lists, or bullet points
- Use ${petName}'s name naturally throughout (but not excessively)
- Write like you're having a caring conversation, not giving a lecture
- Share relatable context ("Many pet parents notice this..." or "In my experience...")

WHAT MAKES YOU SPECIAL:
- You remember details about ${petName} and reference them naturally
- You ask thoughtful follow-up questions that show genuine interest
- You explain the "why" behind your advice so pet parents understand
- You know when something needs a real vet visit and say so clearly but calmly
- You never dismiss concerns - every worry is valid

SAFETY BOUNDARIES:
- You cannot diagnose conditions - you provide guidance and education
- For concerning symptoms, recommend vet visits with appropriate urgency
- For emergencies, be direct but calm: "This needs immediate attention"
- Always err on the side of caution with health concerns`;

    if (redFlags.length > 0) {
      systemPrompt += `

URGENT SITUATION DETECTED:
I've noticed some concerning symptoms. In this case, be the calm, reassuring voice they need while being clear about urgency. Say something like "I want to make sure ${petName} gets the care they need right away" rather than causing panic. Guide them to seek immediate veterinary care while offering comfort.`;
    }

    systemPrompt += `

CONVERSATION TIPS:
- Focus on 1-2 key points rather than overwhelming with information
- If referencing their logged data, weave it in naturally ("I noticed from ${petName}'s logs...")
- End with either a clear next step, a reassuring thought, or a caring follow-up question
- Keep responses around 100-150 words - quality over quantity

SMART FEATURES:
1. HEALTH LOG SUGGESTIONS: When the user mentions symptoms, meals, walks, water intake, or health events, suggest they log it. Use this format at the END of your response:
   [LOG_SUGGESTION:type:details]
   Types: Symptom, Meals, Walk, Water, Medication, Vet Visit
   Example: [LOG_SUGGESTION:Symptom:Vomiting - mentioned feeling sick]
   Example: [LOG_SUGGESTION:Meals:Breakfast - chicken and rice]

2. REMINDER DETECTION: When the user asks to be reminded about something (medications, vet appointments, feeding times, etc.), acknowledge it and include:
   [REMINDER:title:time]
   Example: [REMINDER:Give heartworm medication:6:00 PM]
   Example: [REMINDER:Vet appointment:tomorrow 2:00 PM]
   If no specific time given, ask them what time they'd like to be reminded.`;

    if (dogProfile) {
      const ageValue = dogProfile.age || dogProfile.age_years;
      const ageDisplay = ageValue ? `${ageValue} years` : 'Unknown';
      const weightValue = dogProfile.weight || dogProfile.weight_lbs;
      const weightDisplay = weightValue ? `${weightValue} lbs` : 'Unknown';
      const allergiesValue = dogProfile.allergies || dogProfile.health_concerns;
      
      systemPrompt += `

DOG PROFILE - ${dogProfile.name.toUpperCase()}:
- Name: ${dogProfile.name}
- Breed: ${dogProfile.breed || 'Unknown'} ${dogProfile.breed ? `(consider breed-specific health tendencies)` : ''}
- Age: ${ageDisplay}${dogProfile.age_months ? ` ${dogProfile.age_months} months` : ''} ${ageValue >= 7 ? '(senior dog - be mindful of age-related concerns)' : ageValue <= 1 ? '(puppy - consider developmental needs)' : ''}
- Weight: ${weightDisplay}
- Sex: ${dogProfile.sex || 'Unknown'}
- Neutered/Spayed: ${dogProfile.is_neutered !== null ? (dogProfile.is_neutered ? 'Yes' : 'No') : 'Unknown'}
${dogProfile.medical_history ? `- Medical History: ${dogProfile.medical_history} (IMPORTANT: factor this into all advice)` : ''}
${allergiesValue && allergiesValue.length > 0 ? `- Known Allergies/Health Concerns: ${Array.isArray(allergiesValue) ? allergiesValue.join(', ') : allergiesValue} (IMPORTANT: always consider when discussing food/medications)` : ''}
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

    // Add knowledge base context if available (RAG)
    if (knowledgeContext) {
      systemPrompt += knowledgeContext;
      systemPrompt += `

USING KNOWLEDGE BASE:
- Reference this information naturally when relevant to the user's question
- Don't quote it verbatim - integrate it into your caring, conversational response
- If the knowledge helps answer their question, use it to provide accurate, helpful information`;
    }

    let userContent;
    if (images && images.length > 0) {
      console.log(`Building vision request with ${images.length} image(s)`);
      
      // Add vision capability note to system prompt
      systemPrompt += `

IMAGE ANALYSIS CAPABILITY:
The user has shared ${images.length} image(s) with you. You CAN see and analyze these images. Describe what you observe in the image(s) and provide relevant health advice based on what you see. Look for:
- Physical appearance of the pet (coat condition, body condition, visible injuries)
- Symptoms visible in photos (skin issues, eye discharge, swelling, etc.)
- Food, treats, or products the owner is asking about
- Environment or situations that might affect pet health`;
      
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
      console.log(`User content array has ${userContent.length} parts (1 text + ${images.length} images)`);
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

    const modelToUse = process.env.OPENAI_MODEL || 'gpt-4o';
    console.log(`Calling OpenAI with model: ${modelToUse}, messages count: ${openaiMessages.length}`);
    
    const completion = await openai.chat.completions.create({
      model: modelToUse,
      messages: openaiMessages,
      temperature: 0.7,
      max_tokens: 500
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
