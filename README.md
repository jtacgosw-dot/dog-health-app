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

1. **Install Fastlane dependencies:**
   ```bash
   cd ios-app
   bundle install
   ```

2. **Open in Xcode**
   ```bash
   open ios-app/DogHealthApp.xcodeproj
   ```

3. **Configure App Store Connect**
   - Set up your app in App Store Connect
   - Configure subscription products: `pup_monthly`, `pup_annual`
   - Enable Sign in with Apple capability

4. **Update Bundle ID**
   - Set your bundle identifier in Xcode
   - Update `BUNDLE_ID` in backend `.env` to match

5. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd+R` to build and run

### TestFlight Deployment

1. **Setup certificates (first time only):**
   ```bash
   cd ios-app
   bundle exec fastlane certificates
   ```

2. **Deploy to TestFlight:**
   ```bash
   bundle exec fastlane beta
   ```

### GitHub Secrets Configuration

For automated CI/CD, configure these secrets in your GitHub repository:

- `APPLE_ISSUER_ID`: Your App Store Connect API issuer ID
- `APPLE_KEY_ID`: Your App Store Connect API key ID  
- `APPLE_PRIVATE_KEY`: Your App Store Connect API private key
- `APPLE_TEAM_ID`: Your Apple Developer Team ID
- `BUNDLE_ID`: Your app's bundle identifier
- `MATCH_PASSWORD`: Password for encrypting certificates in Match
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`: App-specific password for Apple ID
- `MATCH_GIT_BASIC_AUTHORIZATION`: Base64 encoded git credentials for certificate repository

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

## TestFlight Distribution

### Prerequisites
1. **Apple Developer Program membership** ($99/year)
2. **App Store Connect access** with Admin or App Manager role
3. **Certificates and Provisioning Profiles** configured in Apple Developer portal
4. **App Store Connect API Key** for automated uploads

### GitHub Secrets Configuration
Configure the following secrets in GitHub repository settings:

```bash
APPLE_ID                    # Your Apple ID email
APPLE_APP_PASSWORD         # App-specific password from Apple ID
APPLE_TEAM_ID              # Your Apple Developer Team ID (10-character string)
APPLE_CERTIFICATE_P12      # Base64 encoded .p12 certificate
APPLE_CERTIFICATE_PASSWORD # Password for .p12 certificate
APPLE_PROVISIONING_PROFILE # Base64 encoded provisioning profile
```

**To get these values:**

1. **APPLE_ID**: Your Apple Developer account email
2. **APPLE_APP_PASSWORD**: Generate at [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords
3. **APPLE_TEAM_ID**: Found in Apple Developer portal → Membership → Team ID
4. **APPLE_CERTIFICATE_P12**: 
   - Export iOS Distribution certificate from Keychain Access as .p12
   - Convert to base64: `base64 -i certificate.p12 | pbcopy`
5. **APPLE_CERTIFICATE_PASSWORD**: Password you set when exporting the .p12
6. **APPLE_PROVISIONING_PROFILE**:
   - Download App Store provisioning profile from Apple Developer portal
   - Convert to base64: `base64 -i profile.mobileprovision | pbcopy`

### Manual TestFlight Build
1. Open `ios-app/DogHealthApp.xcodeproj` in Xcode
2. Select "Any iOS Device" as destination
3. Product → Archive
4. In Organizer, select "Distribute App"
5. Choose "App Store Connect" → "Upload"
6. Follow prompts to upload to TestFlight

### Automated TestFlight Build
1. Configure GitHub Secrets (see above)
2. Set `APPLE_CERTIFICATES_AVAILABLE: 'true'` in workflow
3. Push to main branch or create PR
4. GitHub Actions will build and upload to TestFlight automatically

### Testing the App
1. Install TestFlight app on iPhone
2. Accept TestFlight invite (sent via email)
3. Install Dog Health app from TestFlight
4. Test complete flow:
   - Onboarding screen
   - Safety disclaimer acceptance
   - Sign in with Apple (use sandbox Apple ID)
   - Chat screen should be accessible (entitlements mocked as active)
   - Test AI chat functionality with live backend

### Alternative Testing Without TestFlight
Since TestFlight requires Apple Developer credentials, you can test the app using:

1. **iOS Simulator** (requires Xcode on macOS):
   ```bash
   cd ios-app
   xcodebuild -project DogHealthApp.xcodeproj \
     -scheme DogHealthApp \
     -destination 'platform=iOS Simulator,name=iPhone 15' \
     build
   ```

2. **Local Device Testing** (requires development provisioning profile):
   - Connect iPhone via USB
   - Enable Developer Mode in iPhone Settings
   - Build and run from Xcode

3. **GitHub Actions Build Verification**:
   - Push changes to trigger workflow
   - Check that build completes successfully
   - Download build artifacts for manual testing

### Current Limitations
- **Entitlements are mocked as active** to bypass Apple credentials requirement
- **TestFlight upload requires** Apple Developer Program membership and certificates
- **Sign in with Apple** will work in sandbox mode but requires Apple Developer configuration for production

### Expected App Flow with Mocked Entitlements
With the current mocking configuration, the app flow will be:

1. **Onboarding Screen** → User taps "Get Started" → `hasCompletedOnboarding = true`
2. **Safety Disclaimer Screen** → User taps "I Understand" → `hasAcceptedDisclaimer = true`
3. **Sign in with Apple Screen** → User signs in → `isAuthenticated = true`, `hasActiveSubscription = true` (mocked)
4. **Chat Screen** → Directly accessible (skips paywall due to mocked active subscription)
5. **AI Chat Functionality** → Works with live backend API at `https://dog-health-app.onrender.com/api`

### Testing the Complete Flow
To test the app with mocked entitlements:

1. **Build and run** the iOS app in Xcode or iOS Simulator
2. **Navigate through onboarding** and accept the safety disclaimer
3. **Sign in with Apple** (can use any Apple ID in development)
4. **Verify chat screen appears** without showing paywall
5. **Test chat functionality** by sending messages to the AI
6. **Verify API connectivity** by checking network requests in Xcode console

### Screenshots and UI Testing
Key screens to capture for UI/UX review:
- Onboarding screen with app introduction
- Safety disclaimer with veterinary advice warning
- Sign in with Apple authentication screen
- Chat interface with message bubbles and input field
- AI responses with safety disclaimers
- Settings screen with account management options

## Certificate Management

The project uses Fastlane Match for automated certificate and provisioning profile management:

- **Certificates are stored** in a private git repository and encrypted with a password
- **GitHub Actions** automatically handles certificate setup during CI builds
- **Local development** can use `bundle exec fastlane certificates` to sync certificates
- **No manual CSR generation** required - Match handles everything automatically

### Cloud-Based Mac Solutions Analysis

For iOS certificate generation, we evaluated several options:

1. **Fastlane Match (Chosen Solution)** - FREE
   - Uses GitHub Actions macOS runners (included in free tier)
   - Automated certificate and provisioning profile management
   - Industry standard solution with excellent CI integration
   - No additional costs beyond GitHub usage

2. **MacStadium** - $109-399/month
   - Dedicated Mac cloud instances
   - Full macOS environment access
   - Higher cost for occasional certificate generation needs

3. **AWS EC2 Mac Instances** - $15.60-37.44/24hr minimum
   - mac2 instances: $0.65/hr ($15.60/24hr minimum)
   - mac2-m2 instances: $0.878/hr ($21.07/24hr minimum)  
   - mac1 instances: $1.083/hr ($25.99/24hr minimum)
   - mac2-m2pro instances: $1.56/hr ($37.44/24hr minimum)
   - 24-hour minimum billing period on Dedicated Hosts

**Recommendation:** Fastlane Match provides the most cost-effective and maintainable solution for automated iOS certificate management.

## Safety & Compliance

- All AI responses include safety disclaimers
- Users are advised to consult veterinarians for serious concerns
- No medical diagnosis or treatment recommendations provided
- Emergency situations redirect to professional veterinary care
- Sign in with Apple provides privacy-focused authentication
- Account deletion removes all user data for GDPR compliance
- Subscription validation prevents unauthorized access to premium features

<!-- Trigger CI to test updated APPLE_PRIVATE_KEY secret format -->
# Trigger CI to test Fastlane Match with configured secrets
# Test Fastlane Match with configured GitHub secrets
# Trigger CI with updated MATCH_GIT_BASIC_AUTHORIZATION secret
# SSH deploy key fix - trigger CI
# Testing updated SSH deploy key
