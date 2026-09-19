import 'package:flutter/services.dart';

/// App-wide haptic vocabulary so every tap feels consistent.
///
/// - [tap]: selection tick for tiles, tabs, keypad digits, nav items.
/// - [press]: light thump for primary buttons.
/// - [success] / [error]: outcome of a payment or security action.
class Haptics {
  Haptics._();

  static void tap() => HapticFeedback.selectionClick();

  static void press() => HapticFeedback.lightImpact();

  static void success() => HapticFeedback.mediumImpact();

  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.heavyImpact();
  }
}
