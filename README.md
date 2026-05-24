GeoFlow Mobile 
A Flutter mobile application for smart field reporting and water leak monitoring. GeoFlow empowers citizens to report water leaks in real time using AI-powered image detection and GPS location tagging.

Features

- Camera-based Leak Reporting — Take a photo of a suspected leak and submit it directly from the app
- AI Detection — Images are analyzed by a machine learning model to verify if a leak is present before submission
- GPS Location Tagging — Automatically captures and attaches your current location to every report
- Push Notifications — Receive real-time updates when your report status changes (submitted, under review, verified, resolved)
- User Profile — Manage your account, avatar, and personal information
- My Reports — View and track all your submitted reports and their statuses
- Secure Authentication — Token-based login and registration via Laravel Sanctum


Tech Stack
LayerTechnologyMobile FrameworkFlutter (Dart)Backend APILaravel (PHP)ML DetectionPython (Flask)AuthenticationLaravel SanctumLocationGeolocator + GeocodingHTTP Clienthttp (Dart package)Image Pickerimage_picker

Getting Started
Prerequisites

Flutter SDK >=3.0.0
Dart SDK >=3.0.0
Android Studio or VS Code with Flutter extension
A physical device or emulator

Installation

Clone the repository

bash   git clone https://github.com/your-org/mygeoflow.git
   cd mygeoflow

Install dependencies

bash   flutter pub get

Run the app

bash   flutter run

Build release APK

bash   flutter build apk --release

Build release App Bundle (for Play Store)

bash   flutter build appbundle --release

Project Structure
lib/
├── main.dart                  # App entry point and route definitions
├── screens/
│   ├── login_screen.dart      # Login page
│   ├── register_screen.dart   # Registration page
│   ├── home_screen.dart       # Home / welcome screen
│   ├── camera_screen.dart     # Camera capture screen
│   ├── manage_leaks_screen.dart  # Submit report + My Reports tabs
│   ├── notifications_screen.dart # Notification list
│   ├── profile_screen.dart    # Edit profile
│   ├── settings_screen.dart   # App settings
│   └── help_support_screen.dart  # Help & support
├── widgets/
│   └── bottom_nav_bar.dart    # Main navigation scaffold
└── services/
    └── api_service.dart       # API base URL and token management

API
The app connects to the GeoFlow backend at:
https://geoflow.duckdns.org/api
Key endpoints used:
MethodEndpointDescriptionPOST/loginUser loginPOST/registerUser registrationGET/userGet current user profilePOST/reportsSubmit a leak reportGET/my-reportsGet user's reportsDELETE/my-reports/{id}Delete a reportGET/notificationsGet notificationsPOST/notifications/{id}/mark-readMark one as readPOST/notifications/mark-all-readMark all as read

Permissions
The app requires the following Android permissions:
xml<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

Screenshots

Add screenshots here once available


Contributing

Fork the repository
Create your feature branch (git checkout -b feature/your-feature)
Commit your changes (git commit -m 'Add your feature')
Push to the branch (git push origin feature/your-feature)
Open a Pull Request


License
This project is developed for GeoFlow — Smart Field Reporting System.
All rights reserved © 2025 GeoFlow Team.
