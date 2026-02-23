# BytePlus - Smart Canteen System 🍔

[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red)](LICENSE)

A comprehensive Flutter-based mobile application designed to digitize and streamline canteen operations in educational or corporate campuses. BytePlus connects students, merchants, and administrators in a unified, real-time ordering ecosystem.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Firebase Setup](#firebase-setup)
- [Running the App](#running-the-app)
- [Project Structure](#project-structure)
- [User Roles](#user-roles)
- [Key Functionalities](#key-functionalities)
- [Security Features](#security-features)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## 🎯 Overview

BytePlus is a production-ready, enterprise-grade solution that transforms traditional canteen operations into a modern, efficient, and user-friendly digital experience. The platform handles the complete order lifecycle from browsing to fulfillment, with robust admin controls, real-time updates, location-based security, and thermal printer integration.

### Why BytePlus?

- **🚀 Real-time Operations**: Live order updates using Firestore streams
- **📱 Multi-Platform**: Supports Android, iOS, Web, Windows, macOS, and Linux
- **🔔 Push Notifications**: Firebase Cloud Messaging for instant updates
- **📍 Geofencing**: Location-based access control for campus security
- **🖨️ Printer Integration**: Bluetooth thermal printer support (ESC/POS)
- **📊 Analytics Dashboard**: Comprehensive sales and performance metrics
- **🌓 Dark Mode**: Full light/dark theme support
- **👥 Role-Based Access**: Student, Merchant, and Admin roles with distinct interfaces

---

## ✨ Features

### For Students 👨‍🎓

- **Browse & Search**: Discover stores and products with real-time availability
- **Smart Cart**: Multi-store cart with per-store checkout
- **Customization**: Size, sugar level, ice level, toppings, and special notes
- **Order Tracking**: Real-time status updates with queue numbers (A01, B02, etc.)
- **Favorites**: Save frequently ordered items for quick reordering
- **Push Notifications**: Get notified when orders are ready
- **Order History**: View past orders with detailed breakdowns
- **Pickup Scheduling**: Order now or schedule for later

### For Merchants 🏪

- **Order Management**: Real-time incoming orders with queue management
- **Menu Management**: Add/edit products with images, prices, and variations
- **Analytics Dashboard**: Sales trends, revenue reports, and product performance
- **Thermal Printing**: Auto-print receipts to Bluetooth ESC/POS printers
- **Inventory Tracking**: Monitor stock levels and availability
- **Store Profile**: Manage operating hours, logo, and store information
- **Order Reports**: Export detailed transaction history
- **Customer Insights**: Track customer patterns and popular items

### For Administrators 🛡️

- **Dashboard Overview**: System-wide statistics and metrics
- **User Management**: Approve registrations, manage roles and access
- **Store Management**: Add, edit, activate/deactivate stores
- **Geofence Configuration**: Set campus boundaries with interactive map
- **Registration Approval**: Review and approve student/merchant accounts
- **Order Oversight**: Monitor all system orders
- **Security Controls**: Location-based access and role management

---

## 🛠 Technology Stack

### Frontend

- **Flutter 3.7.0+** - Cross-platform UI framework
- **Dart SDK ^3.7.0** - Programming language
- **Provider** - State management
- **Iconsax Flutter** - Modern icon library

### Backend

- **Firebase Core** - Backend infrastructure
- **Cloud Firestore** - NoSQL real-time database
- **Firebase Authentication** - User authentication
- **Cloud Functions** - Serverless backend logic
- **Firebase Cloud Messaging** - Push notifications

### Key Packages

- **geolocator** (11.0.0) - GPS location services
- **flutter_blue_plus** (1.32.0) - Bluetooth connectivity for printers
- **flutter_local_notifications** (18.0.1) - Local notification handling
- **flutter_map** (6.1.0) - Interactive map for geofencing
- **lottie** (3.3.2) - Animations
- **cached_network_image** (3.4.1) - Image caching
- **intl** (0.18.0) - Internationalization and formatting

---

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.7.0 or higher)

   ```bash
   flutter --version
   ```

2. **Dart SDK** (^3.7.0)
   - Comes bundled with Flutter

3. **Android Studio** or **Xcode** (for mobile development)
   - Android Studio for Android builds
   - Xcode for iOS builds (macOS only)

4. **Firebase CLI**

   ```bash
   npm install -g firebase-tools
   ```

5. **Git**

   ```bash
   git --version
   ```

6. **An IDE**
   - VS Code (recommended)
   - Android Studio
   - IntelliJ IDEA

---

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/byte_plus.git
cd byte_plus/byte_plus_main
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Check Flutter Setup

```bash
flutter doctor
```

Resolve any issues reported by `flutter doctor` before proceeding.

---

## 🔥 Firebase Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enable Google Analytics (recommended)

### 2. Configure Firebase Options

**Using FlutterFire CLI (Recommended):**

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure --project=your-project-id
```

This will automatically generate `lib/firebase_options.dart`.

**Manual Configuration:**

1. Copy the template file:

   ```bash
   cp firebase_options.dart.template lib/firebase_options.dart
   ```

2. Get your Firebase config from Firebase Console → Project Settings → General

3. Fill in the values in `lib/firebase_options.dart`

4. **IMPORTANT**: Verify `lib/firebase_options.dart` is in `.gitignore`

### 3. Register Your Apps

**For Android:**

```bash
flutterfire configure --project=your-project-id
```

**Manual Setup:**

- Download `google-services.json` from Firebase Console
- Place it in `android/app/`
- **IMPORTANT**: Verify it's in `.gitignore` (already configured)
- A template is provided at `google-services.json.template` for reference

**For iOS:**

- Download `GoogleService-Info.plist` from Firebase Console
- Add it to `ios/Runner/`
- **IMPORTANT**: Verify it's in `.gitignore` (already configured)

**For Web:**

- Copy the Firebase config to `web/index.html`

### 4. Enable Firebase Services

In the Firebase Console, enable:

- **Authentication** → Email/Password
- **Firestore Database** → Create database (start in production mode)
- **Cloud Functions** → Upgrade to Blaze plan (required)
- **Cloud Messaging** → Enable for push notifications
- **Storage** → Enable for image uploads (optional)

### 5. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### 6. Deploy Firestore Indexes

```bash
firebase deploy --only firestore:indexes
```

### 7. Deploy Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### 8. Configure Geofence (Optional)

1. Navigate to Admin Panel in the app
2. Go to Geofence Settings
3. Set campus coordinates and radius
4. Enable geofencing

---

## ▶️ Running the App

### Development Mode

**Android:**

```bash
flutter run
```

**iOS:**

```bash
flutter run -d ios
```

**Web:**

```bash
flutter run -d chrome
```

**Windows:**

```bash
flutter run -d windows
```

### Release Build

**Android APK:**

```bash
flutter build apk --release
```

**Android App Bundle (for Play Store):**

```bash
flutter build appbundle --release
```

**iOS:**

```bash
flutter build ios --release
```

**Web:**

```bash
flutter build web --release
```

---

## 📁 Project Structure

```
byte_plus_main/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase configuration
│   ├── models/                      # Data models
│   │   └── cart_item_model.dart
│   ├── pages/                       # UI screens
│   │   ├── splash_page.dart         # Splash screen
│   │   ├── login_page.dart          # Login screen
│   │   ├── register_page.dart       # Registration
│   │   ├── user_shell.dart          # Student main interface
│   │   ├── merchant_shell.dart      # Merchant main interface
│   │   ├── admin_shell.dart         # Admin main interface
│   │   ├── store_page.dart          # Store browsing
│   │   ├── product_page.dart        # Product listing
│   │   ├── cart_page.dart           # Shopping cart
│   │   ├── order_page.dart          # Order tracking
│   │   ├── merchant_orders_page.dart # Merchant order management
│   │   ├── analytics_page.dart      # Sales analytics
│   │   ├── manage_menu_page.dart    # Menu management
│   │   └── admin/                   # Admin pages
│   │       ├── admin_dashboard_page.dart
│   │       ├── admin_users_page.dart
│   │       ├── admin_stores_page.dart
│   │       ├── admin_registration_requests_page.dart
│   │       └── admin_geofence_settings_page.dart
│   ├── services/                    # Business logic
│   │   ├── order_service.dart       # Order operations
│   │   ├── cart_service.dart        # Cart management
│   │   ├── notification_service.dart # Push notifications
│   │   ├── location_service.dart    # GPS services
│   │   ├── location_guard.dart      # Geofencing
│   │   ├── thermal_printer_service.dart # Bluetooth printing
│   │   ├── analytics_service.dart   # Analytics calculations
│   │   ├── firestore_service.dart   # Database operations
│   │   └── theme_service.dart       # Theme management
│   ├── theme/
│   │   └── app_theme.dart           # App styling
│   ├── utils/
│   │   └── responsive_utils.dart    # Responsive helpers
│   └── widgets/                     # Reusable components
│       ├── app_modal_dialog.dart
│       ├── pickup_time_picker.dart
│       └── widgets.dart
├── android/                         # Android-specific files
├── ios/                            # iOS-specific files
├── web/                            # Web-specific files
├── assets/                         # Images, fonts, animations
│   ├── images/
│   ├── animation/
│   └── stores/
├── functions/                      # Cloud Functions
│   ├── index.js
│   └── package.json
├── pubspec.yaml                    # Dependencies
├── firebase.json                   # Firebase configuration
├── firestore.rules                 # Security rules
├── firestore.indexes.json          # Database indexes
└── README.md                       # This file
```

---

## 👥 User Roles

### Student

- **Default role** for most users
- Can browse stores, order food, track deliveries
- Subject to geofencing restrictions
- Requires admin approval for registration

### Staff (Merchant)

- Manages one or more stores
- Processes incoming orders
- Updates menu and inventory
- Views analytics and reports
- Exempt from geofencing

### Admin

- Full system access
- Manages users, stores, and configurations
- Approves registrations
- Configures geofencing
- Exempt from geofencing
- System oversight

---

## 🔑 Key Functionalities

### Queue Number System

- Alphanumeric format: A01, A02...A99, B01...Z99, AA01...
- Transaction-safe generation using Firestore
- Displayed on orders, receipts, and pickup screens

### Order Workflow

1. **Student**: Adds items to cart → Checkout → Place order
2. **System**: Generates queue number → Sends notification to merchant
3. **Merchant**: Receives order → Accepts → Marks in-progress → Marks ready
4. **Student**: Gets notification → Picks up order
5. **Merchant**: Marks completed

### Geofencing System

- Real-time GPS tracking every 15 seconds
- Configurable radius around campus center
- Visual feedback when outside boundary
- Auto-disables ordering outside geofence
- Admin/staff bypass restrictions

### Notification Flow

```
Action → Firestore Document → Cloud Function → FCM → User Device
```

### Thermal Printing

- Bluetooth discovery and pairing
- ESC/POS command support
- Auto-print on new orders (configurable)
- Receipt includes: store info, queue number, items, customizations, totals

---

## 🔒 Security Features

### Authentication

- Firebase Authentication with email/password
- Role-based access control (RBAC)
- Session management and auto-logout

### Data Security

- Firestore security rules enforce role-based access
- All network requests over HTTPS
- Token-based authentication for API calls

### Location Security

- Geofencing prevents unauthorized access
- GPS permission verification
- Real-time location monitoring

### Admin Controls

- Manual approval for new accounts
- User activation/deactivation
- Order oversight and intervention
- Audit logs for critical actions

### 🔐 Protecting Sensitive Data

**⚠️ CRITICAL: Never commit these files to version control:**

- `lib/firebase_options.dart` - Firebase configuration
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config
- `functions/serviceAccountKey.json` - Service account credentials
- `.env` - Environment variables
- Any file containing API keys or credentials

**✅ Template files are provided for reference:**

- `.env.template` - Environment variables template
- `firebase_options.dart.template` - Firebase options template
- `google-services.json.template` - Google services template

**Before running the app:**

1. Copy template files and remove `.template` extension
2. Fill in your actual Firebase credentials
3. Ensure real config files are in `.gitignore`
4. Never commit files with real credentials

**📖 For detailed security guidelines, see [SECURITY.md](SECURITY.md)**

---

## 🤝 Contributing

### Development Workflow

1. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow Dart style guide
   - Add comments for complex logic
   - Update documentation as needed

3. **Test thoroughly**

   ```bash
   flutter test
   flutter analyze
   ```

4. **Commit with descriptive messages**

   ```bash
   git commit -m "feat: add order cancellation feature"
   ```

5. **Push and create a pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Keep functions small and focused
- Add documentation comments for public APIs

### Testing

- Write unit tests for services
- Test on multiple devices and screen sizes
- Verify Firebase integration in staging environment

---

## 🐛 Troubleshooting

### Common Issues

**Issue: Firebase initialization failed**

```bash
Solution: Ensure google-services.json (Android) or GoogleService-Info.plist (iOS) is properly configured
```

**Issue: Geolocation not working**

```bash
Solution: Check location permissions in AndroidManifest.xml and Info.plist
Add: <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

**Issue: Notifications not received**

```bash
Solution:
1. Verify Firebase Cloud Messaging is enabled
2. Check FCM token is being saved to Firestore
3. Deploy Cloud Functions
4. Request notification permissions on app start
```

**Issue: Bluetooth printer not connecting**

```bash
Solution:
1. Enable Bluetooth permissions in manifest
2. Pair device in system settings first
3. Use ESC/POS compatible printer
4. Check printer service logs for connection errors
```

**Issue: Build fails with dependency conflicts**

```bash
Solution:
flutter clean
flutter pub get
flutter pub upgrade
```

### Debug Tools

**Enable Flutter inspector:**

```bash
flutter run --debug
```

**View Firebase logs:**

```bash
firebase functions:log
```

**Check Firestore data:**

- Use Firebase Console → Firestore Database
- Or use the in-app Debug Firestore page

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.

Copyright © 2026 BytePlus. All rights reserved.

---

## 📞 Support

For issues, questions, or contributions:

- **Email**: support@byteplus.com
- **Documentation**: [Link to docs]
- **Issue Tracker**: [GitHub Issues]

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- All contributors and testers
- Open source community for packages and inspiration

---

**Built with ❤️ using Flutter**
