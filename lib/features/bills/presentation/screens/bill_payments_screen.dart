import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/noise_painter.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/widgets/coming_soon_pill.dart';
class BillService {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String route;
  final bool isLocked;
  final TierLevel requiredTier;

  BillService({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.route,
    this.isLocked = false,
    this.requiredTier = TierLevel.tier0,
  });
}

class BillPaymentsScreen extends StatefulWidget {
  const BillPaymentsScreen({super.key});

  @override
  State<BillPaymentsScreen> createState() => _BillPaymentsScreenState();
}

class _BillPaymentsScreenState extends State<BillPaymentsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    _searchController.dispose();
    super.dispose();
  }

  List<BillService> _getAllServices() {
    return [
      BillService(
        id: 'airtime',
        title: context.l10n.airtime,
        description: context.l10n.allNetworks,
        icon: Icons.phone_android,
        color: const Color(0xFF8B5CF6),
        bgColor: context.adapt(const Color(0xFFF5F3FF), const Color(0xFF1E1633)),
        route: '/bills/airtime',
      ),
      BillService(
        id: 'data',
        title: context.l10n.data,
        description: context.l10n.dataBundles,
        icon: Icons.wifi,
        color: const Color(0xFFF97316),
        bgColor: context.bgWarningSubtle,
        route: '/bills/data',
      ),
      BillService(
        id: 'electricity',
        title: context.l10n.electricity,
        description: context.l10n.discoPayments,
        icon: Icons.bolt,
        color: const Color(0xFFEAB308),
        bgColor: context.adapt(const Color(0xFFFEFCE8), const Color(0xFF2A1A08)),
        route: '/bills/electricity',
      ),
      BillService(
        id: 'cable',
        title: context.l10n.cableTV,
        description: context.l10n.cableProviders,
        icon: Icons.tv,
        color: const Color(0xFFEC4899),
        bgColor: context.adapt(const Color(0xFFFDF2F8), const Color(0xFF2A0F1F)),
        route: '/bills/cable',
      ),
      BillService(
        id: 'education',
        title: context.l10n.education,
        description: context.l10n.examBodies,
        icon: Icons.school,
        color: const Color(0xFF3B82F6),
        bgColor: context.adapt(const Color(0xFFEFF6FF), const Color(0xFF0F1E3A)),
        route: '/education-bills',
      ),
      BillService(
        id: 'internet',
        title: context.l10n.internet,
        description: context.l10n.internetProviders,
        icon: Icons.router_outlined,
        color: const Color(0xFF3949AB),
        bgColor: context.adapt(const Color(0xFFE8EAF6), const Color(0xFF1A1D3A)),
        route: '/bills/internet',
      ),
    ];
  }

  List<BillService> _filteredServices() {
    final all = _getAllServices();
    if (_searchQuery.isEmpty) return all;
    return all
        .where((s) =>
            s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.description.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onServiceTap(BillService service) {
    if (service.isLocked) {
      _showUpgradeSheet(service);
      return;
    }
    if (service.id == 'data') {
      context.push('/bills/airtime', extra: 1);
    } else {
      context.push(service.route);
    }
  }

  void _showUpgradeSheet(BillService service) {
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
            Icon(service.icon, size: 40, color: service.color),
            const SizedBox(height: 12),
            Text(
              context.l10n.upgradeToUnlockService(service.title),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.serviceRequiresTier(service.requiredTier.name.toUpperCase()),
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Account upgrades have no backend yet.
            Container(
              width: double.infinity,
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.upgradeAccount,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.45)),
                    ),
                  ),
                  const ComingSoonPill(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = _filteredServices();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // ── Green gradient header ──
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 20,
                      right: 20,
                      bottom: 28,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF073D25),
                          Color(0xFF0B4F2F),
                          Color(0xFF073D25),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: NoisePainter(opacity: 0.04, seed: 5),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back button
                            GestureDetector(
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/home');
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.18)),
                                ),
                                child: Icon(Icons.arrow_back_ios_new,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                            Text(
                              context.l10n.services,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.payBillsManageServices,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Search bar
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.18)),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: context.l10n.searchServices,
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.white.withOpacity(0.6),
                                      size: 20),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear,
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Service Grid ──
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = services[index];
                    return _ServiceCard(
                      service: service,
                      onTap: () => _onServiceTap(service),
                    );
                  },
                  childCount: services.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final BillService service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: service.isLocked
                ? Theme.of(context).dividerColor
                : service.color.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: service.isLocked
                          ? Theme.of(context).scaffoldBackgroundColor
                          : Theme.of(context).brightness == Brightness.dark
                              ? service.color.withOpacity(0.15)
                              : service.bgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        service.icon,
                        size: 24,
                        color: service.isLocked
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                            : service.color,
                      ),
                    ),
                  ),
                  if (service.isLocked)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.lock,
                            color: Theme.of(context).cardColor, size: 9),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                service.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: service.isLocked
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                      : Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                service.isLocked
                    ? '${service.requiredTier.name.toUpperCase()}+'
                    : service.description,
                style: TextStyle(
                  fontSize: 10,
                  color: service.isLocked
                      ? const Color(0xFFff6b35)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight:
                      service.isLocked ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
