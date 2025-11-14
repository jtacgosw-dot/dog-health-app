# Database Schema Design - Dog Health App

## Overview
This document defines the complete database schema for the Dog Health App, including all tables, relationships, indexes, and constraints.

## Database: Supabase (PostgreSQL)

---

## Tables

### 1. users
Stores user account information from Sign in with Apple.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique user identifier |
| apple_user_id | VARCHAR(255) | UNIQUE, NOT NULL | Apple Sign In user identifier |
| email | VARCHAR(255) | UNIQUE | User email (optional from Apple) |
| full_name | VARCHAR(255) | | User's full name |
| subscription_status | VARCHAR(50) | DEFAULT 'free' | free, pup_monthly, pup_annual |
| subscription_expires_at | TIMESTAMP | | Subscription expiration date |
| created_at | TIMESTAMP | DEFAULT NOW() | Account creation timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update timestamp |
| last_login_at | TIMESTAMP | | Last login timestamp |

**Indexes:**
- `idx_users_apple_user_id` on `apple_user_id`
- `idx_users_email` on `email`
- `idx_users_subscription_status` on `subscription_status`

---

### 2. dogs
Stores information about users' dogs.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique dog identifier |
| user_id | UUID | FOREIGN KEY REFERENCES users(id) ON DELETE CASCADE, NOT NULL | Owner's user ID |
| name | VARCHAR(100) | NOT NULL | Dog's name |
| breed | VARCHAR(100) | | Dog's breed |
| age_years | INTEGER | | Dog's age in years |
| age_months | INTEGER | | Additional months |
| weight_lbs | DECIMAL(5,2) | | Dog's weight in pounds |
| sex | VARCHAR(10) | | male, female, unknown |
| is_neutered | BOOLEAN | | Neutered/spayed status |
| medical_history | TEXT | | Medical history notes |
| allergies | TEXT | | Known allergies |
| current_medications | TEXT | | Current medications |
| is_active | BOOLEAN | DEFAULT true | Whether this dog profile is active |
| created_at | TIMESTAMP | DEFAULT NOW() | Profile creation timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `idx_dogs_user_id` on `user_id`
- `idx_dogs_is_active` on `is_active`

---

### 3. conversations
Stores chat conversation threads.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique conversation identifier |
| user_id | UUID | FOREIGN KEY REFERENCES users(id) ON DELETE CASCADE, NOT NULL | User who owns this conversation |
| dog_id | UUID | FOREIGN KEY REFERENCES dogs(id) ON DELETE SET NULL | Associated dog (optional) |
| title | VARCHAR(255) | | Auto-generated conversation title |
| created_at | TIMESTAMP | DEFAULT NOW() | Conversation start timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last message timestamp |
| is_archived | BOOLEAN | DEFAULT false | Whether conversation is archived |

**Indexes:**
- `idx_conversations_user_id` on `user_id`
- `idx_conversations_dog_id` on `dog_id`
- `idx_conversations_created_at` on `created_at DESC`
- `idx_conversations_is_archived` on `is_archived`

---

### 4. messages
Stores individual messages within conversations.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique message identifier |
| conversation_id | UUID | FOREIGN KEY REFERENCES conversations(id) ON DELETE CASCADE, NOT NULL | Parent conversation |
| role | VARCHAR(20) | NOT NULL | user, assistant, system |
| content | TEXT | NOT NULL | Message content |
| tokens_used | INTEGER | | Number of tokens used (for AI responses) |
| model_used | VARCHAR(50) | | AI model used (e.g., gpt-4) |
| feedback | VARCHAR(20) | | positive, negative, null |
| feedback_comment | TEXT | | Optional user feedback comment |
| created_at | TIMESTAMP | DEFAULT NOW() | Message timestamp |

**Indexes:**
- `idx_messages_conversation_id` on `conversation_id`
- `idx_messages_created_at` on `created_at`
- `idx_messages_role` on `role`
- `idx_messages_feedback` on `feedback`

---

### 5. subscriptions
Stores subscription transaction history and receipts.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique subscription record |
| user_id | UUID | FOREIGN KEY REFERENCES users(id) ON DELETE CASCADE, NOT NULL | User who purchased |
| product_id | VARCHAR(50) | NOT NULL | pup_monthly or pup_annual |
| transaction_id | VARCHAR(255) | UNIQUE, NOT NULL | Apple transaction ID |
| original_transaction_id | VARCHAR(255) | | Original transaction ID for renewals |
| purchase_date | TIMESTAMP | NOT NULL | Purchase timestamp |
| expires_date | TIMESTAMP | | Expiration timestamp |
| is_trial | BOOLEAN | DEFAULT false | Whether this is a trial period |
| is_active | BOOLEAN | DEFAULT true | Whether subscription is currently active |
| cancellation_date | TIMESTAMP | | When subscription was cancelled |
| receipt_data | JSONB | | Full receipt data from Apple |
| created_at | TIMESTAMP | DEFAULT NOW() | Record creation timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `idx_subscriptions_user_id` on `user_id`
- `idx_subscriptions_transaction_id` on `transaction_id`
- `idx_subscriptions_is_active` on `is_active`
- `idx_subscriptions_expires_date` on `expires_date`

---

### 6. ai_knowledge_base
Stores curated dog health knowledge for RAG (Retrieval Augmented Generation).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique knowledge entry |
| category | VARCHAR(100) | NOT NULL | Category (symptoms, breeds, conditions, etc.) |
| title | VARCHAR(255) | NOT NULL | Entry title |
| content | TEXT | NOT NULL | Knowledge content |
| embedding | VECTOR(1536) | | OpenAI embedding vector for semantic search |
| source | VARCHAR(255) | | Source of information |
| is_verified | BOOLEAN | DEFAULT false | Whether content is verified by expert |
| created_at | TIMESTAMP | DEFAULT NOW() | Entry creation timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `idx_ai_knowledge_category` on `category`
- `idx_ai_knowledge_embedding` using ivfflat on `embedding` (for vector similarity search)

---

### 7. usage_analytics
Stores usage metrics for monitoring and improvement.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique analytics record |
| user_id | UUID | FOREIGN KEY REFERENCES users(id) ON DELETE CASCADE | User (nullable for anonymous events) |
| event_type | VARCHAR(50) | NOT NULL | Event type (chat_sent, subscription_started, etc.) |
| event_data | JSONB | | Additional event data |
| created_at | TIMESTAMP | DEFAULT NOW() | Event timestamp |

**Indexes:**
- `idx_analytics_user_id` on `user_id`
- `idx_analytics_event_type` on `event_type`
- `idx_analytics_created_at` on `created_at DESC`

---

## Relationships

```
users (1) ──< (many) dogs
users (1) ──< (many) conversations
users (1) ──< (many) subscriptions
users (1) ──< (many) usage_analytics

dogs (1) ──< (many) conversations

conversations (1) ──< (many) messages
```

---

## Row Level Security (RLS) Policies

### users table
- Users can only read/update their own record
- No user can delete their own record (admin only)

### dogs table
- Users can only CRUD their own dogs

### conversations table
- Users can only CRUD their own conversations

### messages table
- Users can only read/create messages in their own conversations
- Users cannot update/delete messages (audit trail)

### subscriptions table
- Users can only read their own subscription records
- Only backend can create/update subscription records

### ai_knowledge_base table
- All authenticated users can read
- Only admins can create/update/delete

### usage_analytics table
- Users can only read their own analytics
- Backend can create analytics for any user

---

## Triggers

### update_updated_at_trigger
Automatically updates `updated_at` timestamp on row modification for:
- users
- dogs
- conversations
- subscriptions
- ai_knowledge_base

---

## Functions

### update_conversation_title()
Automatically generates conversation title from first user message.

### check_subscription_status()
Checks if user's subscription is still valid based on expires_date.

### calculate_dog_age()
Calculates dog's age in human years based on breed and age.

---

## Migration Strategy

1. Create tables in order (respecting foreign key dependencies)
2. Create indexes
3. Enable RLS policies
4. Create triggers and functions
5. Seed initial ai_knowledge_base data

---

## Backup & Recovery

- Supabase provides automatic daily backups
- Point-in-time recovery available
- Export scripts for manual backups

---

## Performance Considerations

- All foreign keys have indexes
- Frequently queried columns have indexes
- Vector similarity search uses ivfflat index for performance
- Partitioning strategy for messages table if volume exceeds 10M rows

---

## Security Considerations

- All tables use RLS policies
- Sensitive data (receipts) stored in JSONB with encryption at rest
- API keys and secrets stored in environment variables, not database
- User emails are optional and can be null for privacy

---

## Future Enhancements

- Add `notifications` table for push notifications
- Add `veterinarians` table for vet recommendations
- Add `appointments` table for vet appointment tracking
- Add `symptoms_log` table for structured symptom tracking
- Add `photos` table for dog photos and symptom images
