import 'package:flutter/material.dart';

import '../../core/Utils/haptics.dart';
import '../../core/localization/l10n.dart';
import '../../core/theme/app_colors.dart';

/// Asks how to share a receipt. Returns true for an image, false for a PDF,
/// or null if the sheet was dismissed.
Future<bool?> showReceiptFormatSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _ReceiptFormatSheet(),
  );
}

class _ReceiptFormatSheet extends StatelessWidget {
  const _ReceiptFormatSheet();

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.shareReceiptAs,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: onSurface),
          ),
          const SizedBox(height: 16),
          _Option(
            icon: Icons.picture_as_pdf_outlined,
            color: AppColors.error,
            title: context.l10n.receiptPdf,
            subtitle: context.l10n.receiptPdfHint,
            onTap: () => Navigator.pop(context, false),
          ),
          const SizedBox(height: 10),
          _Option(
            icon: Icons.image_outlined,
            color: AppColors.primary500,
            title: context.l10n.receiptImage,
            subtitle: context.l10n.receiptImageHint,
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Haptics.tap();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: onSurface.withOpacity(0.55))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: onSurface.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
