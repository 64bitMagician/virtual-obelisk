# art_platform

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase notes

### Security Rules

The Firestore and Storage Security Rules live in this repository:

- `firestore.rules` (and `firestore.indexes.json`)
- `storage.rules`

Edit them here, then deploy with:

```
firebase deploy --only firestore:rules,storage
```

### Storage bucket

The app does **not** use the project's default Storage bucket. The original default bucket was deleted
when the data was moved to a new region, and all files now live in the bucket **`art-platform-878d0`**.

Because of this:

- `firebase.json` uses the Storage deploy target `main`, and `.firebaserc` maps `main` to the bucket
  `art-platform-878d0`, so rules deploy to the right bucket. (Set up with
  `firebase target:apply storage main art-platform-878d0`.)
  `firebase init storage` will not work for this project, and is not needed.
- `lib/firebase_options.dart` uses `storageBucket: 'art-platform-878d0'`.
  **If you ever re-run `flutterfire configure`, it will overwrite this with the old default bucket name, and
  uploads/downloads will break.** Change `storageBucket` back to `'art-platform-878d0'` for every platform afterwards.
- Do not click "Get started" in the Storage section of the Firebase Console. It would create a new, empty default bucket.

### Testing with the Firebase Emulators

The Security Rules can be tested locally, without touching the real data, using the Firebase Emulator Suite
(Authentication, Firestore and Storage, ports configured in `firebase.json`). Java is required.

```
firebase emulators:start
flutter run -d chrome --dart-define=USE_EMULATORS=true
```

With `USE_EMULATORS=true` the app connects to the emulators instead of the real Firebase project
(see `_connectToFirebaseEmulators()` in `lib/main.dart`). Without it, the app uses the real project as usual.
The emulator database starts empty. The Emulator UI at http://localhost:4000 shows the data and every
allowed/denied request.
