import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/features/receipt/presentation/screens/receipt_screen.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/noise_painter.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFilter = false;
  String _selectedFilter = 'all';

  final List<_FilterOption> _filterOptions = [
    _FilterOption('all', 'All', Icons.list_rounded),
    _FilterOption('income', 'Income', Icons.arrow_downward_rounded),
    _FilterOption('expense', 'Expenses', Icons.arrow_upward_rounded),
    _FilterOption('today', 'Today', Icons.today_rounded),
    _FilterOption('yesterday', 'Yesterday', Icons.history_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _filtered(List<Transaction> all) {
    var list = all;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((tx) =>
              tx.typeDisplayName.toLowerCase().contains(_searchQuery) ||
              tx.recipient.toLowerCase().contains(_searchQuery) ||
              (tx.description?.toLowerCase().contains(_searchQuery) ?? false))
          .toList();
    }
    switch (_selectedFilter) {
      case 'income':
        return list.where((tx) => tx.type == TransactionType.addMoney).toList();
      case 'expense':
        return list.where((tx) => tx.type != TransactionType.addMoney).toList();
      case 'today':
        final d = DateTime.now();
        return list
            .where((tx) =>
                tx.timestamp.year == d.year &&
                tx.timestamp.month == d.month &&
                tx.timestamp.day == d.day)
            .toList();
      case 'yesterday':
        final d = DateTime.now().subtract(const Duration(days: 1));
        return list
            .where((tx) =>
                tx.timestamp.year == d.year &&
                tx.timestamp.month == d.month &&
                tx.timestamp.day == d.day)
            .toList();
    }
    return list;
  }

  void _openReceipt(Transaction tx) {
    final re = ReceiptData.fromJson({
      'id': tx.id,
      'type': tx.typeDisplayName,
      'amount': tx.formattedAmount,
      'recipient': tx.recipient,
      'date': '${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year}',
      'time': _fmtTime(tx.timestamp),
      'status': 'success',
      'reference': tx.reference ?? 'RMP${DateTime.now().millisecondsSinceEpoch}',
      'description': '${tx.typeDisplayName} payment',
    });
    context.push('/receipt', extra: re);
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  String _fmtAmount(double v) {
    final s = v.toStringAsFixed(2).split('.');
    final whole = s[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$whole.${s[1]}';
  }

  double _dayTotal(List<Transaction> list) => list.fold(0.0, (t, tx) {
        return tx.type == TransactionType.addMoney
            ? t - tx.amount
            : t + tx.amount;
      });

  Map<String, List<Transaction>> _grouped(List<Transaction> list) {
    final map = <String, List<Transaction>>{};
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final tx in list) {
      final d = DateTime(
          tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
      final key = d == today
          ? 'Today'
          : d == yesterday
              ? 'Yesterday'
              : '${d.day}/${d.month}/${d.year}';
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(recentTransactionsProvider);
    final filtered = _filtered(all);
    final grouped = _grouped(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(child: _Header(
                  searchController: _searchController,
                  selectedFilter: _selectedFilter,
                  filterOptions: _filterOptions,
                  onFilterTap: (id) => setState(() => _selectedFilter = id),
                  onFilterModalTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showFilter = true);
                  },
                )),

                // ── Summary strip ──
                if (all.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SummaryStrip(transactions: all),
                  ),

                // ── List ──
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(hasSearch: _searchQuery.isNotEmpty),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, gi) {
                          final dateKey =
                              grouped.keys.elementAt(gi);
                          final txList = grouped[dateKey]!;
                          final total = _dayTotal(txList);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (gi > 0) const SizedBox(height: 20),
                              // Date group header
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateKey,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        fontFamily: 'Effra',
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    Text(
                                      '₦${_fmtAmount(total)} spent',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontFamily: 'Effra',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Cards
                              ...txList.map((tx) => _TxCard(
                                    tx: tx,
                                    fmtAmount: _fmtAmount,
                                    fmtTime: _fmtTime,
                                    onTap: () => _openReceipt(tx),
                                  )),
                            ],
                          );
                        },
                        childCount: grouped.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Filter modal
          if (_showFilter)
            _FilterModal(
              options: _filterOptions,
              selected: _selectedFilter,
              onSelect: (id) =>
                  setState(() {
                    _selectedFilter = id;
                    _showFilter = false;
                  }),
              onClose: () => setState(() => _showFilter = false),
            ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedFilter;
  final List<_FilterOption> filterOptions;
  final ValueChanged<String> onFilterTap;
  final VoidCallback onFilterModalTap;

  const _Header({
    required this.searchController,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterTap,
    required this.onFilterModalTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: NoisePainter(opacity: 0.04, seed: 3),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/home'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Transaction History',
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Effra',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 14,
                          fontFamily: 'Effra'),
                      decoration: InputDecoration(
                        hintText: 'Search by name, type...',
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 14,
                            fontFamily: 'Effra'),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.white.withOpacity(0.6), size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () => searchController.clear(),
                                child: Icon(Icons.close,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 18),
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
                ),
                const SizedBox(height: 14),

                // Filter chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filterOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final opt = filterOptions[i];
                      final active = opt.id == selectedFilter;
                      return GestureDetector(
                        onTap: () => onFilterTap(opt.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.goldPrimary
                                : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.goldPrimary
                                  : Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(opt.icon,
                                  size: 12,
                                  color: active
                                      ? const Color(0xFF073D25)
                                      : Colors.white.withOpacity(0.8)),
                              const SizedBox(width: 5),
                              Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Effra',
                                  color: active
                                      ? const Color(0xFF073D25)
                                      : Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Strip ─────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final List<Transaction> transactions;
  const _SummaryStrip({required this.transactions});

  String _fmt(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '₦$s';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayTx = transactions.where((tx) =>
        tx.timestamp.year == today.year &&
        tx.timestamp.month == today.month &&
        tx.timestamp.day == today.day);
    final spent = todayTx
        .where((tx) => tx.type != TransactionType.addMoney)
        .fold(0.0, (t, tx) => t + tx.amount);
    final income = todayTx
        .where((tx) => tx.type == TransactionType.addMoney)
        .fold(0.0, (t, tx) => t + tx.amount);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  'Today\'s Spending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF073D25).withOpacity(0.7),
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmt(spent),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF073D25),
                    fontFamily: 'Effra',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFF073D25).withOpacity(0.15),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Income',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF073D25).withOpacity(0.7),
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmt(income),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF073D25),
                    fontFamily: 'Effra',
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

// ── Transaction Card ──────────────────────────────────────────────────────────

class _TxCard extends StatelessWidget {
  final Transaction tx;
  final String Function(double) fmtAmount;
  final String Function(DateTime) fmtTime;
  final VoidCallback onTap;

  const _TxCard({
    required this.tx,
    required this.fmtAmount,
    required this.fmtTime,
    required this.onTap,
  });

  Color get _accentColor {
    if (tx.type == TransactionType.addMoney) return AppColors.goldPrimary;
    switch (tx.type) {
      case TransactionType.transfer:
        return const Color(0xFF3B82F6);
      case TransactionType.electricity:
        return const Color(0xFFF59E0B);
      case TransactionType.cable:
        return const Color(0xFFEC4899);
      case TransactionType.data:
      case TransactionType.airtime:
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary500;
    }
  }

  Color get _bgColor {
    if (tx.type == TransactionType.addMoney)
      return AppColors.goldPrimary.withOpacity(0.08);
    switch (tx.type) {
      case TransactionType.transfer:
        return const Color(0xFFEFF6FF);
      case TransactionType.electricity:
        return const Color(0xFFFEFCE8);
      case TransactionType.cable:
        return const Color(0xFFFDF2F8);
      case TransactionType.data:
      case TransactionType.airtime:
        return const Color(0xFFF5F3FF);
      default:
        return const Color(0xFFF2F7F3);
    }
  }

  String get _icon {
    switch (tx.type) {
      case TransactionType.airtime:
        return '📱';
      case TransactionType.data:
        return '📶';
      case TransactionType.electricity:
        return '⚡';
      case TransactionType.cable:
        return '📺';
      case TransactionType.transfer:
        return '💸';
      case TransactionType.addMoney:
        return '💰';
      case TransactionType.loan:
        return '🏦';
      case TransactionType.education:
        return '🎓';
      case TransactionType.betting:
        return '🎰';
      case TransactionType.transport:
        return '🚌';
      case TransactionType.government:
        return '🏛️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncoming = tx.type == TransactionType.addMoney;
    final isPending = tx.status == TransactionStatus.pending;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left accent strip
            Container(
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(_icon,
                      style: TextStyle(fontSize: 20)),
                ),
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.typeDisplayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Effra',
                            ),
                          ),
                        ),
                        Text(
                          '${isIncoming ? '+' : '-'}₦${fmtAmount(tx.amount)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Effra',
                            color: isIncoming
                                ? AppColors.goldDark
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.recipient,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontFamily: 'Effra',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          fmtTime(tx.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            fontFamily: 'Effra',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFFF8EC)
                                : const Color(0xFFF2F7F3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPending ? 'Pending' : 'Done',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Effra',
                              color: isPending
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.primary500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ),
                    if (tx.plan != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tx.plan!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF7C3AED),
                            fontFamily: 'Effra',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary500.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.receipt_long_outlined,
                  size: 38,
                  color: AppColors.primary500.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch ? 'No results found' : 'No transactions yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search term or filter'
                  : 'Your transaction history will appear here',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'Effra',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Modal ──────────────────────────────────────────────────────────────

class _FilterModal extends StatelessWidget {
  final List<_FilterOption> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;

  const _FilterModal({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withOpacity(0.45)),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Transactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'Effra',
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F8),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(Icons.close,
                                size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...options.map((opt) {
                      final active = opt.id == selected;
                      return GestureDetector(
                        onTap: () => onSelect(opt.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary500.withOpacity(0.06)
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary500.withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.primary500.withOpacity(0.1)
                                      : const Color(0xFFEEF2F7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(opt.icon,
                                    size: 18,
                                    color: active
                                        ? AppColors.primary500
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active
                                        ? AppColors.primary500
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    fontFamily: 'Effra',
                                  ),
                                ),
                              ),
                              if (active)
                                Icon(Icons.check_circle_rounded,
                                    color: AppColors.primary500, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _FilterOption {
  final String id;
  final String label;
  final IconData icon;
  const _FilterOption(this.id, this.label, this.icon);
}
