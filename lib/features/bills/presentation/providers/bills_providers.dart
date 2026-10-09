import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bills_api_service.dart';
import '../../data/bills_dtos.dart';

final billsApiServiceProvider = Provider<BillsApiService>((ref) {
  return BillsApiService();
});

// ── Airtime & data ────────────────────────────────────────────────────────────

final airtimeLimitProvider =
    FutureProvider.autoDispose<UtilityLimitDto?>((ref) {
  return ref.watch(billsApiServiceProvider).getAirtimeLimit();
});

/// Networks the backend currently sells data for (e.g. MTN, AIRTEL, GLO, 9MOBILE).
final dataNetworksProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(billsApiServiceProvider).getDataNetworks();
});

/// Data bundles keyed by `(network, validityType)`,
/// e.g. `('MTN', 'Monthly')`.
final dataPlansProvider = FutureProvider.autoDispose
    .family<List<DataBundleDto>, (String, String)>((ref, key) async {
  final plans = await ref
      .watch(billsApiServiceProvider)
      .getDataPlans(network: key.$1, validityType: key.$2);
  return [...plans]..sort((a, b) => a.sortOrder != b.sortOrder
      ? a.sortOrder.compareTo(b.sortOrder)
      : a.amount.compareTo(b.amount));
});

/// Saved + frequent airtime/data beneficiaries for the signed-in user.
final beneficiariesProvider =
    FutureProvider.autoDispose<List<BeneficiaryDto>>((ref) {
  return ref.watch(billsApiServiceProvider).getBeneficiaries();
});

// ── Billers ───────────────────────────────────────────────────────────────────

final billerCategoriesProvider =
    FutureProvider.autoDispose<List<BillerCategoryDto>>((ref) {
  return ref.watch(billsApiServiceProvider).getCategories();
});

/// App bill screens that are backed by a biller category.
///
/// Category IDs are owned by the backend/QuickTeller sync, so screens resolve
/// their category by name keywords instead of hardcoding IDs.
enum BillCategoryKind { electricity, cable, internet, education, government }

extension BillCategoryKindKeywords on BillCategoryKind {
  /// Tried in order; the first category whose name contains a keyword wins.
  List<String> get keywords {
    switch (this) {
      case BillCategoryKind.electricity:
        return const ['electric', 'disco', 'utilit'];
      case BillCategoryKind.cable:
        return const ['cable', 'tv'];
      case BillCategoryKind.internet:
        return const ['internet'];
      case BillCategoryKind.education:
        return const ['educat', 'exam', 'school'];
      case BillCategoryKind.government:
        return const ['government', 'tax', 'state'];
    }
  }
}

class CategoryBillers {
  /// Null when no backend category matched this screen.
  final int? categoryId;
  final List<BillerDto> billers;

  const CategoryBillers({this.categoryId, this.billers = const []});
}

final billersByKindProvider = FutureProvider.autoDispose
    .family<CategoryBillers, BillCategoryKind>((ref, kind) async {
  final categories = await ref.watch(billerCategoriesProvider.future);
  final active = categories.where((c) => c.isActive).toList();

  BillerCategoryDto? match;
  for (final keyword in kind.keywords) {
    for (final c in active) {
      if ((c.name ?? '').toLowerCase().contains(keyword)) {
        match = c;
        break;
      }
    }
    if (match != null) break;
  }

  if (match == null) {
    debugPrint('No biller category for ${kind.name}. '
        'Available: ${active.map((c) => '${c.categoryId}:${c.name}').join(', ')}');
    return const CategoryBillers();
  }

  final billers =
      await ref.watch(billsApiServiceProvider).getBillers(match.categoryId);
  return CategoryBillers(
    categoryId: match.categoryId,
    billers: billers.where((b) => b.isActive).toList(),
  );
});

final billerItemsProvider = FutureProvider.autoDispose
    .family<List<BillerItemDto>, int>((ref, billerId) async {
  final items =
      await ref.watch(billsApiServiceProvider).getBillerItems(billerId);
  return items.where((i) => i.isActive).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final billLimitProvider =
    FutureProvider.autoDispose.family<UtilityLimitDto?, int>((ref, categoryId) {
  return ref.watch(billsApiServiceProvider).getBillLimit(categoryId);
});

/// Forces a fresh fetch of categories and the billers for [kind].
void refreshBillers(WidgetRef ref, BillCategoryKind kind) {
  ref.invalidate(billerCategoriesProvider);
  ref.invalidate(billersByKindProvider(kind));
}

// ── Bill history ──────────────────────────────────────────────────────────────

/// Bill screens with a History tab, mapped to the backend `UtilityType` filter.
enum BillHistoryKind { electricity, cableTv, airtime, data }

extension BillHistoryKindApi on BillHistoryKind {
  /// `bills/history` filter; airtime and data have endpoints of their own.
  String get utilityType => switch (this) {
        BillHistoryKind.electricity => 'Electricity',
        BillHistoryKind.cableTv => 'CableTv',
        BillHistoryKind.airtime => 'Airtime',
        BillHistoryKind.data => 'Data',
      };
}

class BillHistoryState {
  final List<BillPaymentHistoryDto> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const BillHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  /// True before the first page has come back.
  bool get isInitialLoad => isLoading && items.isEmpty;

  BillHistoryState copyWith({
    List<BillPaymentHistoryDto>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) =>
      BillHistoryState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

/// Paged purchase history for one bill kind, filtered server-side by
/// `utilityType`, newest first.
class BillHistoryNotifier extends StateNotifier<BillHistoryState> {
  BillHistoryNotifier(this._ref, this.kind) : super(const BillHistoryState()) {
    loadMore();
  }

  final Ref _ref;
  final BillHistoryKind kind;
  static const _pageSize = 20;
  int _nextPage = 1;

  Future<void> refresh() async {
    _nextPage = 1;
    state = const BillHistoryState();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final api = _ref.read(billsApiServiceProvider);
      final page = await switch (kind) {
        BillHistoryKind.airtime =>
          api.getAirtimeHistory(page: _nextPage, pageSize: _pageSize),
        BillHistoryKind.data =>
          api.getDataHistory(page: _nextPage, pageSize: _pageSize),
        _ => api.getBillHistory(
            page: _nextPage,
            pageSize: _pageSize,
            utilityType: kind.utilityType,
          ),
      };
      if (!mounted) return;
      _nextPage++;
      final seen = state.items.map((e) => e.id).toSet();
      final items = [
        ...state.items,
        ...page.where((e) => e.id.isEmpty || seen.add(e.id)),
      ]..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      state = BillHistoryState(items: items, hasMore: page.length >= _pageSize);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final billHistoryProvider = StateNotifierProvider.autoDispose
    .family<BillHistoryNotifier, BillHistoryState, BillHistoryKind>(
  BillHistoryNotifier.new,
);
