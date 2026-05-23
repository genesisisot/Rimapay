import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

const Color brandGreen = Color(0xFF1A6B35);
const Color darkGreen = Color(0xFF155C2C);
const Color goldAccent = Color(0xFFC9A84C);
const Color lightGreenBg = Color(0xFFE8F5ED);
const Color pageBg = Color(0xFFF5F5F5);
const Color cardBorder = Color(0xFFEEEEEE);
const Color textGray = Color(0xFF888888);
const Color textDark = Color(0xFF1A1A1A);
const Color redDebit = Color(0xFFE53935);
const Color orangeIcon = Color(0xFFFF7043);

const TextStyle headingBold = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: textDark,
);

const TextStyle balanceAmount = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  color: Colors.white,
);

const TextStyle labelSmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: textGray,
);

const TextStyle sectionTitle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: textDark,
);

const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: textDark,
);

const TextStyle whiteRegular = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w400,
  color: Color(0xFFAAAAAA),
);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: const [
              _HeaderSection(),
              _BalanceCard(),
              _ActionButtons(),
              _QuickServices(),
              _UpgradeBanner(),
              _RecentTransactions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 21,
                backgroundColor: Color(0xFFDDDDDD),
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: GoogleFonts.dmSans(fontSize: 13, color: textGray),
                  ),
                  Row(
                    children: [
                      Text(
                        'Adebayo',
                        style: TextStyle(fontFamily: "Effra", 
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('👋', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 26, color: textDark),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Available Balance', style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFAAAAAA),
                )),
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
                      style: balanceAmount,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Account No. 2138 5476 90', style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFAAAAAA),
                )),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_outlined,
                            color: Colors.white54, size: 14),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text('⭐', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text('Basic Tier',
                              style: TextStyle(fontFamily: "Effra", 
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text('Account Details',
                              style: TextStyle(fontFamily: "Effra", 
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: brandGreen)),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right,
                              color: brandGreen, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
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
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Transfer',
                        style: TextStyle(fontFamily: "Effra", 
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: lightGreenBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: brandGreen, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('Add Money',
                        style: TextStyle(fontFamily: "Effra", 
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textDark)),
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

class _QuickServices extends StatelessWidget {
  const _QuickServices();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick Services', style: sectionTitle),
              Row(
                children: [
                  Text('See All',
                      style: TextStyle(fontFamily: "Effra", 
                          fontSize: 13, color: brandGreen)),
                  const Icon(Icons.chevron_right, color: brandGreen, size: 16),
                ],
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
            children: const [
              _QuickServiceTile(
                icon: Icons.phone_android,
                label: 'Airtime',
                iconBgColor: Color(0xFFE8F5ED),
                iconColor: brandGreen,
                route: '/bills/airtime',
              ),
              _QuickServiceTile(
                icon: Icons.wifi,
                label: 'Data',
                iconBgColor: Color(0xFFE3F2FD),
                iconColor: Color(0xFF1976D2),
                route: '/bills/data',
              ),
              _QuickServiceTile(
                icon: Icons.bolt,
                label: 'Electricity',
                iconBgColor: Color(0xFFFFFDE7),
                iconColor: Color(0xFFF9A825),
                route: '/bills/electricity',
              ),
              _QuickServiceTile(
                icon: Icons.tv,
                label: 'Cable TV',
                iconBgColor: Color(0xFFF3E5F5),
                iconColor: Color(0xFF7B1FA2),
                route: '/bills/cable',
              ),
              _QuickServiceTile(
                icon: Icons.school,
                label: 'Education',
                iconBgColor: Color(0xFFE3F2FD),
                iconColor: Color(0xFF1565C0),
                route: '/education-bills',
              ),
              _QuickServiceTile(
                icon: Icons.phone_android,
                label: 'Airtime Cash',
                iconBgColor: Color(0xFFE8F5ED),
                iconColor: brandGreen,
                route: '/airtime-to-cash',
              ),
              _QuickServiceTile(
                icon: Icons.flight,
                label: 'Flights',
                iconBgColor: Color(0xFFF3E5F5),
                iconColor: Color(0xFF7B1FA2),
                route: '/air-transport',
              ),
              _QuickServiceTile(
                icon: Icons.apps,
                label: 'More',
                iconBgColor: Color(0xFFF5F5F5),
                iconColor: Color(0xFF757575),
                route: '/bills',
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
    return GestureDetector(
      onTap: () => context.push(route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontFamily: "Effra", fontSize: 12, color: textDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FAF4),
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
                children: [
                  Text(
                    'Upgrade to Tier 2',
                    style: TextStyle(fontFamily: "Effra", 
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: brandGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Unlock higher limits, lower fees and more amazing features.',
                    style: TextStyle(fontFamily: "Effra", 
                      fontSize: 13,
                      color: textGray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: brandGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Upgrade Now',
                            style: TextStyle(fontFamily: "Effra", 
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              color: Colors.white, size: 16),
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
      ),
    );
  }
}

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

    final lightLinePaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

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

    final coinPaint = Paint()
      ..color = goldAccent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(12, 16), 8, coinPaint);
    canvas.drawCircle(const Offset(70, 12), 6, coinPaint);
    canvas.drawCircle(const Offset(78, 30), 5, coinPaint);
    canvas.drawCircle(const Offset(8, 40), 4, coinPaint);

    canvas.drawLine(
      const Offset(20, 35),
      const Offset(55, 35),
      lightLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: sectionTitle),
              Row(
                children: [
                  Text('See All',
                      style: TextStyle(fontFamily: "Effra", 
                          fontSize: 13, color: brandGreen)),
                  const Icon(Icons.chevron_right, color: brandGreen, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            children: const [
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),
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
                Text(title, style: bodyMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: "Effra", fontSize: 12, color: textGray),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(fontFamily: "Effra", 
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? brandGreen : redDebit,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(fontFamily: "Effra", fontSize: 11, color: textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

