import 'package:flutter/material.dart';

import '../../core/Utils/haptics.dart';
import '../../core/theme/app_colors.dart';

/// The app's one main-action button (Continue / Pay / Send / Save): gold
/// gradient, 54px, rounded 14. Disabled is a flat neutral fill; [loading]
/// swaps the label for a spinner and blocks taps.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? trailingIcon;
  final IconData? leadingIcon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.trailingIcon,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fg = enabled || loading ? Colors.white : onSurface.withOpacity(0.4);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                Haptics.press();
                onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled || loading ? AppColors.goldGradient : null,
            color: enabled || loading ? null : onSurface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.goldPrimary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 19, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Effra',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 6),
                      Icon(trailingIcon, size: 18, color: fg),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary action next to / below a primary one (Cancel, Copy, Share):
/// brand-green outline, same size and radius as [AppPrimaryButton].
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = onPressed == null
        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.35)
        : (dark ? AppColors.primary300 : AppColors.primary500);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Effra',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
