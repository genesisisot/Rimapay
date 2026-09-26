import 'package:flutter/material.dart';

/// Profile photo with a graceful fallback chain: remote picture → initials →
/// person icon. A broken or expired URL never leaves an empty grey circle.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.initials = '',
    this.radius = 21,
    this.backgroundColor,
    this.foregroundColor,
  });

  bool get _hasUrl => (imageUrl ?? '').startsWith('http');

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).dividerColor;
    final fg = foregroundColor ?? Theme.of(context).cardColor;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: ClipOval(
        child: _hasUrl
            ? Image.network(
                imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(fg),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _fallback(fg),
              )
            : _fallback(fg),
      ),
    );
  }

  Widget _fallback(Color fg) {
    if (initials.trim().isEmpty) {
      return Icon(Icons.person, color: fg, size: radius * 1.05);
    }
    return Center(
      child: Text(
        initials.trim(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
          fontFamily: 'Effra',
        ),
      ),
    );
  }
}
