# AGENTS.md - RimaPay Development Guide

RimaPay is a Flutter mobile wallet app using Riverpod, go_router, and clean architecture.

## Build & Run Commands

```bash
# Run app
flutter run                              # dev (default)
flutter run -t lib/mainStaging.dart      # staging environment
flutter run -t lib/mainProd.dart         # production environment
flutter run -d chrome                    # specific device
flutter devices                          # list available devices

# Build
flutter build apk --debug
flutter build apk --release
flutter build web --release

# Test
flutter test                             # run all tests
flutter test test/widget_test.dart       # run single test file
flutter test --name "test name"          # run tests matching pattern
flutter test test/path/to/file_test.dart -n "specific test name"  # single test

# Lint & Analyze
flutter analyze
flutter analyze --fix

# Dependencies & Code Generation
flutter pub get
dart run build_runner build              # run code generation
dart run build_runner build --delete-conflicting-outputs  # regenerate
```

## Project Structure

```
lib/
├── core/           # theme, providers, services, router, constants
├── features/       # feature-driven modules (auth/, home/, bills/, wallet/)
├── shared/         # reusable widgets, components
├── Services/       # legacy services (migrating to features/)
├── Models/         # data models
└── Utils/         # helpers, extensions
```

## Code Style

### Naming Conventions
- Files: `snake_case.dart` (home_screen.dart, auth_provider.dart)
- Classes/Widgets: `PascalCase` (HomeScreen, AuthProvider)
- Variables/Methods: `camelCase` (userName, isLoading)
- Private members: `_privateVariable` (leading underscore)

### Imports (order matters)
1. Dart core (`dart:convert`, `dart:async`)
2. Flutter (`flutter/material.dart`)
3. Third-party packages (`go_router`, `dio`)
4. Project imports (relative paths)

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
```

### Widget Guidelines
- Use `const` constructors wherever possible
- Use `ConsumerStatefulWidget` with Riverpod for stateful features
- Use trailing commas for better formatting
- Extract reusable UI into `shared/widgets/`

```dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
```

### State Management (Riverpod)
```dart
// Provider (read-only)
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// StateNotifier (mutable state)
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) => UserNotifier());

// Usage
final user = ref.watch(userProvider);
ref.read(userProvider.notifier).updateUser(newUser);
```

### Error Handling

**Services** - return typed responses:
```dart
Future<OtpResponse> verifyOtp(params) async {
  try {
    final response = await dio.post('/otp/verify', data: params);
    if (response.statusCode == 200) return OtpResponse(status: "success");
    return OtpResponse(errmessage: "error", status: "failed");
  } on SocketException catch (_) => OtpResponse(errmessage: NETWORK_ERROR);
}
```

**Providers/Notifiers** - manage UI state:
```dart
Future<bool> login(String email, String password) async {
  _isLoading = true; notifyListeners();
  try {
    _user = await authService.login(email, password);
    return true;
  } catch (e) { _error = e.toString(); return false; }
  finally { _isLoading = false; notifyListeners(); }
}
```

### Models
```dart
class User {
  final String id, email;
  User({required this.id, required this.email});
  
  factory User.fromJson(Map<String, dynamic> json) => 
      User(id: json['id'], email: json['email']);
  
  Map<String, dynamic> toJson() => {'id': id, 'email': email};
  
  User copyWith({String? id, String? email}) => 
      User(id: id ?? this.id, email: email ?? this.email);
}
```

### Theme & Navigation
- Colors: `AppColors` (`core/theme/app_colors.dart`)
- Text: `AppTextStyles` (`core/theme/app_text_styles.dart`)
- Spacing: `AppSpacing` (`core/theme/app_spacing.dart`)
- Navigation: Use GoRouter `context.push('/home')` or `context.push('/user/${user.id}')`

## Key Dependencies
- State: `flutter_riverpod ^2.4.9`
- Router: `go_router ^16.2.1`
- HTTP: `dio ^5.3.3`, `retrofit ^4.0.3`
- Storage: `shared_preferences`, `hive`

## Linting Rules
- Uses `flutter_lints`
- Avoid `print` statements (use `dart:developer` package)
- Prefer `const` constructors and single quotes
- Sort imports alphabetically
- Use explicit return types on public methods

## Formatting & Typing
- Avoid `dynamic` - use specific types or `Object?`
- Use `late` for late-initialized fields
- Nullable types: `String?` not `String | null`

## Testing
- Tests live in `test/` matching lib structure
- Use `flutter_test` matchers: `expect(find.byType(Text), findsOneWidget)`
- Mock services with `Mocktail` or manual mocks
- Test Riverpod providers with `ProviderScope` overrides

## Widget Performance Tips
- Use `CustomScrollView` with `Sliver` lists for long lists
- Wrap complex custom paints in `RepaintBoundary`
- Use `const` constructors everywhere possible
- Avoid rebuilding widgets unnecessarily with `select` or `selectAll`