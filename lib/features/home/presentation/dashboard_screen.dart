import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/Utils/haptics.dart';
import '../../../shared/widgets/rimapay_logo.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../receipt/presentation/screens/receipt_screen.dart';
import '../../notification/presentation/providers/notification_provider.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme_colors.dart';

const Color brandGreen = Color(0xFF1A6B35);
const Color darkGreen = Color(0xFF155C2C);
const Color goldAccent = Color(0xFFC9A84C);
const Color lightGreenBg = Color(0xFFE8F5ED);
const Color redDebit = Color(0xFFE53935);
const Color orangeIcon = Color(0xFFFF7043);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pull a fresh balance the moment the dashboard opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshBalance());
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Money may have arrived while the app was backgrounded — refresh on return.
    if (state == AppLifecycleState.resumed) {
      _refreshBalance();
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _refreshBalance());
  }

  Future<void> _refreshBalance() async {
    if (!mounted) return;
    await context.read<AuthProvider>().fetchAccounts(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshBalance,
          color: brandGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const _HeaderSection(),
                const _BalanceCard(),
                const _ActionButtons(),
                const _QuickServices(),
                const _BannerCarousel(),
                const _RecentTransactions(),
                const SizedBox(height: 24),
              ],
            ),
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
                        context.l10n.customerCare,
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
                        context.l10n.wereHereToHelp,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _careRow(context, Icons.phone_outlined, context.l10n.callUs,
                        '0800-RIMAPAY (0800-7462729)', const Color(0xFF1A6B35)),
                    const SizedBox(height: 10),
                    _careRow(
                        context,
                        Icons.chat_bubble_outline,
                        context.l10n.whatsapp,
                        '+234 800 746 2729',
                        const Color(0xFF25D366)),
                    const SizedBox(height: 10),
                    _careRow(context, Icons.mail_outline, context.l10n.email,
                        'support@rimamfb.ng', const Color(0xFF3B82F6)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                              size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.supportHours,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
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

Widget _careRow(BuildContext context, IconData icon, String title,
    String detail, Color color) {
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6))),
          ],
        ),
      ],
    ),
  );
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HeaderSection extends ConsumerStatefulWidget {
  const _HeaderSection();

  @override
  ConsumerState<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends ConsumerState<_HeaderSection> {
  @override
  void initState() {
    super.initState();
    // Fetch just the badge number, not the whole feed; the list loads when
    // the notifications screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ref.read(inAppNotificationsProvider.notifier).refreshUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final unread = ref.watch(unreadNotificationCountProvider);
    if (!auth.profileFetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        auth.fetchProfileFromApi();
      });
    }
    final user = auth.user;
    final textDark = Theme.of(context).colorScheme.onSurface;
    final textGray = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);
    final iconBg = Theme.of(context).colorScheme.onSurface.withOpacity(0.07);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? context.l10n.greetingMorning
        : hour < 17
            ? context.l10n.greetingAfternoon
            : context.l10n.greetingEvening;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              UserAvatar(
                imageUrl: user?.profileImageUrl,
                initials: user?.initials ?? '',
                radius: 21,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // greeting is already localized above.
                    '$greeting 👋',
                    style: GoogleFonts.dmSans(fontSize: 13, color: textGray),
                  ),
                  Text(
                    user?.firstName ?? 'User',
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
              const _LanguageToggle(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showCustomerCare(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.headset_mic_outlined,
                      size: 20, color: textDark),
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
                      child: Icon(Icons.notifications_outlined,
                          size: 20, color: textDark),
                    ),
                    // Only when there is something to read; the number used to
                    // be a hardcoded 3 and showed even with an empty feed.
                    if (unread > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          padding: EdgeInsets.symmetric(
                              horizontal: unread > 9 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(
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

  Widget _skeleton(double w, double h) => Shimmer.fromColors(
        baseColor: Colors.white24,
        highlightColor: Colors.white60,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final formattedBalance = user?.formattedBalance ?? '₦0.00';
    final accountNumber = user?.accountNumber ?? '';
    // NUBAN reads best as 3-3-4: "110 023 4567".
    final displayAccount = accountNumber.length == 10
        ? '${accountNumber.substring(0, 3)} ${accountNumber.substring(3, 6)} ${accountNumber.substring(6)}'
        : accountNumber;
    final tierName = user?.tierName ?? 'Basic Tier';

    // "₦12,345.67" → big "₦12,345" + small ".67".
    final dot = formattedBalance.lastIndexOf('.');
    final whole = dot > 0 ? formattedBalance.substring(0, dot) : formattedBalance;
    final kobo = dot > 0 ? formattedBalance.substring(dot) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF17773F), Color(0xFF0B4426)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B4426).withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rima logo watermark: upright, centred behind the balance,
            // white tone-on-tone so it never fights the figures.
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.07,
                  child: ColorFiltered(
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    child: RimapayLogo(width: 210, height: 210),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _GlassChip(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 13, color: Color(0xFFF5D06F)),
                            const SizedBox(width: 4),
                            Text(tierName,
                                style: const TextStyle(
                                    fontFamily: 'Effra',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _GlassIconButton(
                        icon: _balanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        onTap: () {
                          Haptics.tap();
                          setState(() => _balanceVisible = !_balanceVisible);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(context.l10n.availableBalance,
                      style: TextStyle(
                          fontFamily: 'Effra',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.75))),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 46,
                    child: auth.isFetchingBalance && _balanceVisible
                        ? Center(child: _skeleton(170, 34))
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: FittedBox(
                              key: ValueKey(_balanceVisible),
                              fit: BoxFit.scaleDown,
                              child: _balanceVisible
                                  ? Text.rich(
                                      TextSpan(children: [
                                        TextSpan(text: whole),
                                        TextSpan(
                                          text: kobo,
                                          style: TextStyle(
                                            fontSize: 22,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ]),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('₦ • • • • • •',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      )),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  // Account number (full, never truncated) + details, centred.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (accountNumber.isNotEmpty) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Haptics.tap();
                              Clipboard.setData(
                                  ClipboardData(text: accountNumber));
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        context.l10n.accountNumberCopied),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: const Color(0xFF155C2C),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                );
                            },
                            child: _GlassChip(
                              padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(displayAccount,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: Colors.white)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.copy_rounded,
                                      color: Colors.white.withOpacity(0.85),
                                      size: 15),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Haptics.tap();
                            context.push('/account-details');
                          },
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(context.l10n.accountDetails,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: const TextStyle(
                                        fontFamily: 'Effra',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0E5530))),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded,
                                    color: Color(0xFF0E5530), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted white chip used on the balance card.
class _GlassChip extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassChip({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: child,
      );
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.13),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      );
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
              onTap: () {
                Haptics.press();
                context.push('/transfer');
              },
              child: Container(
                height: 70,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: brandGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(context.l10n.transfer,
                        style: const TextStyle(
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
              onTap: () {
                Haptics.press();
                context.push('/add-money');
              },
              child: Container(
                height: 70,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color:
                      isDark ? Color(0xFF1A1F2E) : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Color(0xFF2D3348)
                          : Theme.of(context).dividerColor),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? brandGreen.withOpacity(0.15)
                            : lightGreenBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: brandGreen, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(context.l10n.addMoney,
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

/// Compact EN/HA switch in the dashboard header.
///
/// Settings has a full picker, but the language is worth reaching in one tap
/// from the home screen — a Hausa speaker who lands in English should not have
/// to navigate an English settings menu to get out of it. Shows the language
/// you would switch *to*, so the tap target reads as the action.
class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider).languageCode;
    final other = current == 'en' ? 'ha' : 'en';
    final textDark = Theme.of(context).colorScheme.onSurface;

    return Semantics(
      button: true,
      label: L10n.languageNames[other],
      child: GestureDetector(
        onTap: () {
          Haptics.tap();
          ref.read(languageProvider.notifier).setLanguage(other);
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, size: 16, color: textDark),
              const SizedBox(width: 5),
              Text(
                other.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Effra',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.quickServices,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDark)),
              GestureDetector(
                onTap: () => context.go('/bills'),
                child: Row(
                  children: [
                    Text(context.l10n.seeAll,
                        style: TextStyle(
                            fontFamily: 'Effra',
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary)),
                    Icon(Icons.chevron_right,
                        color: Theme.of(context).colorScheme.primary, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
              _QuickServiceTile(
                icon: Icons.phone_android,
                label: context.l10n.airtime,
                iconBgColor: context.adapt(const Color(0xFFE8F5ED), const Color(0xFF0B2417)),
                iconColor: brandGreen,
                route: '/bills/airtime',
              ),
              _QuickServiceTile(
                icon: Icons.wifi,
                label: context.l10n.data,
                iconBgColor: context.adapt(const Color(0xFFE3F2FD), const Color(0xFF0F1E3A)),
                iconColor: const Color(0xFF1976D2),
                route: '/bills/data',
              ),
              _QuickServiceTile(
                icon: Icons.bolt,
                label: context.l10n.electricity,
                iconBgColor: context.adapt(const Color(0xFFFFFDE7), const Color(0xFF2A1A08)),
                iconColor: const Color(0xFFF9A825),
                route: '/bills/electricity',
              ),
              _QuickServiceTile(
                icon: Icons.tv,
                label: context.l10n.cableTV,
                iconBgColor: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF7B1FA2),
                route: '/bills/cable',
              ),
              _QuickServiceTile(
                icon: Icons.school,
                label: context.l10n.education,
                iconBgColor: context.adapt(const Color(0xFFE3F2FD), const Color(0xFF0F1E3A)),
                iconColor: const Color(0xFF1565C0),
                route: '/education-bills',
              ),
              _QuickServiceTile(
                icon: Icons.credit_card_outlined,
                label: context.l10n.myCard,
                iconBgColor: const Color(0xFFE8EAF6),
                iconColor: const Color(0xFF3949AB),
                route: '/cards',
                comingSoon: true,
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

  /// Shows a "coming soon" message instead of opening [route].
  final bool comingSoon;

  const _QuickServiceTile({
    required this.icon,
    required this.label,
    required this.iconBgColor,
    required this.iconColor,
    required this.route,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? Color(0xFF1A1F2E) : Theme.of(context).cardColor;
    final tileBorder =
        isDark ? Color(0xFF2D3348) : Theme.of(context).dividerColor;
    final iconBg = isDark ? iconColor.withOpacity(0.15) : iconBgColor;

    return GestureDetector(
      onTap: () {
        Haptics.tap();
        if (comingSoon) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.comingSoonFeature(label)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1A3A6B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
        context.push(route);
      },
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

class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel();

  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

/// One promo slide. Only features that work end-to-end today belong here
/// (UAT: Hausa, bank transfers, airtime/data, receipts) — no upgrades/loans.
class _PromoSlide {
  final String title;
  final String body;
  final String cta;
  final IconData icon;
  final List<Color> colors;
  final bool isNew;
  final VoidCallback onTap;

  const _PromoSlide({
    required this.title,
    required this.body,
    required this.cta,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.isNew = false,
  });
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  final _controller = PageController();
  int _current = 0;
  int _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _count < 2 || !_controller.hasClients) return;
      _controller.animateToPage((_current + 1) % _count,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<_PromoSlide> _slides(BuildContext context) {
    final l10n = context.l10n;
    final isHausa = ref.watch(languageProvider).languageCode == 'ha';
    return [
      _PromoSlide(
        title: l10n.promoHausaTitle,
        body: l10n.promoHausaBody,
        cta: l10n.promoHausaCta,
        icon: Icons.translate_rounded,
        colors: const [Color(0xFF0E5B33), Color(0xFF1A8A4F)],
        isNew: true,
        onTap: () => ref
            .read(languageProvider.notifier)
            .setLanguage(isHausa ? 'en' : 'ha'),
      ),
      _PromoSlide(
        title: l10n.promoTransferTitle,
        body: l10n.promoTransferBody,
        cta: l10n.promoTransferCta,
        icon: Icons.send_rounded,
        colors: const [Color(0xFF1B3A8C), Color(0xFF3563E9)],
        onTap: () => context.push('/transfer'),
      ),
      _PromoSlide(
        title: l10n.promoAirtimeTitle,
        body: l10n.promoAirtimeBody,
        cta: l10n.promoAirtimeCta,
        icon: Icons.phone_iphone_rounded,
        colors: const [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
        onTap: () => context.push('/bills/airtime'),
      ),
      _PromoSlide(
        title: l10n.promoReceiptTitle,
        body: l10n.promoReceiptBody,
        cta: l10n.promoReceiptCta,
        icon: Icons.receipt_long_rounded,
        colors: const [Color(0xFFB4541A), Color(0xFFEA8A2E)],
        onTap: () => context.push('/transactions'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides(context);
    _count = slides.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 166,
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, i) => _PromoCard(slide: slides[i]),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slides.length, (i) {
              final active = _current == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? slides[i].colors.last
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
}

class _PromoCard extends StatelessWidget {
  final _PromoSlide slide;

  const _PromoCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: slide.colors,
            ),
          ),
          child: InkWell(
            onTap: () {
              Haptics.tap();
              slide.onTap();
            },
            child: Stack(
              children: [
                // Soft decorative rings, top-right.
                Positioned(
                  right: -40,
                  top: -50,
                  child: _ring(170, 0.08),
                ),
                Positioned(
                  right: 30,
                  bottom: -70,
                  child: _ring(130, 0.06),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (slide.isNew) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  context.l10n.promoNewTag,
                                  style: const TextStyle(
                                    fontFamily: 'Effra',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              slide.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Effra',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slide.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Effra',
                                fontSize: 12.5,
                                color: Colors.white.withOpacity(0.82),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    slide.cta,
                                    style: TextStyle(
                                      fontFamily: 'Effra',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: slide.colors.first,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 15, color: slide.colors.first),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Icon(slide.icon, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );
}

// ── Recent Transactions ───────────────────────────────────────────────────────

class _RecentTransactions extends ConsumerStatefulWidget {
  const _RecentTransactions();

  @override
  ConsumerState<_RecentTransactions> createState() =>
      _RecentTransactionsState();
}

class _RecentTransactionsState extends ConsumerState<_RecentTransactions> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(transactionProviders.notifier).fetchTransactions(),
    );
  }

  String _fmtAmount(double v) {
    final s = v.toStringAsFixed(2).split('.');
    final whole = s[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$whole.${s[1]}';
  }

  /// "Today, 10:55 AM", "Yesterday", "2 Oct" (this year) or "2 Oct 2025".
  /// Statement rows carry no time of day, so they show the date only.
  String _fmtTime(Transaction tx) {
    if (tx.dateUnknown) return '';
    final dt = tx.timestamp;
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final String day;
    if (d == today) {
      day = context.l10n.today;
    } else if (d == today.subtract(const Duration(days: 1))) {
      day = context.l10n.yesterday;
    } else {
      day = DateFormat(dt.year == now.year ? 'd MMM' : 'd MMM yyyy').format(dt);
    }
    if (!tx.timeKnown) return day;
    return '$day, ${DateFormat('h:mm a').format(dt)}';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final txs = ref.watch(recentTransactionsProvider);
    final state = ref.watch(transactionProviders);
    final dark = Theme.of(context).brightness == Brightness.dark;

    Widget body;
    if (state.isLoading && txs.isEmpty) {
      body = const _RecentSkeleton();
    } else if (txs.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: brandGreen.withOpacity(dark ? 0.22 : 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  color: dark ? const Color(0xFF4ADE80) : brandGreen),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.noTransactionsYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        children: [
          for (var i = 0; i < txs.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: Theme.of(context).dividerColor.withOpacity(0.6),
              ),
            _TransactionTile(
              tx: txs[i],
              amount:
                  '${txs[i].isIncoming ? '+' : '−'}₦${_fmtAmount(txs[i].amount)}',
              time: _fmtTime(txs[i]),
              isFirst: i == 0,
              isLast: i == txs.length - 1,
              onTap: () {
                Haptics.tap();
                context.push('/receipt',
                    extra: receiptDataForTransaction(txs[i]));
              },
            ),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.recentTransactions,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
              ),
              // A real button-sized target, not a word to aim at.
              Material(
                color: brandGreen.withOpacity(dark ? 0.22 : 0.08),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    Haptics.tap();
                    context.push('/transactions');
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.seeAll,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: dark ? const Color(0xFF4ADE80) : brandGreen,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded,
                            size: 18,
                            color: dark ? const Color(0xFF4ADE80) : brandGreen),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.7)),
              boxShadow: dark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: body,
          ),
        ],
      ),
    );
  }
}

/// Glyph and accent per kind of transaction, so a row is recognisable at a
/// glance (instead of every row being an up or down arrow).
(IconData, Color) _txVisual(Transaction tx) {
  switch (tx.type) {
    case TransactionType.addMoney:
      return (Icons.south_west_rounded, const Color(0xFF16A34A));
    case TransactionType.reversal:
      return (Icons.replay_rounded, const Color(0xFF0D9488));
    case TransactionType.transfer:
      return (Icons.north_east_rounded, const Color(0xFF2563EB));
    case TransactionType.electricity:
      return (Icons.bolt_rounded, const Color(0xFFD97706));
    case TransactionType.cable:
      return (Icons.live_tv_rounded, const Color(0xFF7C3AED));
    case TransactionType.airtime:
      return (Icons.phone_android_rounded, const Color(0xFF16A34A));
    case TransactionType.data:
      return (Icons.wifi_rounded, const Color(0xFF0284C7));
    case TransactionType.education:
      return (Icons.school_rounded, const Color(0xFF4F46E5));
    case TransactionType.government:
      return (Icons.account_balance_rounded, const Color(0xFF475569));
    case TransactionType.transport:
      return (Icons.directions_bus_rounded, const Color(0xFFEA580C));
    case TransactionType.betting:
      return (Icons.casino_rounded, const Color(0xFFDB2777));
    case TransactionType.loan:
      return (Icons.request_quote_rounded, const Color(0xFFCA8A04));
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  final String amount;
  final String time;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const _TransactionTile({
    required this.tx,
    required this.amount,
    required this.time,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (icon, accent) = _txVisual(tx);
    // Brighter accents on dark surfaces so the glyphs keep their contrast.
    final glyph = dark ? Color.lerp(accent, Colors.white, 0.35)! : accent;
    final incoming = tx.isIncoming;
    final amountColor = incoming
        ? (dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : onSurface;
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(20) : Radius.zero,
      bottom: isLast ? const Radius.circular(20) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: ConstrainedBox(
          // Comfortable thumb target for every row.
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(dark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: glyph, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.typeDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tx.recipient,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        time,
                        style: TextStyle(
                            fontSize: 11.5, color: onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder rows while the first load is in flight.
class _RecentSkeleton extends StatelessWidget {
  const _RecentSkeleton();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Shimmer.fromColors(
      baseColor: dark ? Colors.white10 : const Color(0xFFEDEFF1),
      highlightColor: dark ? Colors.white24 : context.adapt(const Color(0xFFF8F9FA), const Color(0xFF1A1F2E)),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [bar(120, 12), const SizedBox(height: 7), bar(170, 10)],
                    ),
                  ),
                  bar(70, 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
