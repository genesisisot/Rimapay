import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/Utils/haptics.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';

/// Account details the user shares to receive money: name, number, bank.
class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  static const _green = Color(0xFF166C46);
  static const _bankName = 'Rima MFB';

  String _formatAccountNumber(String acct) => acct.length == 10
      ? '${acct.substring(0, 4)} ${acct.substring(4, 8)} ${acct.substring(8)}'
      : acct;

  String _shareText(String name, String acct) =>
      'Account Name: $name\nAccount Number: $acct\nBank: $_bankName';

  void _copy(BuildContext context, String value, String what) {
    Haptics.tap();
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$what copied'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.displayName ?? '';
    final acct = user?.accountNumber ?? '';
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final rows = <_DetailRow>[
      _DetailRow('Account Name', name, copyable: true),
      _DetailRow('Account Number', acct, display: _formatAccountNumber(acct), copyable: true),
      const _DetailRow('Bank', _bankName),
      _DetailRow('Account Tier', user?.tierName ?? 'Basic Tier'),
      if ((user?.phoneNumber ?? '').isNotEmpty) _DetailRow('Phone Number', user!.phoneNumber!),
      if ((user?.email ?? '').isNotEmpty) _DetailRow('Email', user!.email),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const BillGreenHeader(
            title: 'Account Details',
            subtitle: 'Share these details to receive money',
            showAccountCard: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BillAccountCard(),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: i == rows.length - 1
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                                      ),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rows[i].label,
                                          style: TextStyle(
                                            fontFamily: 'Effra',
                                            fontSize: 11,
                                            color: onSurface.withOpacity(0.5),
                                          )),
                                      const SizedBox(height: 3),
                                      Text(
                                        rows[i].shown.isEmpty ? '—' : rows[i].shown,
                                        style: TextStyle(
                                          fontFamily: 'Effra',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (rows[i].copyable && rows[i].value.isNotEmpty)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _copy(context, rows[i].value, rows[i].label),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.copy_rounded, size: 17, color: _green),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.copy_all_rounded,
                          label: 'Copy All',
                          filled: false,
                          onTap: acct.isEmpty
                              ? null
                              : () => _copy(context, _shareText(name, acct), 'Account details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          filled: true,
                          onTap: acct.isEmpty
                              ? null
                              : () {
                                  Haptics.press();
                                  Share.share(_shareText(name, acct),
                                      subject: 'My $_bankName account details');
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  final String? display;
  final bool copyable;

  const _DetailRow(this.label, this.value, {this.display, this.copyable = false});

  String get shown => display ?? value;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  static const _green = Color(0xFF166C46);

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = filled ? Colors.white : _green;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: filled ? _green : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Effra',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
