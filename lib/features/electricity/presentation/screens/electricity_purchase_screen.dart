import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';
import '../../../bills/data/bills_dtos.dart';
import '../../../bills/presentation/providers/bills_providers.dart';
import '../../../bills/presentation/widgets/bill_purchase_flow.dart';

import '../../../../core/localization/l10n.dart';
class ElectricityProvider {
  final String id;
  final int billerId;
  final String name;
  final String shortName;

  /// Bundled brand asset, when we have one for this disco.
  final String? logo;
  final String? logoUrl;
  final Color color;
  final Color bgColor;

  ElectricityProvider({
    required this.id,
    required this.billerId,
    required this.name,
    required this.shortName,
    this.logo,
    this.logoUrl,
    required this.color,
    required this.bgColor,
  });

  static const _palette = [
    (Color(0xFF3B82F6), Color(0xFFEBF8FF)),
    (Color(0xFFF97316), Color(0xFFFFF7ED)),
    (Color(0xFFEAB308), Color(0xFFFEFCE8)),
    (Color(0xFF166C46), Color(0xFFF2F7F3)),
    (Color(0xFF8B5CF6), Color(0xFFF3E8FF)),
    (Color(0xFFD33B31), Color(0xFFFEF2F2)),
  ];

  factory ElectricityProvider.fromBiller(BillerDto b, int index) {
    final colors = _palette[index % _palette.length];
    return ElectricityProvider(
      id: '${b.billerId}',
      billerId: b.billerId,
      name: b.name ?? b.displayName,
      shortName: b.displayName,
      logo: billerAssetFor(b),
      logoUrl: b.logoUrl,
      color: colors.$1,
      bgColor: colors.$2,
    );
  }
}

enum MeterType { prepaid, postpaid }

class ElectricityPurchaseScreen extends ConsumerStatefulWidget {
  const ElectricityPurchaseScreen({super.key});

  @override
  ConsumerState<ElectricityPurchaseScreen> createState() =>
      _ElectricityPurchaseScreenState();
}

class _ElectricityPurchaseScreenState
    extends ConsumerState<ElectricityPurchaseScreen>
    with TickerProviderStateMixin {
  ElectricityProvider? _selectedProvider;
  String _amount = '';
  String _meterNumber = '';
  MeterType _meterType = MeterType.prepaid;

  final _meterController = TextEditingController();
  final _customAmountController = TextEditingController();
  final _meterFocus = FocusNode();
  final _amountFocus = FocusNode();

  late AnimationController _processingController;

  final List<String> _quickAmounts = ['1000', '2000', '5000', '10000'];

  @override
  void initState() {
    super.initState();
    _processingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _meterFocus.addListener(() => setState(() {}));
    _amountFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _processingController.dispose();
    _meterController.dispose();
    _customAmountController.dispose();
    _meterFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  List<ElectricityProvider> get _providers {
    final billers = ref
            .read(billersByKindProvider(BillCategoryKind.electricity))
            .valueOrNull
            ?.billers ??
        const <BillerDto>[];
    return [
      for (var i = 0; i < billers.length; i++)
        ElectricityProvider.fromBiller(billers[i], i),
    ];
  }

  List<BillerItemDto> get _items => _selectedProvider == null
      ? const []
      : ref.read(billerItemsProvider(_selectedProvider!.billerId)).valueOrNull ??
          const [];

  /// Payment item matching the Prepaid/Postpaid toggle (first item as fallback).
  BillerItemDto? get _selectedItem {
    final items = _items;
    if (items.isEmpty) return null;
    final key = _meterType == MeterType.prepaid ? 'prepaid' : 'postpaid';
    for (final item in items) {
      if ((item.name ?? '').toLowerCase().contains(key)) return item;
    }
    return items.first;
  }

  double get _amountValue => double.tryParse(_amount.replaceAll(',', '')) ?? 0;

  bool get _isFormValid =>
      _selectedProvider != null &&
      _selectedItem != null &&
      _meterNumber.length >= 10 &&
      _amountValue > 0;

  void _handleNext() {
    final provider = _selectedProvider;
    final item = _selectedItem;
    if (!_isFormValid || provider == null || item == null) return;
    final meter = _meterNumber;
    final amountText = _amount;
    final amount = _amountValue;
    runBillPurchase(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Electricity Bill'},
        {'label': 'Provider', 'value': provider.shortName},
        {'label': 'Meter', 'value': meter},
        {
          'label': 'Type',
          'value': item.name ?? (_meterType == MeterType.prepaid ? 'Prepaid' : 'Postpaid'),
        },
        {'label': 'Amount', 'value': '₦$amountText'},
      ],
      submit: (pin, sourceAccount) =>
          ref.read(billsApiServiceProvider).payBill(BillPaymentRequest(
                sourceAccount: sourceAccount,
                billerId: provider.billerId,
                billerItemId: item.billerItemId,
                customerId: meter,
                amount: amount,
                transactionPin: pin,
              )),
      successProps: (result) => SuccessScreenProps(
        transactionType: 'Electricity Bill',
        amount: amountText,
        recipient: '${provider.shortName} – $meter',
        transactionId: result.transactionReference,
      ),
    );
  }

  void _showProviderSheet() {
    if (ref.read(billersByKindProvider(BillCategoryKind.electricity)).isLoading) return;
    final providers = _providers;
    if (providers.isEmpty) {
      refreshBillers(ref, BillCategoryKind.electricity);
      showBillError(context, 'No providers available right now. Retrying…');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProviderSheet(
        providers: providers,
        selected: _selectedProvider,
        onSelect: (p) {
          setState(() => _selectedProvider = p);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billersAsync =
        ref.watch(billersByKindProvider(BillCategoryKind.electricity));
    final categoryId = billersAsync.valueOrNull?.categoryId;
    final limit = categoryId == null
        ? null
        : ref.watch(billLimitProvider(categoryId)).valueOrNull;
    if (_selectedProvider != null) {
      ref.watch(billerItemsProvider(_selectedProvider!.billerId));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          BillGreenHeader(
            title: context.l10n.electricity,
            subtitle: context.l10n.payElectricityBills,
            showAccountCard: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BillAccountCard(),
                  const SizedBox(height: 10),
                  const BillPaginationDots(count: 1, active: 0),
                  const SizedBox(height: 24),

                  // ── Provider dropdown ──
                  _DropdownField(
                    label: billersAsync.isLoading
                        ? 'Loading providers…'
                        : 'Choose Provider',
                    value: _selectedProvider?.name,
                    leadingLogo: _selectedProvider?.logo,
                    onTap: _showProviderSheet,
                  ),
                  const SizedBox(height: 16),

                  // ── Meter type toggle ──
                  Row(
                    children: [
                      _MeterTypeBtn(
                        label: context.l10n.prepaid,
                        icon: '🔋',
                        selected: _meterType == MeterType.prepaid,
                        onTap: () => setState(() => _meterType = MeterType.prepaid),
                      ),
                      const SizedBox(width: 10),
                      _MeterTypeBtn(
                        label: context.l10n.postpaid,
                        icon: '📄',
                        selected: _meterType == MeterType.postpaid,
                        onTap: () => setState(() => _meterType = MeterType.postpaid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Meter number floating field ──
                  _EFloatingField(
                    controller: _meterController,
                    focusNode: _meterFocus,
                    label: context.l10n.meterNumber,
                    hint: 'Enter 11-digit meter number',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => setState(() => _meterNumber = v),
                  ),

                  const SizedBox(height: 24),

                  // ── Quick amounts ──
                  Text(context.l10n.quickSelectAmount,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _quickAmounts.asMap().entries.map((e) {
                      final amt = e.value;
                      final isLast = e.key == _quickAmounts.length - 1;
                      final isSelected = _amount == amt;
                      final label = int.parse(amt) >= 1000
                          ? '₦${(int.parse(amt) ~/ 1000)},000'
                          : '₦$amt';
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _amount = amt;
                            _customAmountController.text = amt;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(right: isLast ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                                  : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.goldPrimary
                                    : Theme.of(context).dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.goldPrimary
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  Text(context.l10n.enterAmount,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 10),
                  _AmountCard(
                    controller: _customAmountController,
                    focusNode: _amountFocus,
                    onChanged: (v) => setState(() => _amount = v),
                    minMax: 'Min: ₦1,000 · Max: ₦100,000',
                  ),

                  const SizedBox(height: 20),
                  BillDailyLimitCard(
                    dailyLimit: limit?.dailyLimit,
                    remaining: limit?.remainingLimit,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── CTA ──
          _BillCTA(
            enabled: _isFormValid,
            label: _amount.isNotEmpty ? 'Pay Electricity — ₦$_amount' : 'Continue',
            onTap: _handleNext,
          ),
        ],
      ),
    );
  }
}

// ── Provider bottom sheet ─────────────────────────────────────────────────────

class _ProviderSheet extends StatelessWidget {
  final List<ElectricityProvider> providers;
  final ElectricityProvider? selected;
  final void Function(ElectricityProvider) onSelect;

  const _ProviderSheet({
    required this.providers,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text(context.l10n.chooseProvider,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).scaffoldBackgroundColor),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: providers.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 68, color: Theme.of(context).scaffoldBackgroundColor),
            itemBuilder: (_, i) {
              final p = providers[i];
              final isSelected = selected?.id == p.id;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(p),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Builder(builder: (context) {
                        final image = billerImage(asset: p.logo, url: p.logoUrl);
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: image == null
                                ? null
                                : DecorationImage(
                                    image: image,
                                    fit: BoxFit.cover,
                                    onError: (_, __) {},
                                  ),
                            color: Theme.of(context).brightness == Brightness.dark ? p.color.withOpacity(0.15) : p.bgColor,
                          ),
                          child: image == null
                              ? Center(
                                  child: Text(
                                    billerInitials(p.shortName),
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: p.color),
                                  ),
                                )
                              : null,
                        );
                      }),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.shortName,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.goldPrimary
                                        : Theme.of(context).colorScheme.onSurface)),
                            Text(p.name,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.goldPrimary, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ── Dropdown field (tap-to-open) ──────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final String? leadingLogo;
  final VoidCallback onTap;

  const _DropdownField({
    required this.label,
    this.value,
    this.leadingLogo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    final leftPad = (hasValue && leadingLogo != null) ? 56.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? AppColors.goldPrimary.withOpacity(0.4)
                : Theme.of(context).dividerColor,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Leading logo
            if (hasValue && leadingLogo != null)
              Positioned(
                left: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          image: AssetImage(leadingLogo!), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            // Floating label
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              top: hasValue ? 9 : 20,
              left: leftPad,
              right: 48,
              child: IgnorePointer(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontSize: hasValue ? 11 : 15,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: hasValue
                        ? AppColors.goldPrimary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  child: Text(label),
                ),
              ),
            ),
            // Value
            if (hasValue)
              Positioned(
                left: leftPad,
                right: 48,
                top: 28,
                bottom: 6,
                child: IgnorePointer(
                  child: Text(
                    value!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // Chevron
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasValue
                      ? AppColors.goldPrimary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meter type toggle button ──────────────────────────────────────────────────

class _MeterTypeBtn extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _MeterTypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.surface.withOpacity(0.5) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.goldPrimary : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.goldPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Floating label text field ─────────────────────────────────────────────────

class _EFloatingField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final Widget? suffix = null;

  const _EFloatingField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  State<_EFloatingField> createState() => _EFloatingFieldState();
}

class _EFloatingFieldState extends State<_EFloatingField> {
  bool _focused = false;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
    _hasValue = widget.controller.text.isNotEmpty;
    widget.focusNode.addListener(_onFocus);
    widget.controller.addListener(_onValue);
  }

  void _onFocus() => setState(() => _focused = widget.focusNode.hasFocus);
  void _onValue() {
    final v = widget.controller.text.isNotEmpty;
    if (v != _hasValue) setState(() => _hasValue = v);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    widget.controller.removeListener(_onValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _focused || _hasValue;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused
              ? AppColors.goldPrimary
              : _hasValue
                  ? AppColors.goldPrimary.withOpacity(0.4)
                  : Theme.of(context).dividerColor,
          width: _focused ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            top: isActive ? 9 : 20,
            left: 16,
            right: widget.suffix != null ? 52 : 16,
            child: IgnorePointer(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: isActive ? 11 : 15,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: isActive
                      ? AppColors.goldPrimary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                child: Text(widget.label),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: widget.suffix != null ? 48 : 14,
            top: isActive ? 28 : 18,
            bottom: 6,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: isActive ? widget.hint : null,
                hintStyle: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).dividerColor,
                    fontWeight: FontWeight.normal),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.suffix != null)
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(child: widget.suffix!),
            ),
        ],
      ),
    );
  }
}

// ── Amount input card ─────────────────────────────────────────────────────────

class _AmountCard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String)? onChanged;
  final String minMax;

  const _AmountCard({
    required this.controller,
    required this.focusNode,
    this.onChanged,
    required this.minMax,
  });

  @override
  State<_AmountCard> createState() => _AmountCardState();
}

class _AmountCardState extends State<_AmountCard> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() => _focused = widget.focusNode.hasFocus));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _focused ? Theme.of(context).cardColor : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? AppColors.goldPrimary : Theme.of(context).dividerColor,
          width: _focused ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('₦',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                    color: _focused
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CommaFormatter()],
                    onChanged: widget.onChanged,
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                          fontSize: 36,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          fontWeight: FontWeight.w300),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text(widget.minMax,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA button ────────────────────────────────────────────────────────────────

class _BillCTA extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback? onTap;

  const _BillCTA({required this.enabled, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).scaffoldBackgroundColor)),
      ),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? AppColors.goldGradient
                : null,
            color: enabled ? null : Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
