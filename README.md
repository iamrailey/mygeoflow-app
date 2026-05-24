# GeoFlow Mobile 📱
A Flutter mobile application for smart field reporting and water leak monitoring.
 
## Features
- Camera-based leak reporting with AI image verification before submission
- GPS location tagging automatically attached to every report
- Real-time notifications when report status changes (submitted, under review, verified, resolved)
- User profile management with avatar upload support
- My Reports dashboard to track all submitted reports and their statuses
- Secure token-based authentication via Laravel Sanctum
## Project Structure
- `lib/screens/` - All app screens (login, home, camera, manage leaks, notifications, profile, settings)
- `lib/widgets/` - Reusable widgets including the bottom navigation bar
- `lib/services/` - API service for base URL and token management
- `android/` - Android-specific configuration and manifest
- `assets/` - App logo and static assets
## Requirements
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio or VS Code with Flutter extension
- A physical device or Android emulator
- Active internet connection (connects to live backend)
## Setup
 
### 1. Clone the repository
```bash
git clone https://github.com/your-org/mygeoflow.git
cd mygeoflow
```
 
### 2. Install dependencies
```bash
flutter pub get
```
 
### 3. Run the app
```bash
flutter run
```
 
### 4. Build release APK
```bash
flutter build apk --release
```
 
### 5. Build App Bundle for Play Store
```bash
flutter build appbundle --release
```
 
## API Endpoints
 
The app connects to `https://geoflow.duckdns.org/api`
 
- `POST /login` - User login
- `POST /register` - User registration
- `GET /user` - Get current user profile
- `POST /user/update` - Update profile and avatar
- `POST /reports` - Submit a leak report
- `GET /my-reports` - Get user's submitted reports
- `DELETE /my-reports/:id` - Delete a report
- `GET /notifications` - Get all notifications
- `POST /notifications/:id/mark-read` - Mark one notification as read
- `POST /notifications/mark-all-read` - Mark all notifications as read
## Permissions
 
The app requires the following Android permissions:
 
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```
 
## Notes
- Location is fetched automatically on the report submission screen. Tap the refresh icon if GPS takes too long.
- The AI model rejects images that are not recognized as water leaks before they reach the backend.
- Installing the APK outside the Play Store may trigger a Google Play Protect warning — this is a false positive due to sideloading. Tap "Install anyway" to proceed.
 
