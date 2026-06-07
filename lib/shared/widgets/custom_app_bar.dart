import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge!.copyWith(
          color: foregroundColor ?? theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      scrolledUnderElevation: 1,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      foregroundColor: foregroundColor ?? theme.colorScheme.onSurface,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      leading: leading ?? (onBack != null 
        ? IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onBack!();
            },
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: foregroundColor ?? theme.colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.sm),
              minimumSize: const Size(44, 44),
            ),
          )
        : null),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}