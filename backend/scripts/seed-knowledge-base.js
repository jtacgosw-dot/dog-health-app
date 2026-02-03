/**
 * Seed script for AI Knowledge Base
 * 
 * This script populates the ai_knowledge_base table with curated pet health information
 * that the AI can reference when answering user questions (RAG - Retrieval Augmented Generation).
 * 
 * Run with: node scripts/seed-knowledge-base.js
 * 
 * Requirements:
 * - OPENAI_API_KEY environment variable
 * - SUPABASE_URL and SUPABASE_SERVICE_KEY environment variables
 */

require('dotenv').config();
const OpenAI = require('openai');
const { createClient } = require('@supabase/supabase-js');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// Curated pet health knowledge base entries
const knowledgeEntries = [
  // NUTRITION
  {
    category: 'Nutrition',
    title: 'Foods Toxic to Dogs',
    content: 'Several common human foods are toxic to dogs and should never be fed to them. Chocolate contains theobromine which dogs cannot metabolize - dark chocolate is most dangerous. Grapes and raisins can cause kidney failure even in small amounts. Xylitol (artificial sweetener) causes rapid insulin release leading to hypoglycemia and liver failure. Onions and garlic damage red blood cells causing anemia. Macadamia nuts cause weakness, vomiting, and hyperthermia. Avocado contains persin which can cause vomiting and diarrhea. Alcohol is extremely dangerous as dogs are much more sensitive than humans. If your dog ingests any of these, contact your vet or poison control immediately.',
    source: 'ASPCA Animal Poison Control'
  },
  {
    category: 'Nutrition',
    title: 'Healthy Human Foods for Dogs',
    content: 'Many human foods are safe and nutritious for dogs in moderation. Carrots are low-calorie, high in fiber and vitamin A - great for dental health. Blueberries are antioxidant-rich superfoods. Plain cooked chicken or turkey (no bones, skin, or seasoning) is excellent lean protein. Pumpkin (plain, not pie filling) aids digestion and can help with both diarrhea and constipation. Green beans are low-calorie and filling. Apples (without seeds or core) provide vitamins A and C. Watermelon (seedless, no rind) is hydrating. Plain cooked sweet potato is nutritious. Always introduce new foods gradually and in small amounts.',
    source: 'American Kennel Club'
  },
  {
    category: 'Nutrition',
    title: 'How Much to Feed Your Dog',
    content: 'Feeding amounts depend on your dogs age, size, activity level, and the specific food. Puppies need 3-4 meals daily until 6 months, then 2 meals daily. Adult dogs typically do well with 2 meals per day. As a general guide: toy breeds (3-6 lbs) need 1/3 to 1/2 cup daily, small breeds (10-20 lbs) need 3/4 to 1.5 cups, medium breeds (30-50 lbs) need 1.75 to 2.5 cups, large breeds (60-100 lbs) need 3 to 4.5 cups. Always follow the food packaging guidelines and adjust based on your dogs body condition. You should be able to feel but not see ribs. Consult your vet for personalized recommendations.',
    source: 'Association of American Feed Control Officials'
  },
  {
    category: 'Nutrition',
    title: 'Signs of Food Allergies in Dogs',
    content: 'Food allergies in dogs typically manifest as skin problems or digestive issues. Common signs include: itchy skin especially around ears, paws, rear end, and belly; chronic ear infections; red, inflamed skin; hair loss; hot spots; vomiting; diarrhea; excessive gas; and frequent bowel movements. The most common food allergens for dogs are beef, dairy, wheat, egg, chicken, lamb, soy, pork, rabbit, and fish. If you suspect a food allergy, work with your vet on an elimination diet trial lasting 8-12 weeks. This involves feeding a novel protein or hydrolyzed diet exclusively to identify the allergen.',
    source: 'Veterinary Dermatology Journal'
  },

  // COMMON SYMPTOMS
  {
    category: 'Symptoms',
    title: 'When Vomiting is an Emergency',
    content: 'Occasional vomiting can be normal, but certain signs indicate an emergency requiring immediate vet care. Seek emergency help if: vomiting is continuous or happens more than 3 times in an hour; vomit contains blood (red or coffee-ground appearance); your dog is also having diarrhea; there is abdominal bloating or pain; your dog is lethargic or unresponsive; you suspect they ate something toxic or a foreign object; vomiting is accompanied by fever; your dog cannot keep water down for more than 12 hours; or if your dog is a puppy, senior, or has underlying health conditions. For mild cases, withhold food for 12 hours then offer bland diet.',
    source: 'American Veterinary Medical Association'
  },
  {
    category: 'Symptoms',
    title: 'Understanding Dog Diarrhea',
    content: 'Diarrhea in dogs can range from mild to serious. Acute diarrhea lasting 1-2 days is often caused by dietary indiscretion, stress, or minor infections. Chronic diarrhea lasting more than 2 weeks may indicate inflammatory bowel disease, parasites, or other conditions. Color matters: yellow or green suggests rapid transit or gallbladder issues; black tarry stool indicates upper GI bleeding; red blood suggests lower GI bleeding; gray or greasy suggests pancreatic issues. For mild cases, fast for 12-24 hours, then offer bland diet (boiled chicken and rice). Ensure hydration. See a vet if diarrhea persists beyond 48 hours, contains blood, or is accompanied by vomiting, lethargy, or fever.',
    source: 'Veterinary Internal Medicine'
  },
  {
    category: 'Symptoms',
    title: 'Why Dogs Scratch Excessively',
    content: 'Excessive scratching in dogs has many potential causes. Fleas are the most common - check for flea dirt (black specks) in fur. Environmental allergies (atopy) cause seasonal itching, often affecting paws, ears, and belly. Food allergies cause year-round itching. Dry skin from low humidity or over-bathing. Skin infections (bacterial or yeast) often secondary to allergies. Mites cause intense itching, especially around ears. Hot spots are localized areas of inflammation. Anxiety can cause compulsive scratching. Treatment depends on the cause - flea prevention, antihistamines, medicated shampoos, dietary changes, or prescription medications. Persistent scratching warrants a vet visit for proper diagnosis.',
    source: 'Veterinary Dermatology'
  },
  {
    category: 'Symptoms',
    title: 'Lethargy in Dogs - When to Worry',
    content: 'Some tiredness is normal, but lethargy - a significant decrease in energy and interest in activities - can signal health problems. Concerning signs include: sleeping much more than usual; reluctance to walk, play, or eat; slow response to stimuli; weakness when standing or walking; and lack of interest in favorite activities. Potential causes range from minor (overexertion, hot weather, mild illness) to serious (infections, organ disease, pain, anemia, cancer, poisoning). Lethargy combined with other symptoms like vomiting, diarrhea, difficulty breathing, or not eating requires prompt veterinary attention. Track when it started and any other symptoms to help your vet diagnose the cause.',
    source: 'American Animal Hospital Association'
  },

  // PREVENTIVE CARE
  {
    category: 'Preventive Care',
    title: 'Core Vaccinations for Dogs',
    content: 'Core vaccines are recommended for all dogs regardless of lifestyle. Rabies is required by law and protects against a fatal viral disease. Distemper protects against a serious viral disease affecting respiratory, GI, and nervous systems. Parvovirus vaccine prevents a highly contagious and often fatal intestinal virus. Adenovirus (hepatitis) protects against liver disease. Puppies need a series of shots starting at 6-8 weeks, with boosters every 3-4 weeks until 16 weeks old. Adult dogs need boosters every 1-3 years depending on the vaccine. Non-core vaccines (Bordetella, Lyme, Leptospirosis, Canine Influenza) are recommended based on lifestyle and geographic risk.',
    source: 'American Animal Hospital Association Vaccination Guidelines'
  },
  {
    category: 'Preventive Care',
    title: 'Flea and Tick Prevention',
    content: 'Year-round flea and tick prevention is essential in most climates. Fleas cause itching, allergic reactions, and can transmit tapeworms. Ticks transmit serious diseases including Lyme disease, ehrlichiosis, and Rocky Mountain spotted fever. Prevention options include: monthly topical treatments applied to skin; monthly oral chewables; flea/tick collars lasting 6-8 months; and injectable options lasting several months. Choose products based on your dogs size, age, and health status. Some products also prevent heartworm and intestinal parasites. Never use dog products on cats - some ingredients are toxic to cats. Consult your vet for the best prevention plan for your pet.',
    source: 'Companion Animal Parasite Council'
  },
  {
    category: 'Preventive Care',
    title: 'Dental Care for Dogs',
    content: 'Dental disease affects over 80% of dogs by age 3. Poor dental health can lead to pain, tooth loss, and bacteria entering the bloodstream affecting heart, liver, and kidneys. Signs of dental problems include bad breath, yellow/brown tartar, red or bleeding gums, difficulty eating, and pawing at mouth. Prevention includes: daily tooth brushing with dog-specific toothpaste (never human toothpaste); dental chews and toys; dental diets; water additives. Professional dental cleanings under anesthesia are recommended annually or as needed. Start dental care early - puppies can begin having their teeth brushed to get used to the process.',
    source: 'American Veterinary Dental College'
  },
  {
    category: 'Preventive Care',
    title: 'Heartworm Prevention',
    content: 'Heartworm disease is a serious, potentially fatal condition caused by parasitic worms living in the heart and lungs. Its transmitted by mosquitoes and found in all 50 US states. Prevention is critical because treatment is expensive, risky, and hard on dogs. Monthly preventatives (oral or topical) or injectable options lasting 6-12 months are available. All dogs should be tested annually even if on prevention. Symptoms of heartworm disease include coughing, fatigue, decreased appetite, and weight loss - but dogs may show no symptoms until disease is advanced. Prevention costs $5-15/month while treatment costs $1,000+ and requires months of restricted activity.',
    source: 'American Heartworm Society'
  },

  // EXERCISE & ACTIVITY
  {
    category: 'Exercise',
    title: 'How Much Exercise Dogs Need',
    content: 'Exercise needs vary by breed, age, and health. High-energy breeds (Border Collies, Huskies, Retrievers) need 1-2+ hours daily of vigorous activity. Medium-energy breeds (Beagles, Bulldogs) need 30-60 minutes daily. Low-energy breeds (Basset Hounds, Bulldogs) need 20-30 minutes daily. Puppies need short, frequent play sessions - too much exercise can damage developing joints. Senior dogs still need regular but gentler exercise. Signs your dog needs more exercise: destructive behavior, excessive barking, hyperactivity, weight gain. Signs of over-exercise: excessive panting, limping, reluctance to continue. Mental stimulation through training and puzzle toys is also important.',
    source: 'American Kennel Club'
  },
  {
    category: 'Exercise',
    title: 'Safe Exercise in Hot Weather',
    content: 'Dogs are susceptible to heatstroke and burned paw pads in hot weather. Exercise early morning or evening when temperatures are cooler. Test pavement with your hand - if its too hot for you, its too hot for paws. Provide plenty of water before, during, and after exercise. Watch for signs of overheating: excessive panting, drooling, bright red tongue, vomiting, stumbling, collapse. Brachycephalic breeds (Bulldogs, Pugs) are at higher risk due to compromised breathing. Never leave dogs in parked cars - temperatures can reach deadly levels in minutes even with windows cracked. If you suspect heatstroke, move to shade, apply cool (not cold) water, and seek immediate vet care.',
    source: 'American Veterinary Medical Association'
  },

  // BEHAVIOR
  {
    category: 'Behavior',
    title: 'Signs of Anxiety in Dogs',
    content: 'Anxiety in dogs manifests in various ways. Common signs include: excessive barking or whining; destructive behavior especially when alone; pacing or restlessness; trembling or shaking; excessive licking or grooming; hiding or cowering; loss of appetite; house soiling despite being trained; aggression; and escape attempts. Triggers include separation from owners, loud noises (thunderstorms, fireworks), new environments, and past trauma. Management strategies include: creating safe spaces; maintaining routines; gradual desensitization; exercise before stressful events; calming aids (ThunderShirts, pheromone diffusers); and in severe cases, medication prescribed by a vet. Never punish anxious behavior as it worsens anxiety.',
    source: 'American College of Veterinary Behaviorists'
  },
  {
    category: 'Behavior',
    title: 'Why Dogs Eat Grass',
    content: 'Grass eating is common in dogs and usually not concerning. Possible reasons include: dietary fiber supplementation - dogs may instinctively seek plant matter; upset stomach - some dogs eat grass to induce vomiting, though studies show most grass-eaters dont vomit afterward; boredom or habit; they simply like the taste or texture; ancestral behavior from wild canine diets. When to be concerned: if grass eating is sudden and excessive; if accompanied by vomiting, diarrhea, or lethargy; if your dog seems compelled to eat grass frantically. Ensure grass hasnt been treated with pesticides or fertilizers. If concerned, try adding vegetables to diet or consult your vet.',
    source: 'Journal of Veterinary Behavior'
  },

  // SENIOR DOG CARE
  {
    category: 'Senior Care',
    title: 'Caring for Senior Dogs',
    content: 'Dogs are considered seniors at 7-10 years depending on size (larger dogs age faster). Senior dogs need adjusted care: twice-yearly vet visits for early disease detection; age-appropriate diet with joint support and easier-to-digest proteins; modified exercise - regular but gentler activity; comfortable bedding for arthritic joints; ramps or stairs for furniture access; mental stimulation to prevent cognitive decline; dental care becomes even more important. Watch for signs of aging: decreased activity, weight changes, vision/hearing loss, confusion, increased thirst/urination, lumps or bumps. Many age-related conditions are manageable with early intervention.',
    source: 'American Association of Feline Practitioners Senior Care Guidelines (adapted for dogs)'
  },
  {
    category: 'Senior Care',
    title: 'Arthritis in Dogs',
    content: 'Arthritis affects up to 80% of dogs over 8 years old. Signs include: stiffness especially after rest; reluctance to jump, climb stairs, or play; limping; licking joints; difficulty rising; decreased activity; behavior changes due to pain. Management includes: weight management (extra weight stresses joints); appropriate exercise (swimming is excellent - low impact); joint supplements (glucosamine, chondroitin, omega-3s); orthopedic beds; keeping nails trimmed; physical therapy; prescription medications (NSAIDs, pain relievers) from your vet; and in some cases, surgery. Never give human pain medications - many are toxic to dogs. Cold weather often worsens symptoms.',
    source: 'Veterinary Orthopedic Society'
  },

  // PUPPY CARE
  {
    category: 'Puppy Care',
    title: 'Puppy Development Stages',
    content: 'Understanding puppy development helps with training and care. Neonatal period (0-2 weeks): puppies are blind, deaf, and dependent on mother. Transitional period (2-4 weeks): eyes and ears open, begin walking. Socialization period (3-12 weeks): CRITICAL window for exposure to people, animals, sounds, and experiences - positive experiences now shape adult temperament. Juvenile period (3-6 months): teething, increased independence, continued learning. Adolescence (6-18 months): sexual maturity, testing boundaries, may seem to forget training. Social maturity (1-3 years): personality solidifies. Prioritize positive socialization during the critical window while being careful about disease exposure before vaccinations are complete.',
    source: 'American Veterinary Society of Animal Behavior'
  },
  {
    category: 'Puppy Care',
    title: 'House Training Basics',
    content: 'Successful house training requires consistency, patience, and positive reinforcement. Take puppies out frequently: after waking, after eating/drinking, after play, and every 1-2 hours. Use the same door and spot each time. Praise and treat immediately after they go outside. Supervise constantly indoors - use a leash, crate, or confined area when you cant watch. Crate training helps as dogs avoid soiling their sleeping area - crate should be just big enough to stand and turn around. Clean accidents with enzymatic cleaner to remove odor. Never punish accidents - it creates fear and doesnt teach the right behavior. Most puppies arent fully reliable until 4-6 months old.',
    source: 'Association of Professional Dog Trainers'
  },

  // EMERGENCY CARE
  {
    category: 'Emergency',
    title: 'Signs of Bloat (GDV) - Life Threatening',
    content: 'Gastric Dilatation-Volvulus (bloat/GDV) is a life-threatening emergency where the stomach fills with gas and may twist. Large, deep-chested breeds are most at risk (Great Danes, German Shepherds, Standard Poodles). Signs include: distended/swollen abdomen; unproductive retching (trying to vomit but nothing comes up); restlessness and pacing; drooling; rapid breathing; weakness or collapse. THIS IS AN EMERGENCY - death can occur within hours without surgery. Prevention: feed smaller, more frequent meals; avoid elevated food bowls; limit exercise around mealtimes; consider preventive gastropexy surgery for high-risk breeds. If you suspect bloat, go to emergency vet IMMEDIATELY.',
    source: 'American College of Veterinary Surgeons'
  },
  {
    category: 'Emergency',
    title: 'What to Do If Your Dog is Choking',
    content: 'Choking is an emergency requiring immediate action. Signs include: pawing at mouth, gagging, difficulty breathing, blue gums, panic. First, try to see and remove the object - open mouth wide and look for obstruction. Only sweep mouth if you can see the object - blind sweeping may push it deeper. If you cant remove it: for small dogs, hold upside down and shake gently; for large dogs, perform Heimlich maneuver - place fist just behind ribs and push up and forward firmly. If dog becomes unconscious, perform CPR. Even if you dislodge the object, see a vet to check for throat damage. Prevention: supervise with toys and chews, avoid small objects, cut food into appropriate sizes.',
    source: 'American Red Cross Pet First Aid'
  },
  {
    category: 'Emergency',
    title: 'Recognizing Pain in Dogs',
    content: 'Dogs often hide pain, making it important to recognize subtle signs. Behavioral changes: decreased activity, reluctance to move, hiding, aggression when touched, loss of appetite, restlessness, excessive licking of a specific area. Physical signs: limping, stiffness, hunched posture, trembling, panting when at rest, changes in posture or gait. Vocalizations: whimpering, yelping, growling when touched. Facial expressions: furrowed brow, flattened ears, glazed eyes. Changes in routine: sleeping more or less, avoiding stairs or jumping, changes in bathroom habits. If you suspect your dog is in pain, dont give human medications - many are toxic. Contact your vet for proper pain assessment and safe treatment options.',
    source: 'International Veterinary Academy of Pain Management'
  }
];

async function generateEmbedding(text) {
  const response = await openai.embeddings.create({
    model: 'text-embedding-ada-002',
    input: text
  });
  return response.data[0].embedding;
}

async function seedKnowledgeBase() {
  console.log('Starting knowledge base seeding...\n');
  
  // Check if knowledge base already has entries
  const { count, error: countError } = await supabase
    .from('ai_knowledge_base')
    .select('*', { count: 'exact', head: true });
  
  if (countError) {
    console.error('Error checking existing entries:', countError);
    return;
  }
  
  if (count > 0) {
    console.log(`Knowledge base already has ${count} entries.`);
    const readline = require('readline');
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    const answer = await new Promise(resolve => {
      rl.question('Do you want to clear and re-seed? (yes/no): ', resolve);
    });
    rl.close();
    
    if (answer.toLowerCase() !== 'yes') {
      console.log('Aborting seed operation.');
      return;
    }
    
    // Clear existing entries
    const { error: deleteError } = await supabase
      .from('ai_knowledge_base')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all
    
    if (deleteError) {
      console.error('Error clearing knowledge base:', deleteError);
      return;
    }
    console.log('Cleared existing entries.\n');
  }
  
  let successCount = 0;
  let errorCount = 0;
  
  for (const entry of knowledgeEntries) {
    try {
      console.log(`Processing: [${entry.category}] ${entry.title}`);
      
      // Generate embedding for the content
      const textToEmbed = `${entry.title}. ${entry.content}`;
      const embedding = await generateEmbedding(textToEmbed);
      
      // Insert into database
      const { error: insertError } = await supabase
        .from('ai_knowledge_base')
        .insert({
          category: entry.category,
          title: entry.title,
          content: entry.content,
          embedding: embedding,
          source: entry.source,
          is_verified: true
        });
      
      if (insertError) {
        console.error(`  Error inserting: ${insertError.message}`);
        errorCount++;
      } else {
        console.log(`  Success!`);
        successCount++;
      }
      
      // Small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 200));
      
    } catch (error) {
      console.error(`  Error processing ${entry.title}:`, error.message);
      errorCount++;
    }
  }
  
  console.log(`\n========================================`);
  console.log(`Seeding complete!`);
  console.log(`  Successful: ${successCount}`);
  console.log(`  Errors: ${errorCount}`);
  console.log(`  Total entries: ${knowledgeEntries.length}`);
  console.log(`========================================\n`);
}

// Run the seed function
seedKnowledgeBase()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
