# Environment Variables

This document lists all required environment variables for the Dog Health App backend and iOS app.

## Backend Environment Variables

The backend requires the following environment variables to be set in a `.env` file in the `/backend` directory:

### Supabase Configuration
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous/public key
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (for server-side operations)

### Apple Sign In Configuration
- `APPLE_TEAM_ID` - Apple Developer Team ID
- `APPLE_CLIENT_ID` - Apple Services ID (e.g., com.johnathongordon.doghealthapp.signin)
- `APPLE_KEY_ID` - Apple Sign In Key ID
- `APPLE_PRIVATE_KEY` - Apple Sign In private key (PEM format)

### StoreKit / In-App Purchase Configuration
- `APPLE_SHARED_SECRET` - App-specific shared secret for receipt verification
- `APPLE_BUNDLE_ID` - iOS app bundle identifier (com.johnathongordon.doghealthapp)

### Server Configuration
- `PORT` - Port for the Express server (default: 3000)
- `NODE_ENV` - Environment (development, production)

### API Keys (Future)
- `OPENAI_API_KEY` - OpenAI API key for AI chat functionality (to be added later)

## iOS App Configuration

The iOS app uses a configuration file to point to the backend API:

- **Backend Base URL:** `https://dog-health-app.onrender.com/api/`

This is configured in the app's `APIConfig.swift` file.

## Setup Instructions

1. Copy `.env.example` to `.env` in the `/backend` directory
2. Fill in all required values
3. Never commit the `.env` file to version control
4. For production deployment on Render, set these as environment variables in the Render dashboard

## TODO

- [ ] Obtain Supabase credentials
- [ ] Configure Apple Sign In service ID and keys
- [ ] Generate App-specific shared secret in App Store Connect
- [ ] Set up production environment variables on Render
