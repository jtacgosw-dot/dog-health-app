
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS vector;


CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    apple_user_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    full_name VARCHAR(255),
    subscription_status VARCHAR(50) DEFAULT 'free' CHECK (subscription_status IN ('free', 'pup_monthly', 'pup_annual')),
    subscription_expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP
);

CREATE TABLE dogs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    breed VARCHAR(100),
    age_years INTEGER CHECK (age_years >= 0),
    age_months INTEGER CHECK (age_months >= 0 AND age_months < 12),
    weight_lbs DECIMAL(5,2) CHECK (weight_lbs > 0),
    sex VARCHAR(10) CHECK (sex IN ('male', 'female', 'unknown')),
    is_neutered BOOLEAN,
    medical_history TEXT,
    allergies TEXT,
    current_medications TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dog_id UUID REFERENCES dogs(id) ON DELETE SET NULL,
    title VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_archived BOOLEAN DEFAULT false
);

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    tokens_used INTEGER CHECK (tokens_used >= 0),
    model_used VARCHAR(50),
    feedback VARCHAR(20) CHECK (feedback IN ('positive', 'negative') OR feedback IS NULL),
    feedback_comment TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id VARCHAR(50) NOT NULL CHECK (product_id IN ('pup_monthly', 'pup_annual')),
    transaction_id VARCHAR(255) UNIQUE NOT NULL,
    original_transaction_id VARCHAR(255),
    purchase_date TIMESTAMP NOT NULL,
    expires_date TIMESTAMP,
    is_trial BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    cancellation_date TIMESTAMP,
    receipt_data JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ai_knowledge_base (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536),
    source VARCHAR(255),
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE usage_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);


CREATE INDEX idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription_status ON users(subscription_status);

CREATE INDEX idx_dogs_user_id ON dogs(user_id);
CREATE INDEX idx_dogs_is_active ON dogs(is_active);

CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_dog_id ON conversations(dog_id);
CREATE INDEX idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX idx_conversations_is_archived ON conversations(is_archived);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_messages_role ON messages(role);
CREATE INDEX idx_messages_feedback ON messages(feedback);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_transaction_id ON subscriptions(transaction_id);
CREATE INDEX idx_subscriptions_is_active ON subscriptions(is_active);
CREATE INDEX idx_subscriptions_expires_date ON subscriptions(expires_date);

CREATE INDEX idx_ai_knowledge_category ON ai_knowledge_base(category);
CREATE INDEX idx_ai_knowledge_embedding ON ai_knowledge_base USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE INDEX idx_analytics_user_id ON usage_analytics(user_id);
CREATE INDEX idx_analytics_event_type ON usage_analytics(event_type);
CREATE INDEX idx_analytics_created_at ON usage_analytics(created_at DESC);


CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_conversation_title()
RETURNS TRIGGER AS $$
DECLARE
    conv_title TEXT;
BEGIN
    IF NEW.role = 'user' THEN
        SELECT title INTO conv_title FROM conversations WHERE id = NEW.conversation_id;
        IF conv_title IS NULL THEN
            UPDATE conversations 
            SET title = LEFT(NEW.content, 50) || CASE WHEN LENGTH(NEW.content) > 50 THEN '...' ELSE '' END
            WHERE id = NEW.conversation_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_subscription_status(user_uuid UUID)
RETURNS TABLE(is_subscribed BOOLEAN, subscription_type VARCHAR, expires_at TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN s.expires_date IS NULL OR s.expires_date > NOW() THEN true
            ELSE false
        END as is_subscribed,
        s.product_id as subscription_type,
        s.expires_date as expires_at
    FROM subscriptions s
    WHERE s.user_id = user_uuid
        AND s.is_active = true
    ORDER BY s.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dogs_updated_at
    BEFORE UPDATE ON dogs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_knowledge_base_updated_at
    BEFORE UPDATE ON ai_knowledge_base
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER auto_generate_conversation_title
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_title();


ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogs ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_knowledge_base ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can view their own dogs"
    ON dogs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own dogs"
    ON dogs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own dogs"
    ON dogs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own dogs"
    ON dogs FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own conversations"
    ON conversations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own conversations"
    ON conversations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations"
    ON conversations FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations"
    ON conversations FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view messages in their conversations"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create messages in their conversations"
    ON messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view their own subscriptions"
    ON subscriptions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can view knowledge base"
    ON ai_knowledge_base FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can view their own analytics"
    ON usage_analytics FOR SELECT
    USING (auth.uid() = user_id);


COMMENT ON TABLE users IS 'Stores user account information from Sign in with Apple';
COMMENT ON TABLE dogs IS 'Stores information about users dogs';
COMMENT ON TABLE conversations IS 'Stores chat conversation threads';
COMMENT ON TABLE messages IS 'Stores individual messages within conversations';
COMMENT ON TABLE subscriptions IS 'Stores subscription transaction history and receipts';
COMMENT ON TABLE ai_knowledge_base IS 'Stores curated dog health knowledge for RAG';
COMMENT ON TABLE usage_analytics IS 'Stores usage metrics for monitoring and improvement';
