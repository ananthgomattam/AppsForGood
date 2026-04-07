# AppsForGood (ForSeizure)

## Overview
This project is a Flutter app that tracks user data and predicts a safety score based on patterns.  
It is designed to help detect potential seizure risk using daily logs and external data like weather.

## Features
- Stores daily logs
- Calculates a safety score (0.0 to 1.0)
- Uses location + weather data
- Saves data locally using a database
- Triggers warnings if risk is high

## Requirements (Dependencies)

### Software Needed

- Flutter SDK
- Dart SDK (version 3.11 or higher)
- Android Studio or VS Code
- Android Emulator or physical device

### Flutter Packages Used
These are required and listed in `pubspec.yaml`:

- `flutter` (main framework)
- `sqflite` → local database (SQLite)
- `path` → helps locate database files
- `geolocator` → gets user location
- `http` → makes API requests (weather)
- `shared_preferences` → stores small data (like settings)
- `intl` → date formatting
- `crypto` → password hashing
- `cupertino_icons` → UI icons

### Dev Dependencies
- `flutter_test`
- `flutter_lints`
