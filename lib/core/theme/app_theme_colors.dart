import 'package:flutter/material.dart';

/// BuildContext extension — adaptive colors that switch with dark mode.
/// Usage:  context.isDark  /  context.bgPage  /  context.textPrimary  etc.
extension AppThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Backgrounds ────────────────────────────────────────────────────────────
  Color get bgPage =>
      isDark ? const Color(0xFF0F1117) : const Color(0xFFF9FAFB);
  Color get bgCard =>
      isDark ? const Color(0xFF1A1F2E) : Colors.white;
  Color get bgCardElevated =>
      isDark ? const Color(0xFF242938) : const Color(0xFFFAFBFC);
  Color get bgInput =>
      isDark ? const Color(0xFF1A1F2E) : const Color(0xFFF9FAFB);
  Color get bgInputFocused =>
      isDark ? const Color(0xFF242938) : Colors.white;

  // ── Text ───────────────────────────────────────────────────────────────────
  Color get textPrimary =>
      isDark ? const Color(0xFFE8EAF0) : const Color(0xFF101828);
  Color get textSecondary =>
      isDark ? const Color(0xFF8892A4) : const Color(0xFF667085);
  Color get textTertiary =>
      isDark ? const Color(0xFF5A6478) : const Color(0xFF98A2B3);
  Color get textDisabled =>
      isDark ? const Color(0xFF3D4456) : const Color(0xFFD0D5DD);

  // ── Borders & dividers ─────────────────────────────────────────────────────
  Color get border =>
      isDark ? const Color(0xFF2D3348) : const Color(0xFFE4E7EC);
  Color get borderFocused =>
      isDark ? const Color(0xFF4D9A6E) : const Color(0xFF166C46);
  Color get divider =>
      isDark ? const Color(0xFF2D3348) : const Color(0xFFE4E7EC);

  // ── Brand-tinted surfaces ──────────────────────────────────────────────────
  Color get bgBrandSubtle =>
      isDark ? const Color(0xFF0B2417) : const Color(0xFFF0FAF4);
  Color get bgWarningSubtle =>
      isDark ? const Color(0xFF2A1A08) : const Color(0xFFFFF7ED);
  Color get bgErrorSubtle =>
      isDark ? const Color(0xFF2A0B08) : const Color(0xFFFEF2F2);

  // ── Navigation bar ─────────────────────────────────────────────────────────
  Color get navBar =>
      isDark ? const Color(0xFF1A1F2E) : Colors.white;
  Color get navBarSelected =>
      isDark ? const Color(0xFF4D9A6E) : const Color(0xFF166C46);
  Color get navBarUnselected =>
      isDark ? const Color(0xFF5A6478) : const Color(0xFF98A2B3);

  // ── Status bar icon brightness ─────────────────────────────────────────────
  Brightness get statusBarIconBrightness =>
      isDark ? Brightness.light : Brightness.dark;
}
