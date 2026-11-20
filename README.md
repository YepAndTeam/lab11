# Notes Vault | Laboratory Work 11

A single-screen Flutter notes app. It restores dark mode, the display name, and notes from SharedPreferences before rendering the first Flutter frame. Notes are stored as one JSON array and restored through NoteItem.fromJson.

## Run

Open the Flutter project root in Android Studio and run lib/main.dart with an Android device or Chrome selected. From the terminal, run flutter pub get, then flutter run or flutter run -d chrome --web-port 8765. Reuse the same browser profile, hostname, and port to restore web data.

## Cold restart demo

1. Save a display name and turn on Dark mode.
2. Add two notes and mark the newest one completed.
3. On Android, run adb shell am force-stop com.example.lab11 (check the application ID in android/app/build.gradle.kts), then tap Notes Vault in the launcher.
4. Verify the display name, dark theme, both notes, and the completion checkbox. Delete a note and repeat the restart to verify deletion.

## Defense

SharedPreferences is intended for simple, non-sensitive preferences and small cached data. JSON is a data format and provides no encryption. Store secrets in iOS Keychain or encrypt them using keys protected by Android Keystore.
