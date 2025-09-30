# Dog Health iOS App

A SwiftUI iOS app for dog health assistance with AI-powered chat functionality, featuring Sign in with Apple authentication and StoreKit 2 subscriptions.

## Project Structure

```
dog-health-app/
├── ios-app/                 # SwiftUI iOS application
│   └── DogHealthApp/
│       ├── Views/           # SwiftUI views (Chat, Paywall, Auth)
│       ├── Models/          # Data models
│       ├── Services/        # API, Auth, and Subscription services
│       └── Utils/           # Utility functions
├── backend/                 # Node.js Express server
│   ├── routes/              # API route handlers
│   ├── utils/               # Utility functions (Supabase, JWT)
│   ├── middleware/          # Express middleware (Auth)
│   └── database/            # Database schema
└── README.md
```

## Features

### iOS App (SwiftUI)
- **Sign in with Apple**: Secure authentication using Apple ID
- **StoreKit 2 Subscriptions**: Monthly/Annual subscription plans
- **Onboarding Flow**: Welcome screen with app introduction
- **Safety Disclaimer**: Required disclaimer before accessing chat
- **Chat Interface**: Real-time messaging with AI assistant (subscription required)
- **Paywall**: Subscription management and purchase flow
- **Account Management**: Delete account functionality

### Backend API (Node.js/Express)
- **Apple Authentication**: Verify Apple identity tokens
- **Subscription Validation**: App Store Server API integration
- **Database Integration**: Supabase for user and entitlement management
- **Gated Chat**: AI chat requires active subscription
- **Webhook Support**: App Store Server Notifications handling
- **JWT Sessions**: Secure session management

## Setup Instructions

### Backend Setup

1. **Install Dependencies**
   ```bash
   cd backend
   npm install
   ```

2. **Environment Configuration**
   Create a `.env` file in the `backend` directory:
   ```bash
   cp .env.example .env
   ```
   
   Update the `.env` file with your values:
   ```
   # OpenAI API Configuration
   OPENAI_API_KEY=your_openai_api_key_here
   
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   
   # Database Configuration
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key_here
   
   # Apple Authentication
   APPLE_ISSUER_ID=your_apple_issuer_id_here
   APPLE_KEY_ID=your_apple_key_id_here
   APPLE_PRIVATE_KEY=your_apple_private_key_here
   BUNDLE_ID=com.yourco.puppal
   
   # JWT Configuration
   JWT_SECRET=your_jwt_secret_here
   
   # Apple Environment (sandbox or production)
   APPLE_ENV=sandbox
   ```

3. **Database Setup**
   Execute the SQL schema in `backend/database/schema.sql` in your Supabase project:
   ```sql
   -- Create users table
   create table if not exists users (
     id uuid primary key default gen_random_uuid(),
     apple_sub text unique not null,
     created_at timestamptz default now()
   );

   -- Create entitlements table
   create table if not exists entitlements (
     user_id uuid references users(id) on delete cascade,
     is_active boolean not null default false,
     product_id text,
     renews_at timestamptz,
     updated_at timestamptz default now(),
     primary key (user_id)
   );
   ```

4. **Start the Server**
   ```bash
   npm start
   ```
   
   The server will run on `http://localhost:3000`

### iOS App Setup

1. **Open in Xcode**
   ```bash
   open ios-app/DogHealthApp.xcodeproj
   ```

2. **Configure App Store Connect**
   - Set up your app in App Store Connect
   - Configure subscription products: `pup_monthly`, `pup_annual`
   - Enable Sign in with Apple capability

3. **Update Bundle ID**
   - Set your bundle identifier in Xcode
   - Update `BUNDLE_ID` in backend `.env` to match

4. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd+R` to build and run

## API Endpoints

### Health Check
```bash
curl https://dog-health-app.onrender.com/api/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "service": "dog-health-backend"
}
```

### Apple Authentication
```bash
curl -X POST https://dog-health-app.onrender.com/api/auth/apple \
  -H "Content-Type: application/json" \
  -d '{
    "identityToken": "<apple_identity_token>"
  }'
```

**Response:**
```json
{
  "success": true,
  "token": "<jwt_session_token>",
  "user": {
    "id": "uuid",
    "appleSub": "apple_subject_id",
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Check Entitlements
```bash
curl https://dog-health-app.onrender.com/api/entitlements \
  -H "Authorization: Bearer <session_jwt>"
```

**Response:**
```json
{
  "isActive": true,
  "productId": "pup_monthly",
  "renewsAt": "2024-02-01T00:00:00.000Z"
}
```

### Verify In-App Purchase
```bash
curl -X POST https://dog-health-app.onrender.com/api/iap/verify \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <session_jwt>" \
  -d '{
    "transactionId": "<storekit_transaction_id>",
    "productId": "pup_monthly"
  }'
```

### Chat (Requires Active Subscription)
```bash
curl -X POST https://dog-health-app.onrender.com/api/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <session_jwt>" \
  -d '{
    "message": "My dog seems lethargic today",
    "conversationHistory": []
  }'
```

**Response:**
```json
{
  "response": "I understand your concern about your dog's lethargy...",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "conversationId": null
}
```

### Delete Account
```bash
curl -X DELETE https://dog-health-app.onrender.com/api/account \
  -H "Authorization: Bearer <session_jwt>"
```

## Sandbox Testing

### Prerequisites
1. Create a sandbox Apple ID in App Store Connect
2. Configure test subscription products in App Store Connect
3. Set `APPLE_ENV=sandbox` in backend environment

### Test Flow
1. **Sign in with Apple**
   - Use sandbox Apple ID on iOS device/simulator
   - App receives identity token and exchanges for session JWT

2. **Purchase Subscription**
   - Tap subscription option in paywall
   - Complete sandbox purchase flow
   - App sends transaction to `/api/iap/verify`

3. **Verify Backend**
   - Backend validates transaction with App Store Server API
   - Updates entitlements table with `is_active=true`
   - Chat functionality becomes available

4. **Test Restore Purchases**
   - Delete and reinstall app
   - Sign in with same Apple ID
   - Tap "Restore Purchases"
   - Subscription should be restored

5. **Test Account Deletion**
   - Go to Settings in app
   - Tap "Delete Account"
   - Confirm deletion
   - User data should be removed from database

## Environment Variables

### Required
- `OPENAI_API_KEY`: Your OpenAI API key for chat functionality
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Supabase service role key
- `APPLE_ISSUER_ID`: Apple App Store Connect Issuer ID
- `APPLE_KEY_ID`: Apple App Store Connect Key ID
- `APPLE_PRIVATE_KEY`: Apple App Store Connect Private Key (.p8 file contents)
- `BUNDLE_ID`: iOS app bundle identifier
- `JWT_SECRET`: Secret for signing session tokens

### Optional
- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment mode (development/production)
- `APPLE_ENV`: Apple environment (sandbox/production, default: sandbox)

## Deployment

The backend is deployed on Render at: https://dog-health-app.onrender.com

### Production API Endpoints
- Health: `https://dog-health-app.onrender.com/api/health`
- Apple Auth: `https://dog-health-app.onrender.com/api/auth/apple`
- Entitlements: `https://dog-health-app.onrender.com/api/entitlements`
- IAP Verify: `https://dog-health-app.onrender.com/api/iap/verify`
- Chat: `https://dog-health-app.onrender.com/api/chat`
- Account: `https://dog-health-app.onrender.com/api/account`
- Webhook: `https://dog-health-app.onrender.com/api/webhook/apple-asn`

## Safety & Compliance

- All AI responses include safety disclaimers
- Users are advised to consult veterinarians for serious concerns
- No medical diagnosis or treatment recommendations provided
- Emergency situations redirect to professional veterinary care
- Sign in with Apple provides privacy-focused authentication
- Account deletion removes all user data for GDPR compliance
- Subscription validation prevents unauthorized access to premium features
