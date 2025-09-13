import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      statusBarBrightness: Brightness.light,
      
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: RimaPayApp(),
    ),
  );
}

class RimaPayApp extends ConsumerWidget {
  const RimaPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always use English locale for Material components to avoid localization issues
    // Your custom translations will handle the actual language switching
    final currentLocale = const Locale('en', '');

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp.router(
        title: 'RimaPay',
        debugShowCheckedModeBanner: false,

        // Theme
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,

        // Routing
        routerConfig: AppRouter.router,

        // Localization - Use English for Material components
        locale: currentLocale,
        localizationsDelegates: const [
          // Only include English Material localizations to avoid conflicts
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          // Your custom app localizations if you have them
          // AppLocalizations.delegate,
        ],
        
        // Supported locales - keep it simple
        supportedLocales: AppLocalizationsExtension.supportedLocales,
        
        // Fallback locale
        localeResolutionCallback: (locale, supportedLocales) {
          // Always return English as fallback
          return const Locale('en', '');
        },
      ),
    );
  }
}