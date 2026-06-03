import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../shared/widgets/noise_painter.dart';
import '../../../../features/receipt/presentation/screens/receipt_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _balanceVisible = true;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final List<_QuickAction> _quickActions = [
    _QuickAction(
      label: 'Mobile\nTop-Up',
      icon: Icons.phone_android_rounded,
      iconColor: Color(0xFF8B5CF6),
      bgColor: Color(0xFFf5f3ff),
      route: '/bills/airtime',
    ),
    _QuickAction(
      label: 'Electricity',
      icon: Icons.bolt_rounded,
      iconColor: Color(0xFFEAB308),
      bgColor: Color(0xFFfefce8),
      route: '/bills/electricity',
    ),
    _QuickAction(
      label: 'Cable TV',
      icon: Icons.tv_rounded,
      iconColor: Color(0xFFEC4899),
      bgColor: Color(0xFFfdf2f8),
      route: '/bills/cable',
    ),
    _QuickAction(
      label: 'More',
      icon: Icons.apps_rounded,
      iconColor: Color(0xFF166C46),
      bgColor: Color(0xFFF2F7F3),
      route: '/bills',
    ),
  ];

  final List<_Transaction> _recentTransactions = [
    _Transaction(
      name: 'Funmi Adebayo',
      description: 'Dinner split',
      amount: '12,500.00',
      time: '2 min ago',
      sent: true,
      initials: 'FA',
    ),
    _Transaction(
      name: 'Freelance Payment',
      description: 'Design project',
      amount: '450,000.00',
      time: '1 hour ago',
      sent: false,
      initials: 'FP',
    ),
    _Transaction(
      name: 'Netflix',
      description: 'Monthly subscription',
      amount: '2,900.00',
      time: 'Yesterday',
      sent: true,
      initials: 'NF',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Section ──
              _HeroSection(
                greeting: _greeting(),
                balanceVisible: _balanceVisible,
                onToggleBalance: () {
                  HapticFeedback.lightImpact();
                  setState(() => _balanceVisible = !_balanceVisible);
                },
              ),

              // ── White content below hero ──
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    _QuickActionsSection(actions: _quickActions),

                    const SizedBox(height: 24),

                    // Tier Upgrade Card
                    _TierUpgradeCard(),

                    const SizedBox(height: 24),

                    // Referral Card
                    _ReferralCard(),

                    const SizedBox(height: 24),

                    // Recent Transactions
                    _RecentTransactionsSection(
                      transactions: _recentTransactions,
                    ),

                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String greeting;
  final bool balanceVisible;
  final VoidCallback onToggleBalance;

  const _HeroSection({
    required this.greeting,
    required this.balanceVisible,
    required this.onToggleBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            bottom: 60, // extra space for the curve overlap
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF073D25),
                Color(0xFF0B4F2F),
                Color(0xFF073D25),
                Color(0xFF0B4F2F),
              ],
              stops: [0.0, 0.3, 0.65, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Noise overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: NoisePainter(opacity: 0.045, seed: 13),
                ),
              ),

              // Logo watermark (bottom-right)
              Positioned(
                right: 0,
                bottom: 30,
                child: Opacity(
                  opacity: 0.07,
                  child: Image.asset(
                    'assets/images/mild.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: greeting + bell
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting Adebayo 👋',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bell icon
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/notifications'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: Theme.of(context).cardColor,
                                size: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 7,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(0xFFD33B31),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Account switcher pill
                  GestureDetector(
                    onTap: () => _showAccountSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor:
                                const Color(0xFF166C46).withOpacity(0.8),
                            child: Text(
                              'AO',
                              style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Adebayo Okafor',
                            style: TextStyle(
                              color: Theme.of(context).cardColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.expand_more_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Balance
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        balanceVisible ? '₦15,750.00' : '••••••',
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onToggleBalance,
                        child: Icon(
                          balanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white60,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Account: 2138 5476 90',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.22)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            color: Color(0xFFD4AF37), size: 11),
                        SizedBox(width: 4),
                        Text(
                          'Basic Tier',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Effra',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Transfer / Add Money buttons (Transfer first, gold CTA)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/transfer'),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.goldPrimary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded,
                                    color: Theme.of(context).cardColor, size: 17),
                                SizedBox(width: 7),
                                Text(
                                  'Transfer',
                                  style: TextStyle(
                                    color: Theme.of(context).cardColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/add-money'),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline,
                                    color: Theme.of(context).cardColor, size: 18),
                                SizedBox(width: 7),
                                Text(
                                  'Add Money',
                                  style: TextStyle(
                                    color: Theme.of(context).cardColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),

        // Curved white fade at bottom of hero
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: _CurveClipper(),
            child: Container(
              height: 40,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Text(
              'Select Account',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _AccountTile(
              initials: 'AO',
              name: 'Adebayo Okafor',
              number: '2138 5476 90',
              type: 'Personal Account',
              isActive: true,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 20);
    path.quadraticBezierTo(
        size.width / 2, -10, size.width, 20);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ── Quick Actions Section ─────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  final List<_QuickAction> actions;
  const _QuickActionsSection({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map((action) {
            return GestureDetector(
              onTap: () => context.push(action.route),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? action.iconColor.withOpacity(0.15) : action.bgColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(action.icon,
                        color: action.iconColor, size: 26),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Tier Upgrade Card ─────────────────────────────────────────────────────────

class _TierUpgradeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Orange left strip
            Container(width: 4, color: const Color(0xFFff6b35)),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Circular progress
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 0.4,
                            strokeWidth: 4,
                            backgroundColor:
                                Theme.of(context).dividerColor,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFff6b35)),
                          ),
                          Center(
                            child: Text(
                              '40%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade to Tier 2',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Unlock higher limits & features',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/tiers'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFff6b35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Go',
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Referral Card ─────────────────────────────────────────────────────────────

class _ReferralCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFff6b35), Color(0xFFff8c42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff6b35).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite a friend,\nearn ₦500!',
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Share Code',
                      style: TextStyle(
                        color: Color(0xFFff6b35),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('🎁', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}

// ── Recent Transactions ───────────────────────────────────────────────────────

class _RecentTransactionsSection extends StatelessWidget {
  final List<_Transaction> transactions;
  const _RecentTransactionsSection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/transactions'),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166C46),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // "Today" label
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Today',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: transactions.asMap().entries.map((entry) {
              final i = entry.key;
              final tx = entry.value;
              final isLast = i == transactions.length - 1;
              return Column(
                children: [
                  _TransactionRow(tx: tx),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                      color: Theme.of(context).dividerColor,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final _Transaction tx;
  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tx.sent
                  ? const Color(0xFFD33B31).withOpacity(0.12)
                  : const Color(0xFF166C46).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                tx.initials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: tx.sent
                      ? const Color(0xFFD33B31)
                      : const Color(0xFF166C46),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.sent ? '-' : '+'}₦${tx.amount}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tx.sent
                      ? const Color(0xFFD33B31)
                      : const Color(0xFF166C46),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tx.time,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Account Tile ──────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final String initials;
  final String name;
  final String number;
  final String type;
  final bool isActive;

  const _AccountTile({
    required this.initials,
    required this.name,
    required this.number,
    required this.type,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.goldPrimary.withOpacity(0.06)
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.goldPrimary.withOpacity(0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                const Color(0xFF166C46).withOpacity(0.15),
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF166C46),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface)),
                Text('$type · $number',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
          if (isActive)
            const Icon(Icons.check_circle,
                color: Color(0xFF166C46), size: 20),
        ],
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class _QuickAction {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String route;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.route,
  });
}

class _Transaction {
  final String name;
  final String description;
  final String amount;
  final String time;
  final bool sent;
  final String initials;

  const _Transaction({
    required this.name,
    required this.description,
    required this.amount,
    required this.time,
    required this.sent,
    required this.initials,
  });
}

// Keep CardManagementScreen stub so router doesn't break
class CardManagementScreen extends StatelessWidget {
  const CardManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cards'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: const Center(child: Text('Cards coming soon')),
    );
  }
}
