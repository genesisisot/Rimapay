import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';

enum _AddMoneyStep { methodList, bankTransfer }

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  _AddMoneyStep _step = _AddMoneyStep.methodList;

  void _showComingSoon(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$method coming soon'),
        backgroundColor: const Color(0xFF101828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _step == _AddMoneyStep.methodList ? _MethodListView(
        onBankTransfer: () => setState(() => _step = _AddMoneyStep.bankTransfer),
        onComingSoon: _showComingSoon,
      ) : _BankTransferView(
        onBack: () => setState(() => _step = _AddMoneyStep.methodList),
      ),
    );
  }
}

// ─── Screen A: Method Selection ────────────────────────────────────────────

class _MethodListView extends StatelessWidget {
  final VoidCallback onBankTransfer;
  final void Function(String) onComingSoon;

  const _MethodListView({required this.onBankTransfer, required this.onComingSoon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Green gradient header (custom, no BillGreenHeader)
        _AddMoneyHeader(title: 'Add Money', subtitle: 'Fund your RimaPay wallet'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wallet Balance', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      const Text('₦12,450.00', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFF2F7F3), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_circle_outlined, size: 14, color: Color(0xFF166C46)),
                            SizedBox(width: 6),
                            Text('Adebayo Okafor · 0123456789', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166C46))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Choose Payment Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                const SizedBox(height: 12),

                _MethodCard(
                  icon: Icons.account_balance_outlined,
                  iconBg: const Color(0xFFF2F7F3),
                  iconColor: const Color(0xFF166C46),
                  title: 'Bank Transfer',
                  subtitle: 'Transfer from any bank account',
                  badge: 'Free · Instant',
                  badgeColor: const Color(0xFF166C46),
                  badgeBg: const Color(0xFFF2F7F3),
                  onTap: onBankTransfer,
                ),
                const SizedBox(height: 10),
                _MethodCard(
                  icon: Icons.credit_card_outlined,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Debit / Credit Card',
                  subtitle: 'Visa, Mastercard, Verve',
                  badge: 'Fee applies',
                  badgeColor: const Color(0xFF92400E),
                  badgeBg: const Color(0xFFFFFBEB),
                  onTap: () => onComingSoon('Card payment'),
                ),
                const SizedBox(height: 10),
                _MethodCard(
                  icon: Icons.dialpad_outlined,
                  iconBg: const Color(0xFFF5F3FF),
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'USSD',
                  subtitle: 'Dial a code from your phone',
                  badge: 'Free · No internet',
                  badgeColor: const Color(0xFF7C3AED),
                  badgeBg: const Color(0xFFF5F3FF),
                  onTap: () => onComingSoon('USSD'),
                ),
                const SizedBox(height: 10),
                _MethodCard(
                  icon: Icons.store_outlined,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFF97316),
                  title: 'Bank Deposit',
                  subtitle: 'Deposit cash at any bank branch',
                  badge: 'Free · 1–3 hours',
                  badgeColor: const Color(0xFFC2410C),
                  badgeBg: const Color(0xFFFFF7ED),
                  onTap: () => onComingSoon('Bank deposit'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.badge,
    required this.badgeColor, required this.badgeBg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor)),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen B: Bank Transfer ────────────────────────────────────────────────

class _BankTransferView extends StatelessWidget {
  final VoidCallback onBack;

  const _BankTransferView({required this.onBack});

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        backgroundColor: const Color(0xFF101828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyAll(BuildContext context) {
    const text = 'Bank: RimaPay MFB\nAccount: 0123456789\nName: Adebayo Okafor';
    Clipboard.setData(const ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Account details copied'),
        backgroundColor: const Color(0xFF101828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _iSentMoney(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Theme.of(context).cardColor, size: 18),
          SizedBox(width: 8),
          Text("We'll notify you when funds arrive"),
        ]),
        backgroundColor: const Color(0xFF166C46),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddMoneyHeader(title: 'Bank Transfer', subtitle: 'Transfer to fund your wallet', onBack: onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account details card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.account_balance_outlined, color: Theme.of(context).cardColor, size: 18),
                            SizedBox(width: 8),
                            Text('Your Dedicated Account', style: TextStyle(color: Theme.of(context).cardColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _AccountRow(label: 'Bank Name', value: 'RimaPay MFB', onCopy: null),
                            const Divider(height: 20, color: Color(0xFFF3F4F6)),
                            _AccountRow(
                              label: 'Account Number', value: '0123456789',
                              onCopy: () => _copy(context, '0123456789', 'Account number'),
                            ),
                            const Divider(height: 20, color: Color(0xFFF3F4F6)),
                            _AccountRow(
                              label: 'Account Name', value: 'Adebayo Okafor',
                              onCopy: () => _copy(context, 'Adebayo Okafor', 'Account name'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: GestureDetector(
                          onTap: () => _copyAll(context),
                          child: Container(
                            width: double.infinity, height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF166C46), width: 1.5),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.copy_rounded, size: 16, color: Color(0xFF166C46)),
                                SizedBox(width: 8),
                                Text('Copy All Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF166C46))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Info list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      _InfoRow(icon: Icons.bolt_rounded, iconColor: Color(0xFF166C46), text: 'Funds reflect instantly after transfer'),
                      SizedBox(height: 10),
                      _InfoRow(icon: Icons.person_outline_rounded, iconColor: Color(0xFFF59E0B), text: 'Use your registered name when transferring'),
                      SizedBox(height: 10),
                      _InfoRow(icon: Icons.info_outline_rounded, iconColor: Color(0xFF3B82F6), text: 'Minimum transfer: ₦100'),
                      SizedBox(height: 10),
                      _InfoRow(icon: Icons.schedule_rounded, iconColor: Color(0xFF9CA3AF), text: 'Transfers are available 24/7 including weekends'),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        // CTA
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
          child: GestureDetector(
            onTap: () => _iSentMoney(context),
            child: Container(
              width: double.infinity, height: 54,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Theme.of(context).cardColor, size: 18),
                  SizedBox(width: 8),
                  Text("I've Sent the Money", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _AccountRow({required this.label, required this.value, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.copy_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoRow({required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500))),
      ],
    );
  }
}

// ─── Shared green header ────────────────────────────────────────────────────

class _AddMoneyHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const _AddMoneyHeader({required this.title, required this.subtitle, this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).cardColor, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
