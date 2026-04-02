# AGENTS.md - Development Guide for RimaPay

This document provides guidelines for AI agents working on the RimaPay Flutter project.

## Project Overview

RimaPay is a modern mobile wallet and bill-pay app inspired by Chipper Cash, Kuda Bank, and Opay. Built with Flutter, it uses Riverpod for state management, go_router for navigation, and follows clean architecture principles.

## Build Commands

### Running the App

```bash
# Development (default entry point)
flutter run

# Staging environment
flutter run -t lib/mainStaging.dart

# Production environment
flutter run -t lib/mainProd.dart

# Run on specific device
flutter run -d chrome
flutter run -d windows
flutter run -d <device-id>

# List available devices
flutter devices
```

### Building

```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build iOS (macOS only)
flutter build ios --release

# Build web
flutter build web --release

# Build for specific flavor
flutter build apk --debug -t lib/mainStaging.dart
```

### Testing

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run a specific test by name
flutter test --name "Counter increments"

# Run tests with verbose output
flutter test -v

# Run tests with coverage
flutter test --coverage
```

### Code Analysis & Linting

```bash
# Run static analysis
flutter analyze

# Fix auto-fixable issues
flutter analyze --fix
```

### Dependency Management

```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Run build_runner for code generation
dart run build_runner build

# Clean and rebuild
flutter clean && flutter pub get
```

## Code Style Guidelines

### Project Structure

```
lib/
├── core/                    # Shared utilities, theme, providers, services
│   ├── providers/          # Riverpod providers
│   ├── services/           # Core services (storage, biometric, etc.)
│   ├── theme/              # App theme, colors, text styles, spacing
│   ├── router/             # GoRouter configuration
│   └── localization/       # Localization
├── features/               # Feature modules (feature-driven architecture)
│   ├── auth/
│   │   ├── data/           # Data layer (repositories, data sources)
│   │   ├── domain/         # Business logic (entities, use cases)
│   │   └── presentation/  # UI layer (screens, widgets)
│   ├── home/
│   ├── bills/
│   └── ...
├── shared/                 # Shared widgets and components
├── Services/              # Legacy services (being migrated)
├── Models/                # Data models
├── Utils/                 # Utility functions
└── Constants/            # App constants and strings
```

### Naming Conventions

**Files:**
- Use snake_case: `home_screen.dart`, `auth_provider.dart`, `user_model.dart`
- Screens: `{feature}_screen.dart` or `{name}_screen.dart`
- Providers: `{name}_provider.dart`
- Widgets: `{name}_widget.dart` or `{name}.dart`

**Classes:**
- PascalCase: `class HomeScreen`, `class AuthProvider`, `class User`
- Use descriptive names: `OtpService`, `TransactionProvider`

**Variables & Methods:**
- camelCase: `userName`, `isLoading`, `getUserData()`
- Private members: `_privateVariable`, `_privateMethod()`

**Constants:**
- PascalCase for class constants: `class AppConstants`
- UPPER_SNAKE_CASE for enum values: `TierLevel.tier1`

### Imports

**Order (recommended):**
1. Dart core imports
2. Flutter/Third-party package imports
3. Project imports (relative paths)

```dart
// Dart core
import 'dart:convert';
import 'dart:async';

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Third-party
import 'package:go_router/go_router.dart';

// Project
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';
```

### Widgets & UI

- Use `const` constructors where possible
- Prefer `ConsumerStatefulWidget` when using Riverpod with state
- Extract reusable widgets into separate files
- Use trailing commas for better formatting

```dart
// Good
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Use trailing commas
Widget build(BuildContext context) {
  return Column(
    children: [
      const Text('Hello'),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () {},
        child: const Text('Click'),
      ),
    ],
  );
}
```

### State Management (Riverpod)

**Providers:**
```dart
// Simple provider
final authProvider = Provider<AuthService>((ref) => AuthService());

// StateNotifier provider
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier(ref.read(authProvider));
});

// Future provider
final userDataProvider = FutureProvider<User>((ref) async {
  return await ref.read(authProvider).getUser();
});
```

**Consumer Usage:**
```dart
// For reading providers
final user = ref.watch(userProvider);
final isLoading = ref.watch(isLoadingProvider);

// For actions
ref.read(userProvider.notifier).updateUser(newUser);
```

### Error Handling

**Service Layer:**
```dart
Future<OtpResponse> verifyOtp(OtpParams params) async {
  try {
    final response = await http.post(...);
    
    if (response.statusCode == 200) {
      // Handle success
      return OtpResponse(status: "success", model: data);
    } else {
      // Handle API error
      return OtpResponse(
        errmessage: errorMessage,
        status: "failed",
      );
    }
  } on SocketException catch (_) {
    return OtpResponse(errmessage: NETWORK_ERROR, status: "failed");
  } on TimeoutException catch (_) {
    return OtpResponse(errmessage: TIME_OUT_ERROR, status: "failed");
  } catch (e) {
    return OtpResponse(
      errmessage: AN_ERROR_OCCURED_WHILE_PROCESSING_YOUR_REQUEST_PLEASE_TRY_AGAIN,
      status: "failed",
    );
  }
}
```

**Provider Layer:**
```dart
Future<bool> login(String email, String password) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  
  try {
    // API call
    _user = await authService.login(email, password);
    await StorageService.saveUser(_user!);
    return true;
  } catch (e) {
    _error = e.toString();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

### Models & Data

**JSON Serialization:**
```dart
class User {
  final String id;
  final String email;
  
  User({required this.id, required this.email});
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
  };
  
  User copyWith({String? id, String? email}) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
    );
  }
}
```

### Theme & Styling

**Colors:** Use `AppColors` from `core/theme/app_colors.dart`
**Text Styles:** Use `AppTextStyles` from `core/theme/app_text_styles.dart`
**Spacing:** Use `AppSpacing` from `core/theme/app_spacing.dart`

```dart
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// Usage
Text(
  'Hello',
  style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
)
```

### Navigation

**GoRouter:**
```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
```

**Navigation:**
```dart
// Push
context.push('/route');

// Replace
context.go('/route');

// With parameters
context.push('/user/${user.id}');
```

### Testing Guidelines

- Place tests in `test/` directory mirroring `lib/` structure
- Use `flutter_test` package
- Follow naming: `feature_name_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Home screen displays balance', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    
    expect(find.text('Available Balance'), findsOneWidget);
  });
}
```

### Linting

The project uses `flutter_lints` with the default recommended set. Key rules:
- Avoid print statements (use `dart:developer` logging)
- Use `const` where possible
- Prefer single quotes for strings
- Sort imports alphabetically within groups

### API Patterns

**Base URL:** Configured via flavor configs (see `mainStaging.dart`, `mainProd.dart`)

**Error Responses:** Return typed response objects with status and message
```dart
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
}
```

## Common Issues & Solutions

### Build Runner Issues
If code generation fails:
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Android Build Issues
```bash
# Clean gradle cache
cd android && ./gradlew clean
```

### Web Build Issues
```bash
flutter clean
flutter pub get
flutter build web
```

## Key Dependencies

- **State Management:** `flutter_riverpod: ^2.4.9`
- **Navigation:** `go_router: ^16.2.1`
- **HTTP:** `dio: ^5.3.3`, `retrofit: ^4.0.3`
- **Storage:** `shared_preferences: ^2.2.2`, `hive: ^2.2.3`
- **UI:** `flutter_svg`, `cached_network_image`, `flutter_animate`
- **Forms:** `flutter_form_builder`, `form_builder_validators`

## Environment Entry Points

- `lib/main.dart` - Default/dev environment
- `lib/mainStaging.dart` - Staging environment
- `lib/mainProd.dart` - Production environment
