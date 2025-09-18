// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rimapay/Utils/MyFlavorsConfig.dart';
import 'package:rimapay/main.dart';


void main() async {
  await AppInitializer.initialize();
  var appConfig = MyAppConfig(
    appTitle: "RimaPay",
    buildFlavour: "Production",
    isLive: true,
    skipUpdate: false,
    child: RimaPayApp(),
  );
  MyAppConfig.setInstance(appConfig);
  runApp(
    ProviderScope(
      child: appConfig,
    ),
  );
}
