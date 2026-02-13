-- Migration: Add multi-auth support columns to users table
-- This allows Google Sign-In, email/password auth alongside Apple Sign-In
--
-- IMPORTANT: Run this migration on your Supabase database to enable:
-- 1. Google Sign-In (google_user_id column)
-- 2. Email/password auth (password_hash column)
-- 3. Auth provider tracking (auth_provider column)
-- 4. Conversation pinning (is_pinned column on conversations)
--
-- After running this migration, the backend code will automatically
-- use the proper columns instead of the apple_user_id workaround.

-- Add google_user_id column for Google Sign-In users
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_user_id VARCHAR(255);

-- Add auth_provider column to track how user signed up
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(50);

-- Add password_hash column for email/password auth
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

-- Make apple_user_id nullable so non-Apple auth methods can create users
-- (The backend code provides a workaround value, but this is the proper fix)
ALTER TABLE users ALTER COLUMN apple_user_id DROP NOT NULL;

-- Add unique index on google_user_id (only for non-null values)
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_google_user_id
    ON users(google_user_id) WHERE google_user_id IS NOT NULL;

-- Add index on auth_provider for queries
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);

-- Add is_pinned column to conversations table for pinning support
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false;

-- Add index for pinned conversations
CREATE INDEX IF NOT EXISTS idx_conversations_is_pinned ON conversations(is_pinned);
