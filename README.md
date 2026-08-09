# AI Life Organizer — v1

A personal AI-powered life organizer built with Flutter. This is **Phase 1 + Phase 2**
of the full plan: a real, working foundation you can build on.

## What's in this build

- Real login (Firebase Authentication — email/password, forgot password)
- Home dashboard (greeting, today's tasks, today's events, upcoming reminders)
- Tasks (priority, deadline, category, complete/delete)
- Calendar (month view, add/edit events)
- Reminders (time-based, daily/weekly repeat, real Android notifications)
- Notes (search, tags)
- Goals (progress tracking)
- Habits (streaks)
- AI Assistant (chat, understands English/Hinglish, proposes actions like
  "create a reminder" which **you must confirm** before anything is saved —
  the AI never writes to your data directly)
- Simple Memory (tell the AI "remember that..." and it will use that context later;
  view/delete anytype in Settings)
- Light/dark theme, secure on-device storage for your AI key

## Not in this build yet (Phase 3+)

Money/finance tracker, analytics graphs, voice mode, location-based reminders,
encrypted document vault, universal cross-module search, AI auto-scheduling your
whole day, Google Sign-In. These are all designed for in the architecture (see
`lib/models/models.dart` and `lib/services/firestore_service.dart`) so they can be
added without rebuilding what's already here — just tell me when you're ready for
the next phase.

---

## Setup (do this once)

### Step 1: Create a Firebase project

1. Go to https://console.firebase.google.com → **Add project** → give it any name.
2. Once created, click **Add app → Android**.
3. Android package name: enter exactly `com.ailifeorganizer.ai_life_organizer`
4. Skip the SHA-1 field (not needed for this build) → Register app.
5. **Download `google-services.json`** and place it at the **root** of this project
   (same folder as `pubspec.yaml`, not inside `android/` — the build workflow moves
   it into place automatically).
6. In the Firebase console: **Build → Authentication → Get started → Email/Password → Enable**.
7. In the Firebase console: **Build → Firestore Database → Create database** (start
   in production mode — the app ships its own security rules, see Step 3).

### Step 2: Connect Firebase to the app (`firebase_options.dart`)

Open the `google-services.json` you just downloaded in any text editor, then open
`lib/firebase_options.dart` in this project and fill in the 5 placeholder values —
the comment above each line tells you exactly which field to copy from the JSON.

### Step 3: Set Firestore security rules

In Firebase console → Firestore Database → **Rules** tab, replace the contents with
everything inside `firestore.rules` (included in this project) → **Publish**.
This makes sure every user can only ever read/write their own data.

### Step 4: Get a free Gemini API key (for the AI Assistant)

1. Go to https://aistudio.google.com/apikey → **Create API key** (free tier).
2. You'll paste this **inside the app itself** after you install it (Settings →
   AI Assistant → Gemini API key) — it's stored encrypted on your phone, not in
   the code, so it's safe to skip for now and add later.

### Step 5: Push to GitHub and build the APK

1. Create a new GitHub repository and push this whole folder to it (including
   `google-services.json` at the root — everything else is already set up).
2. Go to your repo's **Actions** tab. The build should start automatically on
   push (or click **Build APK → Run workflow** to trigger it manually).
3. When it finishes (green check), open the workflow run → **Artifacts** →
   download `app-release-apk`. Unzip it to get `app-release.apk`.
4. Copy the APK to your phone and install it (you'll need to allow "install
   from unknown sources" the first time).

That's it — sign up in the app, then go to **Settings** and paste your Gemini key
to activate the AI Assistant.

---

## If the GitHub Actions build fails

This project was written carefully, but it wasn't possible to compile-test it in
the environment it was built in (no internet/Android SDK access there). If a step
fails, open the failed step in the Actions log, copy the error text, and send it
back — it's usually a one-line fix (a package version, a permission, etc.).

A few things that commonly need a small manual step on real devices:
- **Exact reminder timing**: on some Android versions you may need to manually
  allow "Alarms & reminders" for the app in Android Settings → Apps.
- **Reminders after a phone restart**: currently reminders are (re)scheduled when
  the app is opened; a full reboot-persistence receiver is a Phase 3 addition.

## Project structure

```
lib/
  models/        data models (Task, Note, Goal, Habit, Reminder, Event, Memory)
  services/      Firebase Auth, Firestore, Gemini AI, local notifications
  providers/     app-wide state (auth, theme)
  screens/       one folder per feature
  theme/         colors, typography, light/dark themes
overrides/       Android permission + Firebase Gradle setup (applied by CI)
firestore.rules  paste into Firebase Console → Firestore → Rules
```

## Requesting the next phase

When you're ready for Money Organizer, Analytics, Voice Mode, Location Reminders,
the Personal Document Vault, or Universal Search, just ask — the data layer
(`firestore_service.dart`) is already structured so each of those is an additive
module, not a rewrite.
