import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rimapay/Utils/MyFlavorsConfig.dart';

import 'core/providers/language_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/localization/app_localizations.dart';

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

  runApp(const ProviderScope(child: RimaPayApp()));
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
    RimaPayApp.globalRef = ref;

    if (mounted) {
      setState(() {});
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Always use English locale for Material components to avoid localization issues
    // Your custom translations will handle the actual language switching
    const currentLocale = Locale('en', '');

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp.router(
        title: MyAppConfig.getAppTitle(),
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
