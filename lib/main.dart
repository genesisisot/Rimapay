import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:rimapay/Utils/MyFlavorsConfig.dart';

import 'core/providers/language_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/localization/l10n.dart';
import 'core/session/session_timeout.dart';

//flutter run -t lib/mainStaging.dart --flavor staging --debug
//flutter run -t lib/mainProduction.dart --flavor production --debug

//flutter build apk --flavor production -t lib/mainProd.dart
//flutter build apk --flavor staging -t lib/mainStaging.dart

//flutter build appbundle --release --flavor production -t lib/mainProd.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(ProviderScope(
    overrides: await buildStartupOverrides(),
    child: const RimaPayApp(),
  ));
}

/// Startup work that must complete before the first frame.
///
/// Reads the saved language and seeds [languageProvider] with it — loading it
/// asynchronously after `runApp` makes the app flash English on startup for a
/// Hausa user. Also initialises date symbols, without which `DateFormat`
/// throws `LocaleDataException` for Hausa.
///
/// Every entry point must use this: `mainProd.dart` and `mainStaging.dart`
/// each build their own `ProviderScope`, so the one here is unused in flavor
/// builds.
Future<List<Override>> buildStartupOverrides() async {
  await initializeDateFormatting();
  final savedLanguage = await LanguageNotifier.readSavedLanguageCode();
  return [
    languageProvider.overrideWith(
      (ref) => LanguageNotifier(Locale(savedLanguage)),
    ),
  ];
}

class RimaPayApp extends ConsumerStatefulWidget {
  static late WidgetRef globalRef;
  const RimaPayApp({super.key});

  @override
  ConsumerState<RimaPayApp> createState() => _RimaPayAppState();
}

class _RimaPayAppState extends ConsumerState<RimaPayApp> {
  @override
  void initState() {
    super.initState();
    RimaPayApp.globalRef = ref;
    Future.microtask(() => ref.read(themeProvider).initialize());
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final currentLocale = ref.watch(languageProvider);

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: MaterialApp.router(
          title: MyAppConfig.getAppTitle(),
          debugShowCheckedModeBanner: false,

          // Theme — wired to themeProvider
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.materialThemeMode,

          // Routing
          routerConfig: AppRouter.router,

          // Session timer: sign out after 5 minutes without interaction.
          builder: (context, child) => SessionTimeout(
            isSessionActive: () =>
                context.read<AuthProvider>().user != null &&
                !_isPublicRoute(),
            navigatorContext: () =>
                AppRouter.router.routerDelegate.navigatorKey.currentContext,
            onExpire: () => _expireSession(context.read<AuthProvider>()),
            child: child ?? const SizedBox.shrink(),
          ),

          // Localization — driven by languageProvider. Changing the locale
          // here rebuilds every route, because MaterialApp.router sits above
          // the Navigator, so the switch takes effect app-wide with no restart.
          locale: currentLocale,
          localizationsDelegates: L10n.delegates,
          supportedLocales: L10n.supportedLocales,
        ),
      ),
    );
  }
}

/// Screens where nobody is signed in yet — the session timer stays idle.
const _publicRoutes = [
  '/splash',
  '/welcome',
  '/auth',
  '/personal-account',
  '/business-account',
  '/forgot-password',
];

bool _isPublicRoute() {
  final path =
      AppRouter.router.routerDelegate.currentConfiguration.uri.path;
  return _publicRoutes.any((r) => path == r || path.startsWith('$r/'));
}

/// Session timed out: normal logout, back to login, say why.
Future<void> _expireSession(AuthProvider auth) async {
  await auth.logout();
  AppRouter.router.go('/auth?mode=login');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(
      content: Text(ctx.l10n.sessionExpired),
      behavior: SnackBarBehavior.floating,
    ));
  });
}
