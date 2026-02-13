ALTER TABLE users ALTER COLUMN apple_user_id DROP NOT NULL;

ALTER TABLE users ADD COLUMN IF NOT EXISTS google_user_id VARCHAR(255) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

CREATE INDEX IF NOT EXISTS idx_users_google_user_id ON users(google_user_id);
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);
