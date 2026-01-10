# Petly iOS App - Comprehensive Developer Handoff

## Quick Start (Day 1 Checklist)

Before diving into the codebase, get the app running locally:

**iOS App:**
1. Open `/home/ubuntu/repos/dog-health-app/ios-app/DogHealthApp/DogHealthApp.xcodeproj` in Xcode
2. Select an iPhone simulator (iPhone 15 Pro recommended)
3. Build and run (Cmd+R)
4. The app will connect to `localhost:3000` in simulator, or `https://dog-health-app.onrender.com` on real devices

**Backend:**
1. `cd backend`
2. Copy `.env.example` to `.env` and fill in:
   - `SUPABASE_URL` - Your Supabase project URL
   - `SUPABASE_SERVICE_ROLE_KEY` - Service role key from Supabase dashboard
   - `OPENAI_API_KEY` - For AI chat functionality
3. `npm install && npm start`
4. Server runs on `http://localhost:3000`

**Sanity Test:**
- Open app, use "Continue as Guest" (or Apple Sign In)
- Create a dog profile
- Log a meal or activity
- Open Smart Insights
- Open AI Chat, send a message
- Try uploading an image in chat

---

## Repository Information

| Item | Value |
|------|-------|
| Repository | https://github.com/jtacgosw-dot/dog-health-app |
| Local Path | `/home/ubuntu/repos/dog-health-app` |
| Main Branch | `main` |
| iOS App Path | `ios-app/DogHealthApp` |
| Backend Path | `backend` |
| Production Backend | https://dog-health-app.onrender.com |
| User | Vac (jhngordon2003@gmail.com) / @Vac1234 |

---

## Current State (as of PR #128)

The app is fully functional and builds successfully. It has been tested on an iPhone 16 Pro.

### What's Working

**Core Features:**
- User authentication via Apple Sign In (plus guest mode for testing)
- Multi-pet support with pet switcher
- Daily health logging (meals, activity, symptoms, water, mood, supplements, etc.)
- AI chat powered by GPT-4 with image upload support (GPT-4 Vision)
- Pet health score calculation with ring visualization
- Weight tracking with trend charts
- Cloud sync of health logs to Supabase
- Push notification infrastructure (needs Apple Developer setup)

**Dashboard Features:**
- Daily Health Review - 4-step check-in flow (symptoms, meals, activity, mood)
- Preventative Care Calendar - vaccine/medication reminders with "Due Now" and "Upcoming" sections
- Smart Insights - pattern detection from logged health data (activity trends, recurring symptoms, feeding consistency)
- Health Digest - AI-generated weekly summaries
- Symptom Triage - AI-powered symptom assessment
- Care Plans - customizable health goals

**Settings & Account:**
- Manage Profile - edit pet details (name, breed, age, weight, allergies, health conditions)
- Membership Status - shows subscription tier and benefits
- Direct chat prompts from various screens
- Export data functionality (Vet Visit Pack)

**UI/UX Polish:**
- Consistent green theme (petlyDarkGreen #40462D, petlyLightGreen #E7E3C8, petlyBackground #FAF6EE)
- Dynamic Type support - fonts scale with system text size settings
- Forced Light Mode globally (to prevent white text issues on real devices)
- Global `.buttonStyle(.plain)` to prevent gray blob artifacts
- Standardized typography using Stylish-Regular (titles) and Poppins (body)

### Deployment

**Backend:** Deployed on Render via `render.yaml`. Environment variables are configured in Render dashboard.

**iOS:** The app uses conditional compilation for API URLs:
- Simulator: `http://localhost:3000/api`
- Real device: `https://dog-health-app.onrender.com/api`

---

## Known Issues & Footguns

These are critical things that have caused build failures or bugs in the past:

### 1. AppState Property Names
**Always use `appState.currentDog`, NOT `appState.selectedDog`**. The codebase had inconsistency here that caused 15+ build errors.

### 2. Duplicate Struct Names
Check for naming conflicts when adding new structs. Examples that caused issues:
- `InsightCard` existed in both `SmartInsightsView.swift` and `NewMainTabView.swift` (renamed to `HealthInsightCard`)
- `StatCard` existed in multiple files
- `ReminderCard` and `AddReminderView` had duplicates

### 3. Optional Chaining on Non-Optional Values
The Dog model has `allergies: [String]` and `healthConcerns: [String]` as non-optional arrays. Don't use `dog.allergies?.joined()` - use `dog.allergies.joined()`.

### 4. SwiftData @Query Macro
Views using `@Query` must be inside a view hierarchy that has `.modelContainer()` applied. The container is set up in `DogHealthAppApp.swift`.

### 5. Deprecated iOS 17 APIs
`onChange(of:perform:)` is deprecated in iOS 17. Use the new `onChange` syntax with two or zero parameter action closure.

### 6. Real Device Rendering Issues
- Gray blob artifacts on buttons: Fixed by applying `.buttonStyle(.plain)` globally
- White text on cards: Fixed by forcing Light Mode globally via `UIUserInterfaceStyle = Light` in Info.plist
- These fixes are intentional - don't remove them thinking they're cleanup opportunities

### 7. No CI Configured
There are currently no CI checks on the repository. Consider adding a basic build/lint workflow.

---

## Tech Stack

### iOS App
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData (local) + Supabase (cloud sync)
- **Minimum iOS:** iOS 17+
- **Architecture:** MVVM-ish with AppState for global state
- **Fonts:** Stylish-Regular (titles), Poppins-Regular/Medium (body)

### Backend
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** Supabase (PostgreSQL)
- **AI:** OpenAI GPT-4 / GPT-4 Vision
- **Auth:** JWT tokens + Apple Sign In + Guest mode

---

## Database Schema (Supabase)

### Core Tables

**users**
- `id` (UUID, PK)
- `apple_user_id` (VARCHAR, unique) - or "guest_" prefix for guest users
- `email`, `full_name`
- `subscription_status` ('free', 'pup_monthly', 'pup_annual')
- `subscription_expires_at`
- `created_at`, `updated_at`, `last_login_at`

**dogs**
- `id` (UUID, PK)
- `user_id` (FK to users)
- `name`, `breed`, `age_years`, `age_months`
- `weight_lbs`, `sex`, `is_neutered`
- `medical_history`, `allergies`, `current_medications` (TEXT fields)
- `is_active` (for soft delete)

**health_logs**
- `id` (UUID, PK)
- `user_id`, `dog_id` (FKs)
- `log_type` (VARCHAR) - meal, walk, playtime, symptom, water, mood, supplement, etc.
- `timestamp`
- Type-specific fields: `meal_type`, `amount`, `duration`, `activity_type`, `mood_level`, `symptom_type`, `severity_level`, etc.
- `client_id` (VARCHAR) - UUID from iOS device for deduplication during sync
- `is_deleted` (soft delete flag)

**conversations** and **messages** - For AI chat history

**subscriptions** - In-app purchase records

**ai_knowledge_base** - Curated dog health knowledge with vector embeddings for RAG (not fully implemented yet)

**usage_analytics** - Event tracking

---

## Remaining Tasks

### High Priority (Blocking Launch)
1. **Apple Developer Setup** - Push notifications require proper certificates and provisioning profiles
2. **In-App Purchase Testing** - Subscription flow needs testing with StoreKit sandbox
3. **App Store Assets** - Screenshots, app description, privacy policy

### Medium Priority (Polish)
1. **Fix Xcode Warnings** - Deprecated `onChange` syntax in NewPetProfileView, NewChatView; unused variables in DailyLogEntryView, HealthDigestView
2. **Duplicate Build File Warnings** - Some files appear twice in Copy Bundle Resources phase (Xcode project configuration issue)
3. **Error Handling** - Improve user-facing error messages throughout the app

### Lower Priority (Nice to Have)
1. **Offline Mode** - Better handling when network is unavailable
2. **Data Migration** - Handle SwiftData schema changes gracefully
3. **Performance** - Profile and optimize if needed on older devices

---

## Future Ideas: Data Roadmap

The user mentioned "the data stuff" as a future focus area. Here are concrete proposals:

### 1. Data Analytics & Visualization
**Goal:** Help users understand their pet's health trends over time.

- **Trend Charts:** Weight over time, symptom frequency, activity levels, mood patterns
- **Correlation Detection:** "Symptoms tend to spike 2 days after food changes"
- **Period Comparisons:** "Last 30 days vs prior 30 days" summaries
- **Health Score History:** Track how the pet health score changes over time

**Implementation:** The `health_logs` table already captures rich data. Build aggregation queries and chart views in SwiftUI using Swift Charts framework.

### 2. Data Export & Sharing
**Goal:** Make health data portable and shareable with vets.

- **Vet Visit Pack Enhancement:** Currently exists but could be expanded
- **PDF Reports:** Configurable date ranges, include/exclude specific log types
- **CSV Export:** For users who want raw data
- **Share Links:** Generate temporary shareable links to health summaries (requires backend work)
- **Photo Attachments:** Include logged photos in exports

### 3. Cloud Sync Improvements
**Goal:** Reliable, conflict-free data synchronization.

- **Conflict Resolution:** Define rules for when local and cloud data conflict
- **Offline-First:** Queue changes when offline, sync when back online
- **Incremental Sync:** Only sync changed records, not full dataset
- **Background Refresh:** Sync in background periodically
- **Sync Status UI:** Show users when data was last synced

### 4. Data Quality & Schema
**Goal:** More structured, queryable data.

- **Normalize Log Types:** Define strict enums for meal types, symptoms, activities instead of freeform strings
- **Validation:** Ensure data integrity before saving
- **Schema Versioning:** Plan for future schema changes with migrations

### 5. Machine Learning (Long-term)
**Goal:** Predictive health insights.

- **Anomaly Detection:** Alert when patterns deviate from normal
- **Predictive Symptoms:** "Based on patterns, watch for X this week"
- **Personalized Recommendations:** AI suggestions based on individual pet's data
- **Breed-Specific Insights:** Compare to typical patterns for the breed

### 6. Privacy & Trust
**Goal:** Build user confidence in data handling.

- **Data Retention Controls:** Let users delete old data
- **Export All Data:** GDPR-style data portability
- **Audit Logging:** Track what data is sent to AI
- **Clear Disclaimers:** "Not veterinary advice" prominently displayed
- **Encryption:** End-to-end encryption for sensitive health data

---

## Key Files Reference

### iOS App Structure
```
ios-app/DogHealthApp/DogHealthApp/
├── DogHealthAppApp.swift          # App entry, AppState class, ModelContainer
├── ContentView.swift              # Root navigation
├── Config/
│   └── APIConfig.swift            # API URL (localhost vs production)
├── Models/
│   ├── Dog.swift                  # Pet model
│   ├── User.swift                 # User model
│   ├── HealthLogEntry.swift       # SwiftData model
│   ├── PetReminder.swift          # SwiftData model
│   ├── PetHealthScore.swift       # Health score calculation
│   └── ...
├── Views/
│   ├── HomeDashboardView.swift    # Main dashboard
│   ├── DailyHealthReviewView.swift # 4-step check-in
│   ├── PreventativeCareView.swift  # Vaccine/med calendar
│   ├── SmartInsightsView.swift     # Pattern detection
│   ├── NewChatView.swift          # AI chat
│   ├── NewPetAccountView.swift    # Account & settings
│   └── ...
├── Services/
│   ├── APIService.swift           # Network layer
│   ├── HealthLogSyncService.swift # Cloud sync
│   └── NotificationManager.swift  # Push notifications
└── Theme/
    └── PetlyColors.swift          # Colors, fonts, Dynamic Type
```

### Backend Structure
```
backend/
├── src/
│   ├── index.js                   # Express server
│   ├── routes/
│   │   ├── auth.js                # Auth endpoints (Apple + guest)
│   │   ├── chat.js                # AI chat with GPT-4
│   │   ├── dogs.js                # Pet CRUD
│   │   └── health-logs.js         # Health log sync
│   ├── services/
│   │   └── openai.js              # OpenAI integration
│   └── middleware/
│       └── auth.js                # JWT verification
├── supabase/
│   └── migrations/                # SQL schema files
└── .env                           # Environment variables
```

---

## Design Philosophy

- **No Gamification:** The user explicitly requested features NOT be like Snapchat streaks. Use "X of 7 days this week" instead of fire emojis and streak counters.
- **Health-Focused:** Features should feel like clinical tools, not social media.
- **Meaningful Milestones:** Sparse achievements like "First full week tracked" rather than frequent badges.
- **Accessibility:** Dynamic Type support ensures the app works for users with vision needs.

---

## PR Workflow

1. Create branch: `git checkout -b devin/$(date +%s)-descriptive-name`
2. Make changes
3. Commit with descriptive message
4. Push: `git push origin branch-name`
5. Create PR using `git_create_pr` tool
6. Wait for CI (if any) using `git_pr_checks`
7. Share PR link with user

---

## What Was Built (PRs #44-#128 Summary)

**UI Consistency (PRs #124, etc.):**
- Standardized typography across all screens
- Consistent card sizes and corner radii (16 for cards, 25 for buttons)
- Unified button styles

**Functional Fixes (PRs #125, etc.):**
- Log Meals button now works
- Export Data functionality
- Theme settings

**Settings/Product (PRs #126, etc.):**
- Manage Profile screen (edit pet details)
- Membership status display
- Direct chat prompts from various screens

**Dynamic Type (PR #127):**
- All fonts use `relativeTo:` parameter for scaling
- `@ScaledMetric` for icons and spacing
- Flexible card heights with `minHeight` instead of fixed

**AI Chat Enhancements (PRs #80, #86-#88, #121-#122):**
- Smarter prompts with health log context
- Image upload with GPT-4 Vision
- Keyboard handling fixes

**Real Device Fixes (PRs #109-#113):**
- Gray blob shadows fixed
- White text issues fixed
- Forced Light Mode
- Global `.buttonStyle(.plain)`

**Guest Auth (PRs #114-#118):**
- Continue as Guest option
- Allows testing without Apple Sign In

**Build Fixes (PRs #96-#100, #128):**
- Duplicate struct renames
- Property name fixes (selectedDog -> currentDog)
- Optional chaining fixes

---

## Contact

The user (Vac) is responsive and can provide screenshots of issues or clarify requirements. They test on an iPhone 16 Pro.

---

*Last updated: After PR #128 merge*
