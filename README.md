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

### Backend
```bash
cd backend
npm install
npm start
```

### iOS App
Open `ios-app/DogHealthApp.xcodeproj` in Xcode and run.

## API Endpoints

- `POST /api/chat` - Send message to AI chatbot
- `GET /api/health` - Health check endpoint

## Safety Notice

This app provides general information only and is not a substitute for professional veterinary advice. Always consult with a qualified veterinarian for serious health concerns.
