# Lumora Flutter App - Running Guide

## Prerequisites

Before running the Lumora app, ensure you have the following installed:

- **Flutter SDK** (version 3.7.2 or higher)
- **Dart SDK** (comes with Flutter)
- **Android Studio** with Android SDK (for Android development)
- **Visual Studio Code** (recommended IDE)
- **Git** (for cloning the repository)

### Verify Installation

Run these commands to verify your setup:

```bash
flutter doctor
```

This should show no errors. If there are issues, follow the Flutter installation guide.

## Getting Started

1. **Clone or navigate to the project**:
   ```bash
   cd path/to/lumora-project/lumora-flutter
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify Firebase configuration**:
   - Firebase is already configured for Android, iOS, Web, and Windows
   - Config files are in place: `lib/firebase_options.dart`, `android/app/google-services.json`, etc.

## Running the App

### On Android Emulator/Device

1. **Start an Android emulator** or connect a physical device
2. **Run the app**:
   ```bash
   flutter run
   ```
   Or specify Android:
   ```bash
   flutter run -d android
   ```

### On Web (Chrome)

```bash
flutter run -d chrome
```

### On Windows Desktop

```bash
flutter run -d windows
```

### On iOS (macOS only)

```bash
flutter run -d ios
```

## Troubleshooting

### Common Issues

- **"No devices found"**: Ensure emulator is running or device is connected
- **Firebase errors**: Check internet connection and Firebase project setup
- **Build failures**: Run `flutter clean` then `flutter pub get`

### Check App Status

- **Static analysis**: `flutter analyze`
- **Test build**: `flutter build apk` (Android) or `flutter build web`

## Features

Lumora is a mental health and wellness app with:
- User authentication (Email/Google/Anonymous)
- Mood tracking
- Meditation player
- Journaling
- Breathing exercises
- Gamification system
- Progress insights

## Development

- **Hot reload**: Press `r` in terminal while running
- **Hot restart**: Press `R` in terminal
- **Debug mode**: App runs in debug by default

## Support

If you encounter issues, check:
- Flutter documentation: https://flutter.dev/docs
- Firebase console for project settings
- Android Studio for emulator issues