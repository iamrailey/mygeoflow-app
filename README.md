GeoFlow Mobile 

Smart Field Reporting & Water Leak Monitoring


📖 Table of Contents

About
Features
Tech Stack
Getting Started
Project Structure
API Endpoints
Permissions
Contributing
License


About
GeoFlow Mobile is a Flutter application that empowers citizens to report water leaks in real time. Reports are verified by an AI model before submission, and users receive live status updates through push notifications.

Features

- Camera-based Leak Reporting — Take a photo and submit directly from the app
- AI Detection — ML model verifies if the image is an actual leak before submission
- GPS Location Tagging — Automatically attaches your current location to every report
- Notifications — Real-time updates when your report status changes
- User Profile — Manage your account, avatar, and personal info
- My Reports — View and track all submitted reports and their statuses
- Secure Authentication — Token-based login via Laravel Sanctum


🛠 Tech Stack
LayerTechnologyMobile FrameworkFlutter (Dart)Backend APILaravel (PHP)ML DetectionPython (Flask)AuthenticationLaravel SanctumLocationGeolocator + GeocodingHTTP Clienthttp (Dart package)Image Pickerimage_picker

🚀 Getting Started
Prerequisites

Flutter SDK >=3.0.0
Dart SDK >=3.0.0
Android Studio or VS Code with Flutter extension
A physical device or emulator

Installation
1. Clone the repository
bashgit clone https://github.com/your-org/mygeoflow.git
cd mygeoflow
2. Install dependencies
bashflutter pub get
3. Run the app
bashflutter run
4. Build release APK
bashflutter build apk --release
5. Build release App Bundle (for Play Store)
bashflutter build appbundle --release

📁 Project Structure
lib/
├── main.dart                     # App entry point and route definitions
├── screens/
│   ├── login_screen.dart         # Login page
│   ├── register_screen.dart      # Registration page
│   ├── home_screen.dart          # Home / welcome screen
│   ├── camera_screen.dart        # Camera capture screen
│   ├── manage_leaks_screen.dart  # Submit report + My Reports tabs
│   ├── notifications_screen.dart # Notification list
│   ├── profile_screen.dart       # Edit profile
│   ├── settings_screen.dart      # App settings
│   └── help_support_screen.dart  # Help & support
├── widgets/
│   └── bottom_nav_bar.dart       # Main navigation scaffold
└── services/
    └── api_service.dart          # API base URL and token management

🌐 API Endpoints
Base URL: https://geoflow.duckdns.org/api
MethodEndpointDescriptionPOST/loginUser loginPOST/registerUser registrationGET/userGet current user profilePOST/reportsSubmit a leak reportGET/my-reportsGet user's reportsDELETE/my-reports/{id}Delete a reportGET/notificationsGet notificationsPOST/notifications/{id}/mark-readMark one as readPOST/notifications/mark-all-readMark all as read

🔒 Permissions
xml<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

🤝 Contributing

Fork the repository
Create your feature branch (git checkout -b feature/your-feature)
Commit your changes (git commit -m 'Add your feature')
Push to the branch (git push origin feature/your-feature)
Open a Pull Request


📄 License
This project is developed for GeoFlow — Smart Field Reporting System.
All rights reserved © 2025 GeoFlow Team.
