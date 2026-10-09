import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/features/receipt/presentation/screens/receipt_screen.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../bills/presentation/providers/bills_providers.dart';
import '../../../bills/presentation/widgets/bill_history_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/noise_painter.dart';

import '../../../../core/localization/l10n.dart';
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

  /// Set once the user picks a range; the 'range' chip filters by it and shows
  /// the dates it is currently using.
  DateTimeRange? _range;

  final List<_FilterOption> _filterOptions = [
    _FilterOption('all', 'All', Icons.list_rounded),
    _FilterOption('income', 'Income', Icons.arrow_downward_rounded),
    _FilterOption('expense', 'Expenses', Icons.arrow_upward_rounded),
    _FilterOption('electricity', 'Electricity', Icons.bolt_rounded),
    _FilterOption('cable', 'Cable TV', Icons.live_tv_rounded),
    _FilterOption('today', 'Today', Icons.today_rounded),
    _FilterOption('yesterday', 'Yesterday', Icons.history_rounded),
    _FilterOption('range', 'Date range', Icons.date_range_rounded),
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
    Future.microtask(
      () => ref.read(transactionProviders.notifier).fetchTransactions(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Electricity / Cable TV chips switch the list to `bills/history`, filtered
  /// server-side by utilityType: the statement can't be filtered by category,
  /// and bill records carry the real biller, meter, token and exact time.
  BillHistoryKind? get _billKind => switch (_selectedFilter) {
        'electricity' => BillHistoryKind.electricity,
        'cable' => BillHistoryKind.cableTv,
        _ => null,
      };

  /// Picking "Date range" opens the picker; every other chip just applies.
  /// Cancelling the picker leaves the previous filter in place rather than
  /// switching to an empty range.
  Future<void> _onFilterSelected(String id) async {
    if (id != 'range') {
      setState(() => _selectedFilter = id);
      return;
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range ??
          DateTimeRange(
              start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'Select a date range',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary500),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _range = picked;
      _selectedFilter = 'range';
    });
  }

  /// Label for the range chip, so the chosen dates are visible without
  /// reopening the picker.
  String get _rangeLabel {
    final r = _range;
    if (r == null) return 'Date range';
    String d(DateTime t) => '${t.day}/${t.month}';
    return '${d(r.start)} - ${d(r.end)}';
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
        return list.where((tx) => tx.isIncoming).toList();
      case 'expense':
        return list.where((tx) => !tx.isIncoming).toList();
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
      case 'range':
        final r = _range;
        if (r == null) return list;
        // Inclusive of both days the user picked, whatever time of day the
        // transaction carries.
        final from = DateTime(r.start.year, r.start.month, r.start.day);
        final to = DateTime(r.end.year, r.end.month, r.end.day)
            .add(const Duration(days: 1));
        return list
            .where((tx) =>
                !tx.timestamp.isBefore(from) && tx.timestamp.isBefore(to))
            .toList();
    }
    return list;
  }

  void _openReceipt(Transaction tx) {
    context.push('/receipt', extra: receiptDataForTransaction(tx));
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

  /// Money that actually left the account that day: purchases and transfers,
  /// minus any of them that were refunded. Money coming in isn't "spent".
  double _dayTotal(List<Transaction> list) {
    var out = 0.0;
    var refunded = 0.0;
    for (final tx in list) {
      if (tx.type == TransactionType.reversal) {
        refunded += tx.amount;
      } else if (!tx.isIncoming) {
        out += tx.amount;
      }
    }
    final spent = out - refunded;
    return spent > 0 ? spent : 0;
  }

  Map<String, List<Transaction>> _grouped(List<Transaction> list) {
    final map = <String, List<Transaction>>{};
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final tx in list) {
      if (tx.dateUnknown) {
        map.putIfAbsent('Unknown date', () => []).add(tx);
        continue;
      }
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
    final state = ref.watch(transactionProviders);
    final all = state.transactions;
    final filtered = _filtered(all);
    final grouped = _grouped(filtered);
    final showLoading = state.isLoading && all.isEmpty;
    final showError = !state.isLoading && state.error != null && all.isEmpty;
    final billKind = _billKind;
    final header = _Header(
      searchController: _searchController,
      selectedFilter: _selectedFilter,
      filterOptions: [
        for (final o in _filterOptions)
          o.id == 'range' ? _FilterOption(o.id, _rangeLabel, o.icon) : o,
      ],
      onFilterTap: _onFilterSelected,
      onFilterModalTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showFilter = true);
      },
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: billKind != null
                ? Column(
                    children: [
                      header,
                      Expanded(
                        child: BillHistoryList(
                          kind: billKind,
                          showSearch: false,
                          query: _searchQuery,
                          onRepeat: (row) => context.push(
                            billKind == BillHistoryKind.electricity
                                ? '/bills/electricity'
                                : '/bills/cable',
                            extra: row,
                          ),
                          onBuyNew: () => context.push(
                            billKind == BillHistoryKind.electricity
                                ? '/bills/electricity'
                                : '/bills/cable',
                          ),
                        ),
                      ),
                    ],
                  )
                : RefreshIndicator(
              onRefresh: () =>
                  ref.read(transactionProviders.notifier).fetchTransactions(),
              child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(child: header),

                // ── Summary strip ──
                if (all.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SummaryStrip(
                      transactions: all,
                      serverSpending: state.todaysSpending,
                      serverIncome: state.todaysIncome,
                    ),
                  ),

                // ── List ──
                if (showLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (showError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: state.error!,
                      onRetry: () => ref
                          .read(transactionProviders.notifier)
                          .fetchTransactions(),
                    ),
                  )
                else if (filtered.isEmpty)
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
                                    if (total > 0)
                                    Text(context.l10n.totalSpent(_fmtAmount(total)),
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
          ),

          // Filter modal
          if (_showFilter)
            _FilterModal(
              options: _filterOptions,
              selected: _selectedFilter,
              onSelect: (id) {
                setState(() => _showFilter = false);
                _onFilterSelected(id);
              },
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
                        child: Text(context.l10n.transactionHistory,
                          style: TextStyle(
                            color: Colors.white,
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
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Effra'),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchByNameType,
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

  /// Totals computed by the statement API; preferred when present.
  final double? serverSpending;
  final double? serverIncome;

  const _SummaryStrip({
    required this.transactions,
    this.serverSpending,
    this.serverIncome,
  });

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
    // Refunds cancel the purchase they reverse; they aren't income.
    final out = todayTx
        .where((tx) => !tx.isIncoming)
        .fold(0.0, (t, tx) => t + tx.amount);
    final refunded = todayTx
        .where((tx) => tx.type == TransactionType.reversal)
        .fold(0.0, (t, tx) => t + tx.amount);
    final localSpent = out - refunded > 0 ? out - refunded : 0.0;
    final localIncome = todayTx
        .where((tx) => tx.type == TransactionType.addMoney)
        .fold(0.0, (t, tx) => t + tx.amount);
    // The statement's own totals lag with it (₦0 right after a transfer), so
    // never let them hide money we know moved today.
    final spent = math.max(serverSpending ?? 0, localSpent);
    final income = math.max(serverIncome ?? 0, localIncome);

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
                Text(context.l10n.todaySSpending,
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
                Text(context.l10n.todaySIncome,
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
    if (tx.isIncoming) return AppColors.goldPrimary;
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
    if (tx.isIncoming) return AppColors.goldPrimary.withOpacity(0.08);
    switch (tx.type) {
      case TransactionType.transfer:
        return const Color(0xFF3B82F6).withOpacity(0.1);
      case TransactionType.electricity:
        return const Color(0xFFF59E0B).withOpacity(0.1);
      case TransactionType.cable:
        return const Color(0xFFEC4899).withOpacity(0.1);
      case TransactionType.data:
      case TransactionType.airtime:
        return const Color(0xFF8B5CF6).withOpacity(0.1);
      default:
        return AppColors.primary500.withOpacity(0.08);
    }
  }

  String get _icon {
    switch (tx.type) {
      case TransactionType.airtime:
        return '📱';
      case TransactionType.reversal:
        return '↩️';
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
    final isIncoming = tx.isIncoming;
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
                          tx.timeKnown ? fmtTime(tx.timestamp) : '',
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
                                ? const Color(0xFFF59E0B).withOpacity(0.15)
                                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
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

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

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
                color: const Color(0xFFD33B31).withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 38,
                  color: const Color(0xFFD33B31).withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(context.l10n.couldnTLoadTransactions,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'Effra',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(context.l10n.retry,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Effra',
                  ),
                ),
              ),
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
                        Text(context.l10n.filterTransactions,
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
                              color: Theme.of(context).colorScheme.surface,
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
                                      : Theme.of(context).colorScheme.surface,
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
