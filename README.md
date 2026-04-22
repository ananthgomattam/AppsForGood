# AppsForGood (ForSeizure)

## Overview
This project is a Flutter app that tracks daily data and predicts a safety score based on patterns.  
It is designed to help detect potential seizure risk using user input and external data like weather.

## Features
- Stores daily logs
- Calculates a safety score (0.0 to 1.0)
- Uses location and weather data
- Saves data locally using a database
- Triggers warnings if risk is high

## Requirements (Dependencies)
### Software Needed
- VS Code
- Flutter SDK
- Dart SDK (3.11 or higher)

### Flutter Packages Used
- flutter
- sqflite (database)
- path (file locations)
- geolocator (location)
- http (API requests)
- shared_preferences (small data storage)
- intl (date formatting)
- crypto (hashing)
- cupertino_icons (UI)
  
### Dev Dependencies
- flutter_test
- flutter_lints
  
## Commands to Run
```
git clone https://github.com/ananthgomattam/AppsForGood.git
flutter pub get
flutter run
```

## Installation Guide
1. Install Flutter:  
https://docs.flutter.dev/get-started/install  
2. Check installation:
```
flutter doctor
```
## Running on a Samsung Galaxy Tab A7

Confirm the tablet is detected:
```
flutter devices
```

Run the App
```
flutter run
```
Flutter will build and install the app directly onto the tablet.

## References
Claude Sonnet 4.6: Used for basic dart training and lessons on how to code this application
