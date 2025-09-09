import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rev;
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/providers/language_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await StorageService.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    rev.ProviderScope(
      child: const RimaPayApp(),
    ),
  );
}

class RimaPayApp extends StatelessWidget {
  const RimaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: Consumer2<LanguageProvider, ThemeProvider>(
          builder: (context, languageProvider, themeProvider, child) {
            return MaterialApp.router(
              title: 'RimaPay',
              debugShowCheckedModeBanner: false,

              // Theme - Convert AppThemeMode to ThemeMode
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: _convertToThemeMode(themeProvider.themeMode),

              // Routing
              routerConfig: AppRouter.router,

              // Localization
              locale: languageProvider.currentLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizationsExtension.supportedLocales,

              // App Builder - Simplified to avoid MediaQuery issues
              // builder: (context, child) {
              //   return AnnotatedRegion<SystemUiOverlayStyle>(
              //     value: SystemUiOverlayStyle(
              //       statusBarColor: Colors.transparent,
              //       statusBarIconBrightness: themeProvider.isDarkMode
              //          ? Brightness.light
              //          : Brightness.dark,
              //       systemNavigationBarColor: themeProvider.isDarkMode
              //          ? Colors.black
              //          : Colors.white,
              //       systemNavigationBarIconBrightness: themeProvider.isDarkMode
              //          ? Brightness.light
              //          : Brightness.dark,
              //     ),
              //     child: Container(
              //       constraints: const BoxConstraints(maxWidth: 430),
              //       child: child ?? const SizedBox.shrink(),
              //     ),
              //   );
              // },
            );
          },
        ),
      ),
    );
  }

  /// Converts AppThemeMode to Flutter's ThemeMode
  ThemeMode _convertToThemeMode(dynamic appThemeMode) {
    // If you have an AppThemeMode enum, convert it here
    // Assuming AppThemeMode has values like: light, dark, system
    if (appThemeMode == null) return ThemeMode.system;

    switch (appThemeMode.toString()) {
      case 'AppThemeMode.light':
        return ThemeMode.light;
      case 'AppThemeMode.dark':
        return ThemeMode.dark;
      case 'AppThemeMode.system':
      default:
        return ThemeMode.system;
    }
  }
}
