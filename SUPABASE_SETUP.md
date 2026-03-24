# ProConnect Supabase Integration

ProConnect can use **Supabase** as the backend (Auth, Database) instead of the Node.js API. This guide covers setup and usage.

## Overview

When Supabase is configured, the app uses:
- **Supabase Auth** for login/register
- **Supabase Database** for providers, bookings, reviews, categories
- **Profiles table** for user metadata (name, role, location, etc.)

When Supabase is *not* configured, the app falls back to the **Node.js backend API**.

---

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Create a new project
3. Wait for the project to be provisioned
4. Go to **Settings → API** and copy:
   - **Project URL**
   - **anon public** key

---

## 2. Run Database Migrations

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Create a new query and paste the contents of:
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_add_profile_email.sql` (if adding email column)
4. Run each migration

---

## 3. Configure the Flutter App

Pass your Supabase credentials when running the app:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

**Windows PowerShell:**
```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

**Alternative:** Edit `lib/utils/constants.dart` and set default values:
```dart
static String get supabaseUrl {
  const url = String.fromEnvironment('SUPABASE_URL', 
    defaultValue: 'https://YOUR_PROJECT.supabase.co');
  return url;
}
static String get supabaseAnonKey {
  const key = String.fromEnvironment('SUPABASE_ANON_KEY', 
    defaultValue: 'your-anon-key');
  return key;
}
```
*(Avoid committing real keys to git.)*

---

## 4. Disable Email Confirmation (Optional)

For easier local testing, you can disable email confirmation:

1. Supabase Dashboard → **Authentication** → **Providers** → **Email**
2. Turn off **Confirm email**

---

## 5. Row Level Security (RLS)

The migrations enable RLS. Policies allow:
- **Profiles**: Users read/update own profile
- **Categories**: Public read
- **Service providers**: Public read; providers manage own profile
- **Bookings**: Customers and providers see only their bookings
- **Reviews**: Public read; customers create reviews

---

## Admin Features

The **Admin dashboard** (`/admin-home`) currently uses the legacy Node.js API. When using Supabase-only:

- Admin login works (via Supabase Auth + profiles with `role='admin'`)
- Admin dashboard stats and verification require the Node.js backend running, OR
- You can implement admin features using Supabase Edge Functions / RPC

---

## Migrating Existing Data

To migrate data from the Node.js JSON files to Supabase:

1. Export users, providers, bookings, reviews, categories from your backend
2. Transform to match the Supabase schema (snake_case, UUIDs)
3. Use Supabase Dashboard → **Table Editor** to import, or write a script using the Supabase client

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Profile not found" after signup | Ensure the `handle_new_user` trigger ran. Check **Database** → **Triggers**. |
| RLS blocks my query | Verify you're authenticated and the policy allows your operation. |
| Categories empty | Run the seed data in `001_initial_schema.sql` or add categories manually. |

---

## Files Changed

- `lib/main.dart` – Supabase init
- `lib/services/auth_service_supabase.dart` – Auth with Supabase
- `lib/services/supabase_service.dart` – Supabase client
- `lib/services/provider_service.dart` – Supabase support
- `lib/services/booking_service.dart` – Supabase support
- `lib/services/review_service.dart` – Supabase support
- `lib/utils/constants.dart` – Supabase URL/key
- `lib/utils/supabase_mapper.dart` – snake_case ↔ camelCase
- `pubspec.yaml` – `supabase_flutter` dependency
