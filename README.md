# Wedding India App

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.6+-02569B?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Android%20%7C%20iOS-000000?style=for-the-badge" alt="Platform" />
  <img src="https://img.shields.io/badge/PHP%20API-Backend-4B5563?style=for-the-badge" alt="Backend" />
  <img src="https://img.shields.io/badge/Firebase-Enabled-FFCA28?style=for-the-badge&logo=firebase" alt="Firebase" />
</div>

A modern matrimonial Flutter application for discovering matches, managing profiles, chatting, calling, payments, and personalized engagement features.

## Overview

Wedding India App is a matchmaking platform that helps users:

- create and manage their profile
- explore compatible matches
- filter by city, religion, education, and preferences
- view profile details and media galleries
- connect through chat, WhatsApp, and calls
- access premium plans and payment flows
- use admin-driven app content and API logic

## Features

- User authentication and registration
- Profile onboarding and updates
- Match recommendation flow
- Location and preference settings
- WhatsApp and call integration
- Video and voice calling support
- Payment and upgrade plans
- Admin API integration
- Responsive Flutter UI for mobile devices

## Tech Stack

- Flutter + Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Messaging
- Agora RTC
- Cashfree Payment Gateway
- PHP REST API backend
- SharedPreferences and local storage

## Project Structure

```text
wedding-india-app/
├── android/
├── ios/
├── lib/
├── lib33/
├── api/
├── asset/
├── test/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── .gitignore
└── LICENSE
```

## Prerequisites

Before running the project, make sure you have:

- Flutter SDK installed
- Android Studio or VS Code
- Xcode for iOS build on macOS
- Firebase project configured
- PHP backend server running

## Getting Started

```bash
git clone https://github.com/techeorankit/weddingindia_app.git
cd weddingindia_app
flutter pub get
flutter run
```

## iOS / macOS Build

For building on a Mac:

```bash
flutter clean
flutter pub get
flutter build ios --release
```

Then open the Xcode project and complete signing, provisioning, and Apple Developer setup.

## Firebase Setup

1. Create a Firebase project.
2. Add Android and iOS apps.
3. Download the configuration files.
4. Add the files to the correct Android/iOS project folders.
5. Enable Authentication, Firestore, and messaging features.

## API Setup

This app uses a PHP-based backend under the `api/` folder. Configure the base URLs and backend environment before production use.

## GitHub Repository

- https://github.com/techeorankit/weddingindia_app

## License

This project is intended for development and deployment use. Please verify ownership, licensing, and production requirements before public release.
