const { createClient } = require('@supabase/supabase-js');

let supabase = null;

if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY) {
  supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
  );
  console.log('✅ Supabase client initialized');
} else {
  console.warn('⚠️  Supabase credentials not found - client not initialized');
  console.warn('   Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env file');
}

module.exports = supabase;
