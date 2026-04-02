import 'package:flutter/material.dart';
// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rimapay/core/services/storage_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class MyAppConfig extends InheritedWidget {
  final String appTitle;
  final String buildFlavour;

  final bool skipUpdate;
  final bool isLive;
  @override
  final Widget child;

  const MyAppConfig({
    super.key,
    required this.appTitle,
    required this.buildFlavour,
    required this.skipUpdate,
    required this.isLive,
    required this.child,
  }) : super(child: child);

  static MyAppConfig? _instance;

  static void setInstance(MyAppConfig instance) {
    _instance = instance;
  }

  static bool getSkipUpdate() {
    if (_instance != null) {
      return _instance!.skipUpdate;
    } else {
      return false;
    }
  }
 static String getAppTitle() {
    if (_instance != null) {
      return _instance!.appTitle;
    } else {
      return "RimaPay";
    }
  }
  static bool getIsLive() {
    if (_instance != null) {
      return _instance!.isLive;
    } else {
      return false;
    }
  }

  static MyAppConfig? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyAppConfig>();
  }

  @override
  bool updateShouldNotify(MyAppConfig oldWidget) {
    return oldWidget.skipUpdate != skipUpdate || oldWidget.isLive != isLive;
  }
}

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Hive for local storage
    await Hive.initFlutter();
    await StorageService.initialize();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Enable edge-to-edge so content renders behind status bar and nav bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Set system UI overlay style — transparent bars, light icons for dark headers
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
}
