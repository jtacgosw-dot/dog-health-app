# Dog Health App

A comprehensive dog health iOS application with AI-powered chatbot assistance.

## Project Structure

- `ios-app/` - SwiftUI iOS application
- `backend/` - Node.js/Express backend with OpenAI integration

## Features

### MVP
- AI-powered chatbot for dog health questions
- Safety disclaimers for all responses
- Clean SwiftUI interface
- Backend API integration

### Future Features
- Medication reminders
- Weight tracking
- Emergency vet finder
- Multi-pet profiles

## Setup

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file based on `.env.example`:
   ```bash
   cp .env.example .env
   ```

4. Add your OpenAI API key to the `.env` file:
   ```
   OPENAI_API_KEY=your_actual_openai_api_key_here
   ```

5. Start the server:
   ```bash
   npm start
   ```

The server will run on `http://localhost:3000`

### iOS App Setup
1. Open `ios-app/DogHealthApp.xcodeproj` in Xcode
2. Build and run the project

## API Endpoints

### Health Check
```bash
curl -X GET http://localhost:3000/api/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-09-29T21:20:23.253Z",
  "service": "dog-health-backend"
}
```

### Chat Endpoint
```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "My dog seems lethargic today, should I be worried?"}'
```

Response:
```json
{
  "response": "AI response with health advice...",
  "disclaimer": "⚠️ IMPORTANT: This information is for educational purposes only and should not replace professional veterinary advice. If your dog is showing concerning symptoms, please consult with a licensed veterinarian immediately. For emergency situations, contact your nearest emergency veterinary clinic."
}
```

## Required Environment Variables

- `OPENAI_API_KEY` - Your OpenAI API key (required)
- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)
- `SUPABASE_URL` - Supabase database URL (for future use)
- `SUPABASE_ANON_KEY` - Supabase anonymous key (for future use)

## Development

### Running the Backend Locally
```bash
cd backend
npm install && npm start
```

### Testing the API
Use the curl examples above to test the health check and chat endpoints.

## Contributing

1. Copy `.env.example` to `.env` and fill in your API keys
2. Follow the setup instructions above
3. Make your changes and test locally
4. Submit a pull request

## Safety Notice

This app provides general information only and is not a substitute for professional veterinary advice. Always consult with a qualified veterinarian for serious health concerns.
