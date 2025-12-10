# TriQRide

A Flutter-based mobile application for managing and monitoring tricycle operations in Candelaria, with QR code scanning, driver ratings, and real-time notifications.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [API Integration](#api-integration)
- [Firebase Setup](#firebase-setup)

## Overview

TriQRide is a comprehensive tricycle management system designed for Candelaria municipality. The application allows users to:

- Scan QR codes on tricycles to view driver information
- Rate drivers and submit incident reports
- View fare matrices for different routes
- Receive real-time notifications about driver attendance and reports
- Access emergency contacts quickly

## Features

### QR Code Scanner

- Real-time QR code scanning for driver verification
- Display comprehensive driver information including:
  - Franchise owner name
  - Plate number
  - Barangay
  - Overall rating and rating count
  - Number of violations

### Rating & Reporting System

- 5-star rating system for drivers
- Incident reporting with detailed descriptions
- 3-hour cooldown period between reports for the same driver
- Automatic violation tracking

### Fare Price List

- Comprehensive fare matrix display
- Zoomable images for better readability
- Multiple route information
- Updated as of January 2024

### Real-Time Notifications

- Firebase Cloud Messaging integration
- Attendance/absence notifications
- Report submission confirmations
- Grouped notifications by date
- Pull-to-refresh functionality
- Clear all notifications feature

## 🛠 Tech Stack

### Frontend (Mobile App)

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider
- **QR Code Scanner**: qr_code_scanner package
- **Local Storage**: shared_preferences

### Backend

- **Framework**: Express.js (Node.js)
- **API Base URL**: `https://triqride.onrender.com/api`

### Firebase Services

- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Local Notifications**: flutter_local_notifications

### Additional Libraries

- `http` - HTTP requests
- `firebase_auth` - User authentication
- `cloud_firestore` - Cloud database
- `firebase_messaging` - Push notifications
- `flutter_local_notifications` - Local notification display

## Prerequisites

Before you begin, ensure you have the following installed:

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Node.js and npm (for backend)
- Firebase account and project setup
- A code editor (VS Code recommended)

### System Requirements

- **Android**: minSdkVersion 21 or higher
- **iOS**: iOS 12.0 or higher

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/triqride.git
cd triqride
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Backend Setup

If you're running the backend locally:

```bash
cd backend
npm install
npm start
```

The backend will start on `http://localhost:3000` (update API endpoints accordingly).

### 4. Configure Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and/or iOS apps to your Firebase project
3. Download configuration files:

   - **Android**: `google-services.json` → Place in `android/app/`
   - **iOS**: `GoogleService-Info.plist` → Place in `ios/Runner/`

4. Enable Firebase services:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Cloud Messaging

### 5. Update API Endpoints

Update the API base URL in `lib/utils/constants.dart`:

```dart
class AppConstants {
  static const String apiBaseUrl = 'https://your-backend-url.com/api';
  // ... other constants
}
```

## Configuration

### Android Configuration

1. **Update `android/app/build.gradle`**:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.1.0'
}
```

2. **Add permissions in `AndroidManifest.xml`**:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### iOS Configuration

1. **Update `Info.plist`**:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera permission is required for QR code scanning</string>
```

2. **Enable Push Notifications** in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Select Runner → Signing & Capabilities
   - Add Push Notifications capability

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── components/
│   ├── Fare_list_page.dart            # Fare matrix display
│   ├── Notification_page.dart         # Notification list with FCM
│   └── Qr_scanner.dart                # QR scanner implementation
├── controllers/
│   ├── auth_service.dart              # Authentication logic
│   ├── crud_service.dart              # CRUD operations
│   ├── notification_provider.dart     # Notification state management
│   ├── qr_provider.dart               # QR scanner state management
│   └── store_service.dart             # Local storage service
├── login/
│   ├── frpass.dart                    # Forgot password screen
│   ├── homepage.dart                  # Main navigation/home page
│   ├── Login.dart                     # Login screen
│   └── Sign_up.dart                   # Sign up screen
├── widgets/
│   ├── firebase_options.dart          # Firebase configuration
│   └── main.dart                      # Alternative entry point

assets/
├── images/
│   ├── municipalhall.jpg              # Background image
│   ├── placeholder.jpg                # Driver placeholder
│   └── farematrix*.jpg                # Fare matrix images (1-12)
```

## API Integration

### Base URL

```
https://triqride.onrender.com/api
```

### Endpoints

#### Get Driver Information

```http
GET /list/:id
```

**Response:**

```json
{
  "id": "123",
  "Driver_name": "Juan Dela Cruz",
  "Plate_number": "1092",
  "Barangay": "Poblacion",
  "Image": "https://...",
  "overallRating": "4.5",
  "totalViolations": "2",
  "ratingCount": "150"
}
```

#### Submit Report

```http
POST /report/:driverId
```

**Request Body:**

```json
{
  "plate": "1092",
  "driver": "Juan Dela Cruz",
  "brgy": "Poblacion",
  "report": "Incident description",
  "fcm_token": "device_fcm_token",
  "ratings": "4",
  "reporter_name": "Maria Santos"
}
```

## Firebase Setup

### 1. Firestore Database Structure

```
users/
  └── {userId}/
      ├── full_name: string
      ├── email: string
      └── created_at: timestamp

notifications/
  └── {notificationId}/
      ├── title: string
      ├── body: string
      ├── serverDate: string
      ├── serverTime: string
      ├── data: map
      └── timestamp: timestamp
```

### 2. Firebase Cloud Messaging

**Server Key Configuration:**

- Get your Server Key from Firebase Console → Project Settings → Cloud Messaging
- Configure in your Express.js backend for sending notifications

### 3. Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /notifications/{notificationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Usage

### Running the App

```bash
# Run on connected device/emulator
flutter run

# Run in release mode
flutter run --release

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Testing QR Code Scanner

1. Launch the app
2. Navigate to the QR Scanner tab (middle icon)
3. Point camera at a valid QR code with format:
   ```
   https://triqride.onrender.com/driver?id=123
   ```
4. View driver information
5. Submit rating or report if needed

### Submitting a Report

1. Scan driver's QR code
2. Tap "Leave a Report" button
3. Enter incident description (optional)
4. Rate the driver (1-5 stars)
5. Tap "Submit"
6. Wait 3 hours before submitting another report for the same driver

### Viewing Notifications

1. Navigate to Notifications tab
2. Pull down to refresh
3. Tap "Clear All" to remove all notifications
4. Notifications are grouped by date
