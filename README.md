# 🚀 ProConnect: Smart Local Service Marketplace

ProConnect is a premium, high-performance cross-platform application designed to bridge the gap between skilled service providers (electricians, plumbers, tutors, etc.) and customers in their local vicinity. 

Built with **Flutter** and powered by **Supabase**, ProConnect offers a seamless, real-time experience with a professional design system inspired by modern industry leaders.

---

## ✨ Key Features

### 👤 For Customers
- **Service Discovery**: High-visual category browsing and smart provider search.
- **Trusted Choices**: Detailed provider profiles with verified ratings and community reviews.
- **Smart Booking**: One-tap scheduling with date, time, and service location.
- **Real-time Status**: Live tracking of booking lifecycle (Pending → Accepted → In-Progress → Completed).
- **Native Experience**: Modern Light Mode UI with smooth micro-animations.

### 🛠️ For Service Providers
- **Professional Presence**: Native image upload for profile photos (Gallery/Camera).
- **Business Management**: Real-time dashboard for managing incoming service requests.
- **Reputation Building**: Showcase skills, experience, and earn through verified customer feedback.
- **Earnings Tracking**: Monitor productivity and completed jobs directly from the app.

### 🛡️ For Admin
- **Centralized Command**: Unified dashboard for platform health and statistics.
- **Provider Verification**: Robust system to verify and onboard skilled professionals.
- **Platform Integrity**: Manage categories, moderate reviews, and resolve disputes.

---

## 🛠 Tech Stack

### Frontend (Mobile & Web)
- **Framework**: [Flutter](https://flutter.dev/) (3.x)
- **State Management**: Provider Pattern
- **UI/UX**: Custom Premium Design System (Vanilla CSS inspired styling in Flutter)
- **Native Features**: `image_picker` for cross-platform media selection.

### Backend (BaaS)
- **Provider**: [Supabase](https://supabase.com/)
- **Database**: PostgreSQL with Row-Level Security (RLS)
- **Authentication**: Supabase Auth (Email/Password)
- **Storage**: Supabase Storage for secure, organized asset management (Avatars bucket).
- **Real-time**: Postgres CDC for live chat and booking synchronization.

---

## 📂 Project Structure

```text
proconnect/
├── frontend/               # Flutter Multi-platform Application
│   ├── lib/
│   │   ├── models/        # Type-safe Data Models
│   │   ├── providers/     # Global State Management
│   │   ├── screens/       # feature-based UI Screens
│   │   ├── services/      # Supabase & Upload Logic
│   │   └── utils/         # Theme, Constants, and Mappers
│   └── pubspec.yaml       # Flutter Dependencies
│
├── supabase/               # Backend-as-a-Code
│   ├── migrations/        # SQL Version Control (RLS & Schema)
│   └── seed/              # Development Data
│
├── admin-dashboard/        # Modern Admin Interface
│   ├── js/                # Direct Supabase Client Logic
│   └── index.html         # Premium Dashboard UI
│
└── README.md              # Project Documentation
```

---

## 🚦 Quick Start

### 1. Backend Setup (Supabase)
1. Create a free project at [supabase.com](https://supabase.com).
2. Create a public bucket named `avatars` in **Storage**.
3. Apply the migrations located in `./supabase/migrations/` using the Supabase SQL Editor.

### 2. Frontend Configuration
You can pass your Supabase credentials directly via `--dart-define` to keep your environment secure:

```bash
cd frontend
flutter run \
  --dart-define=SUPABASE_URL=https://your-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

### 3. Build & Deploy
- **Android/iOS**: Native mobile builds.
- **Web**: `flutter build web --release`.
- **Desktop**: Native Windows/macOS/Linux executables.

---

## 📈 Roadmap & Recent Progress

- [x] **Phase 1**: Legacy Migration (Node.js → Supabase)
- [x] **Phase 2**: Real-time Chat & Booking Sync
- [x] **Phase 3**: Premium UI Overhaul (Light Theme)
- [x] **Phase 4**: Native Image Upload & Storage Policies
- [x] **Phase 5**: Optimized Registration Flow with Photo Support
- [ ] **Phase 6**: Google Maps & Geolocation Distance Calculating (Coming Soon)

---

Built with ❤️ by the ProConnect Team.
