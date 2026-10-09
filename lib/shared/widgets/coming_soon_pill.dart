import 'package:flutter/material.dart';

import '../../core/localization/l10n.dart';

/// Non-tappable "Coming soon" badge shown where a feature (e.g. account
/// upgrades) has no backend yet. Replaces the button instead of firing a
/// snackbar on every tap.
class ComingSoonPill extends StatelessWidget {
  /// True when drawn on a dark/brand background (white-on-glass style).
  final bool onDark;

  const ComingSoonPill({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg = onDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withOpacity(0.14)
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onDark
              ? Colors.white.withOpacity(0.22)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            context.l10n.comingSoon2,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'Effra',
            ),
          ),
        ],
      ),
    );
  }
}
