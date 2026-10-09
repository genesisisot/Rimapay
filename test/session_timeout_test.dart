import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/localization/l10n.dart';
import 'package:rimapay/core/session/session_timeout.dart';

void main() {
  late int expired;
  late bool signedIn;
  final navKey = GlobalKey<NavigatorState>();

  Widget app() => MaterialApp(
        navigatorKey: navKey,
        localizationsDelegates: L10n.delegates,
        supportedLocales: L10n.supportedLocales,
        builder: (context, child) => SessionTimeout(
          timeout: const Duration(minutes: 5),
          warningBefore: const Duration(seconds: 30),
          isSessionActive: () => signedIn,
          navigatorContext: () => navKey.currentContext,
          onExpire: () async => expired++,
          child: child!,
        ),
        home: const Scaffold(body: Center(child: Text('home'))),
      );

  setUp(() {
    expired = 0;
    signedIn = true;
  });

  testWidgets('warns 30s before the 5-minute timeout', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(minutes: 4, seconds: 29));
    expect(find.text('Still there?'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Still there?'), findsOneWidget);
  });

  testWidgets('"Stay signed in" keeps the session', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(minutes: 4, seconds: 31));
    await tester.pump();
    await tester.tap(find.text('Stay signed in'));
    await tester.pumpAndSettle();
    expect(find.text('Still there?'), findsNothing);
    expect(expired, 0);
  });

  testWidgets('signs out when the countdown runs out', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(minutes: 4, seconds: 31));
    await tester.pump();
    for (var i = 0; i < 31; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(expired, 1);
    expect(find.text('Still there?'), findsNothing);
  });

  testWidgets('stays idle while nobody is signed in', (tester) async {
    signedIn = false;
    await tester.pumpWidget(app());
    await tester.pump(const Duration(minutes: 6));
    await tester.pump();
    expect(find.text('Still there?'), findsNothing);
    expect(expired, 0);
  });

  testWidgets('a tap restarts the countdown', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(minutes: 4));
    await tester.tap(find.text('home'));
    await tester.pump(const Duration(minutes: 4));
    await tester.pump();
    expect(find.text('Still there?'), findsNothing);
  });
}
