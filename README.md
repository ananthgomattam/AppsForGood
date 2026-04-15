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

git clone https://github.com/ananthgomattam/AppsForGood.git

flutter pub get

flutter run

## Installation Guide

1. Install Flutter:  
https://docs.flutter.dev/get-started/install  

2. Check installation:
flutter doctor

## Offline Model Lab (No UI, No App DB Impact)

Use the standalone model test runner to validate trigger detection and prediction scoring outside the app UI.

Run built-in consistency checks:

dart run tool/model_lab.dart --self-check

Run prediction on built-in fixed dataset:

dart run tool/model_lab.dart --dataset fixed --date 2023-01-22

Run prediction on custom CSV sample:

dart run tool/model_lab.dart --csv tool/sample_model_input.csv --date 2023-02-03

Prove that input trends affect output (example: sleep trend):

dart run tool/model_lab.dart --csv tool/sample_model_input.csv --date 2023-02-03 --sensitivity sleep

CSV columns required:

date,sleepHours,sleepQuality,sleepInterruptions,stressLevel,dietQuality,medicationAdherence,drugUse,hormonalChanges,seizureCount

Optional columns:

temperature,pressure,humidity
