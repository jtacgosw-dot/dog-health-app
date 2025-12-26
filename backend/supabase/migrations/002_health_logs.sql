-- Health Logs table for storing pet health entries
-- This table syncs with the iOS app's SwiftData HealthLogEntry model

CREATE TABLE health_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dog_id UUID NOT NULL REFERENCES dogs(id) ON DELETE CASCADE,
    log_type VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    notes TEXT,
    
    -- Meal-specific fields
    meal_type VARCHAR(50),
    amount VARCHAR(100),
    
    -- Activity-specific fields (walk, playtime)
    duration VARCHAR(50),
    activity_type VARCHAR(100),
    
    -- Health-specific fields
    mood_level INTEGER CHECK (mood_level >= 0 AND mood_level <= 4),
    symptom_type VARCHAR(100),
    severity_level INTEGER CHECK (severity_level >= 1 AND severity_level <= 5),
    digestion_quality VARCHAR(50),
    
    -- Other fields
    supplement_name VARCHAR(100),
    dosage VARCHAR(100),
    appointment_type VARCHAR(100),
    location VARCHAR(255),
    grooming_type VARCHAR(100),
    treat_name VARCHAR(100),
    water_amount VARCHAR(100),
    
    -- Sync metadata
    client_id VARCHAR(100), -- UUID from iOS device for deduplication
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX idx_health_logs_user_id ON health_logs(user_id);
CREATE INDEX idx_health_logs_dog_id ON health_logs(dog_id);
CREATE INDEX idx_health_logs_timestamp ON health_logs(timestamp DESC);
CREATE INDEX idx_health_logs_log_type ON health_logs(log_type);
CREATE INDEX idx_health_logs_client_id ON health_logs(client_id);
CREATE INDEX idx_health_logs_is_deleted ON health_logs(is_deleted);

-- Composite index for common query pattern
CREATE INDEX idx_health_logs_dog_timestamp ON health_logs(dog_id, timestamp DESC);

-- Trigger for updated_at
CREATE TRIGGER update_health_logs_updated_at
    BEFORE UPDATE ON health_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security
ALTER TABLE health_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own health logs"
    ON health_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own health logs"
    ON health_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own health logs"
    ON health_logs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own health logs"
    ON health_logs FOR DELETE
    USING (auth.uid() = user_id);

COMMENT ON TABLE health_logs IS 'Stores health log entries for pets, synced from iOS app';
COMMENT ON COLUMN health_logs.client_id IS 'UUID from iOS device for deduplication during sync';
COMMENT ON COLUMN health_logs.is_deleted IS 'Soft delete flag for sync - deleted entries are marked but not removed';
