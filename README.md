# AMSv2 - Flutter Application

A comprehensive Flutter application with full architecture setup including state management, API integration, local storage, and clean code structure.

## Project Structure

```
lib/
├── config/
│   ├── routes/
│   │   └── app_routes.dart
│   └── theme/
│       └── app_theme.dart
├── models/
│   └── user_model.dart
├── providers/
│   └── app_provider.dart
├── screens/
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── services/
│   ├── api_service.dart
│   └── storage_service.dart
├── utils/
│   ├── constants.dart
│   └── extensions.dart
├── widgets/
│   ├── custom_button.dart
│   └── custom_text_field.dart
└── main.dart
```

## Features

- **State Management**: Provider pattern for efficient state management
- **API Integration**: HTTP client with error handling
- **Local Storage**: SharedPreferences for persistent data
- **Theme Support**: Light and dark theme support
- **Navigation**: Named routes for easy navigation
- **Custom Widgets**: Reusable UI components
- **Utilities**: Extensions and constants for common operations

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio or Xcode

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Dependencies

- **provider**: State management
- **http**: HTTP client for API calls
- **shared_preferences**: Local storage
- **intl**: Internationalization
- **uuid**: Unique ID generation
- **connectivity_plus**: Network connectivity
- **logger**: Logging utility

## Usage

### Adding a New Screen

1. Create a new file in `lib/screens/[feature]/[feature]_screen.dart`
2. Add the route in `lib/config/routes/app_routes.dart`
3. Navigate using `Navigator.pushNamed(context, '/route_name')`

### Using the API Service

```dart
final apiService = ApiService();
final data = await apiService.get('/endpoint');
```

### Using Local Storage

```dart
await StorageService.setString('key', 'value');
final value = StorageService.getString('key');
```

### State Management with Provider

```dart
Consumer<AppProvider>(
  builder: (context, appProvider, _) {
    return Text(appProvider.userRole);
  },
)
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## License

This project is licensed under the MIT License.
