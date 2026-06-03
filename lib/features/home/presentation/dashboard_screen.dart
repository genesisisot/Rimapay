import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

const Color brandGreen = Color(0xFF1A6B35);
const Color darkGreen = Color(0xFF155C2C);
const Color goldAccent = Color(0xFFC9A84C);
const Color lightGreenBg = Color(0xFFE8F5ED);
const Color redDebit = Color(0xFFE53935);
const Color orangeIcon = Color(0xFFFF7043);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: const [
              _HeaderSection(),
              _BalanceCard(),
              _ActionButtons(),
              _QuickServices(),
              _BannerCarousel(),
              _RecentTransactions(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Customer care sheet ───────────────────────────────────────────────────────

void _showCustomerCare(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Customer Care',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        "We're here to help you",
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _careRow(context, Icons.phone_outlined, 'Call Us',
                        '0800-RIMAPAY (0800-7462729)', const Color(0xFF1A6B35)),
                    const SizedBox(height: 10),
                    _careRow(context, Icons.chat_bubble_outline, 'WhatsApp',
                        '+234 800 746 2729', const Color(0xFF25D366)),
                    const SizedBox(height: 10),
                    _careRow(context, Icons.mail_outline, 'Email',
                        'support@rimamfb.ng', const Color(0xFF3B82F6)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mon – Fri: 8am – 8pm\nSat: 9am – 5pm',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _careRow(BuildContext context, IconData icon, String title, String detail, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: color)),
            Text(detail,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ],
    ),
  );
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final textDark = Theme.of(context).colorScheme.onSurface;
    final textGray = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);
    final iconBg = Theme.of(context).colorScheme.onSurface.withOpacity(0.07);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: Theme.of(context).dividerColor,
                child: Icon(Icons.person, color: Theme.of(context).cardColor, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning 👋',
                    style: GoogleFonts.dmSans(fontSize: 13, color: textGray),
                  ),
                  Text(
                    'Mustapha',
                    style: TextStyle(
                      fontFamily: 'Effra',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showCustomerCare(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.headset_mic_outlined, size: 20, color: textDark),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.notifications_outlined, size: 20, color: textDark),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('3',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Balance Card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatefulWidget {
  const _BalanceCard();

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _balanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: brandGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Available Balance',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFAAAAAA))),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                      child: Icon(
                        _balanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _balanceVisible ? '₦15,750.00' : '••••••',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: '2138547690'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Account number copied'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF155C2C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Text('Account No. 2138 5476 90',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFAAAAAA))),
                      SizedBox(width: 6),
                      Icon(Icons.copy_outlined, color: Colors.white54, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text('⭐', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text('Basic Tier',
                          style: TextStyle(
                              fontFamily: 'Effra',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text('Account Details',
                          style: TextStyle(
                              fontFamily: 'Effra',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: brandGreen)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, color: brandGreen, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/transfer'),
              child: Container(
                height: 70,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: brandGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Transfer',
                        style: TextStyle(
                            fontFamily: 'Effra',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/add-money'),
              child: Container(
                height: 70,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1A1F2E) : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Color(0xFF2D3348) : Theme.of(context).dividerColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? brandGreen.withOpacity(0.15) : lightGreenBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: brandGreen, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('Add Money',
                        style: TextStyle(
                            fontFamily: 'Effra',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Services ────────────────────────────────────────────────────────────

class _QuickServices extends StatelessWidget {
  const _QuickServices();

  @override
  Widget build(BuildContext context) {
    final textDark = Theme.of(context).colorScheme.onSurface;
    final textGray = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick Services',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDark)),
              GestureDetector(
                onTap: () => context.go('/bills'),
                child: Row(
                  children: [
                    Text('See All',
                        style: TextStyle(
                            fontFamily: 'Effra',
                            fontSize: 13,
                            color: brandGreen)),
                    const Icon(Icons.chevron_right, color: brandGreen, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _QuickServiceTile(
                icon: Icons.phone_android,
                label: 'Airtime',
                iconBgColor: const Color(0xFFE8F5ED),
                iconColor: brandGreen,
                route: '/bills/airtime',
              ),
              _QuickServiceTile(
                icon: Icons.wifi,
                label: 'Data',
                iconBgColor: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1976D2),
                route: '/bills/data',
              ),
              _QuickServiceTile(
                icon: Icons.bolt,
                label: 'Electricity',
                iconBgColor: const Color(0xFFFFFDE7),
                iconColor: const Color(0xFFF9A825),
                route: '/bills/electricity',
              ),
              _QuickServiceTile(
                icon: Icons.tv,
                label: 'Cable TV',
                iconBgColor: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF7B1FA2),
                route: '/bills/cable',
              ),
              _QuickServiceTile(
                icon: Icons.school,
                label: 'Education',
                iconBgColor: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1565C0),
                route: '/education-bills',
              ),
              _QuickServiceTile(
                icon: Icons.phone_android,
                label: 'Airtime Cash',
                iconBgColor: const Color(0xFFE8F5ED),
                iconColor: brandGreen,
                route: '/airtime-to-cash',
              ),
              _QuickServiceTile(
                icon: Icons.savings_outlined,
                label: 'Fixed Dep.',
                iconBgColor: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFE65100),
                route: '/fixed-deposit',
              ),
              _QuickServiceTile(
                icon: Icons.credit_card_outlined,
                label: 'My Card',
                iconBgColor: const Color(0xFFE8EAF6),
                iconColor: const Color(0xFF3949AB),
                route: '/cards',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBgColor;
  final Color iconColor;
  final String route;

  const _QuickServiceTile({
    required this.icon,
    required this.label,
    required this.iconBgColor,
    required this.iconColor,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? Color(0xFF1A1F2E) : Theme.of(context).cardColor;
    final tileBorder = isDark ? Color(0xFF2D3348) : Theme.of(context).dividerColor;
    final iconBg = isDark ? iconColor.withOpacity(0.15) : iconBgColor;

    return GestureDetector(
      onTap: () => context.push(route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tileBorder,
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  fontFamily: 'Effra',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner Carousel ───────────────────────────────────────────────────────────

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % 2;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _current = i),
              children: [
                _buildUpgradeBanner(context),
                _buildLoansBanner(context),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i
                      ? brandGreen
                      : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0B2417)
            : const Color(0xFFF0FAF4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Upgrade to Tier 2',
                  style: TextStyle(
                    fontFamily: 'Effra',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: brandGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Unlock higher limits, lower fees and more amazing features.',
                  style: TextStyle(
                    fontFamily: 'Effra',
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push('/tiers'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: brandGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Upgrade Now',
                            style: TextStyle(
                                fontFamily: 'Effra',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: CustomPaint(
                size: const Size(90, 90),
                painter: WalletIllustrationPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A6B), Color(0xFF0D2149)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('💰', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Need a Loan?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get up to ₦500,000 at low interest. Quick approval.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Loan application coming soon!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF1A3A6B),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Apply Now',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Transactions ───────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    final textDark = Theme.of(context).colorScheme.onSurface;
    final textGray = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDark)),
              GestureDetector(
                onTap: () => context.push('/transactions'),
                child: Row(
                  children: [
                    Text('See All',
                        style: TextStyle(
                            fontFamily: 'Effra',
                            fontSize: 13,
                            color: brandGreen)),
                    const Icon(Icons.chevron_right, color: brandGreen, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _TransactionTile(
            iconBgColor: brandGreen,
            icon: Icons.arrow_downward,
            title: 'Money Received',
            subtitle: 'From Abdullahi Musa',
            amount: '+ ₦5,000.00',
            time: 'Today, 08:45 AM',
            isCredit: true,
          ),
          _TransactionTile(
            iconBgColor: orangeIcon,
            icon: Icons.arrow_upward,
            title: 'Airtime Purchase',
            subtitle: 'MTN Airtime',
            amount: '- ₦500.00',
            time: 'Today, 08:20 AM',
            isCredit: false,
          ),
          _TransactionTile(
            iconBgColor: brandGreen,
            icon: Icons.arrow_downward,
            title: 'POS Settlement',
            subtitle: 'Rima POS 001',
            amount: '+ ₦12,000.00',
            time: 'Yesterday, 06:30 PM',
            isCredit: true,
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Color iconBgColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final String time;
  final bool isCredit;

  const _TransactionTile({
    required this.iconBgColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    final textDark = Theme.of(context).colorScheme.onSurface;
    final textGray = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: 'Effra',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontFamily: 'Effra', fontSize: 12, color: textGray)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontFamily: 'Effra',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? brandGreen : redDebit,
                ),
              ),
              const SizedBox(height: 2),
              Text(time,
                  style: TextStyle(
                      fontFamily: 'Effra', fontSize: 11, color: textGray)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Wallet illustration painter ───────────────────────────────────────────────

class WalletIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final walletPaint = Paint()
      ..color = brandGreen
      ..style = PaintingStyle.fill;

    final darkGreenPaint = Paint()
      ..color = darkGreen
      ..style = PaintingStyle.fill;

    final goldPaint = Paint()
      ..color = goldAccent
      ..style = PaintingStyle.fill;

    final walletBody = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 25, 65, 45),
      const Radius.circular(10),
    );
    canvas.drawRRect(walletBody, walletPaint);

    final walletFlap = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 25, 65, 16),
      const Radius.circular(10),
    );
    canvas.drawRRect(walletFlap, darkGreenPaint);

    final clasp = RRect.fromRectAndRadius(
      Rect.fromLTWH(42 - 7, 25 - 4, 14, 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(clasp, goldPaint);

    canvas.drawCircle(const Offset(12, 16), 8, goldPaint);
    canvas.drawCircle(const Offset(70, 12), 6, goldPaint);
    canvas.drawCircle(const Offset(78, 30), 5, goldPaint);
    canvas.drawCircle(const Offset(8, 40), 4, goldPaint);

    final lightLinePaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
        const Offset(20, 35), const Offset(55, 35), lightLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
