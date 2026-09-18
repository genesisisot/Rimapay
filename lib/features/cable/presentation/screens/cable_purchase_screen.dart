import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';
import '../../../bills/data/bills_dtos.dart';
import '../../../bills/presentation/providers/bills_providers.dart';
import '../../../bills/presentation/widgets/bill_purchase_flow.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class CableProvider {
  final String id;
  final int billerId;
  final String name;

  /// Bundled brand asset, when we have one for this provider.
  final String? icon;
  final String? logoUrl;

  const CableProvider({
    required this.id,
    required this.billerId,
    required this.name,
    this.icon,
    this.logoUrl,
  });

  factory CableProvider.fromBiller(BillerDto b) => CableProvider(
        id: '${b.billerId}',
        billerId: b.billerId,
        name: b.displayName,
        icon: billerAssetFor(b),
        logoUrl: b.logoUrl,
      );
}

class CablePackage {
  final String id;
  final String name;
  final String channels;
  final String validity;
  final String price;
  final bool popular;
  final double amount;
  final bool isAmountFixed;

  const CablePackage({
    required this.id,
    required this.name,
    this.channels = '',
    this.validity = '',
    required this.price,
    this.popular = false,
    this.amount = 0,
    this.isAmountFixed = true,
  });

  factory CablePackage.fromItem(BillerItemDto i) => CablePackage(
        id: i.billerItemId,
        name: i.name ?? 'Package',
        price: formatBillAmount(i.amount),
        amount: i.amount,
        isAmountFixed: i.isAmountFixed,
      );

  String get subtitle =>
      [channels, validity].where((p) => p.isNotEmpty).join(' · ');
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CablePurchaseScreen extends ConsumerStatefulWidget {
  const CablePurchaseScreen({super.key});

  @override
  ConsumerState<CablePurchaseScreen> createState() => _CablePurchaseScreenState();
}

class _CablePurchaseScreenState extends ConsumerState<CablePurchaseScreen>
    with SingleTickerProviderStateMixin {
  CableProvider? _selectedProvider;
  CablePackage? _selectedPackage;

  final _cardController = TextEditingController();
  final _cardFocus = FocusNode();

  late AnimationController _processingController;

  @override
  void initState() {
    super.initState();
    _processingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _cardFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _processingController.dispose();
    _cardController.dispose();
    _cardFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _cardController.text.length >= 8 &&
      _selectedProvider != null &&
      _selectedPackage != null;

  List<CableProvider> get _providers {
    final billers =
        ref.read(billersByKindProvider(BillCategoryKind.cable)).valueOrNull?.billers ??
            const <BillerDto>[];
    return billers.map(CableProvider.fromBiller).toList();
  }

  void _handleNext() {
    final provider = _selectedProvider;
    final pkg = _selectedPackage;
    if (!_isFormValid || provider == null || pkg == null) return;
    final card = _cardController.text;
    runBillPurchase(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Cable TV'},
        {'label': 'Provider', 'value': provider.name},
        {'label': 'Package', 'value': pkg.name},
        {'label': 'Card No.', 'value': card},
        {'label': 'Amount', 'value': '₦${pkg.price}'},
      ],
      submit: (pin, sourceAccount) =>
          ref.read(billsApiServiceProvider).payBill(BillPaymentRequest(
                sourceAccount: sourceAccount,
                billerId: provider.billerId,
                billerItemId: pkg.id,
                customerId: card,
                amount: pkg.isAmountFixed ? null : pkg.amount,
                transactionPin: pin,
              )),
      successProps: (result) => SuccessScreenProps(
        transactionType: 'Cable TV',
        amount: pkg.price,
        recipient: '${provider.name} – $card',
        transactionId: result.transactionReference,
      ),
    );
  }

  void _showProviderSheet() {
    if (ref.read(billersByKindProvider(BillCategoryKind.cable)).isLoading) return;
    final providers = _providers;
    if (providers.isEmpty) {
      refreshBillers(ref, BillCategoryKind.cable);
      showBillError(context, 'No providers available right now. Retrying…');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CableProviderSheet(
        providers: providers,
        selected: _selectedProvider,
        onSelect: (p) {
          setState(() {
            _selectedProvider = p;
            _selectedPackage = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPackageSheet() {
    if (_selectedProvider == null) return;
    final itemsAsync = ref.read(billerItemsProvider(_selectedProvider!.billerId));
    if (itemsAsync.isLoading) return;
    final pkgs = (itemsAsync.valueOrNull ?? const <BillerItemDto>[])
        .map(CablePackage.fromItem)
        .toList();
    if (pkgs.isEmpty) {
      ref.invalidate(billerItemsProvider(_selectedProvider!.billerId));
      showBillError(context, 'No packages available right now. Retrying…');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackageSheet(
        providerName: _selectedProvider!.name,
        packages: pkgs,
        selected: _selectedPackage,
        onSelect: (pkg) {
          setState(() => _selectedPackage = pkg);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billersAsync = ref.watch(billersByKindProvider(BillCategoryKind.cable));
    final categoryId = billersAsync.valueOrNull?.categoryId;
    final limit = categoryId == null
        ? null
        : ref.watch(billLimitProvider(categoryId)).valueOrNull;
    final itemsLoading = _selectedProvider != null &&
        ref.watch(billerItemsProvider(_selectedProvider!.billerId)).isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const BillGreenHeader(
            title: 'Cable TV',
            subtitle: 'Pay cable TV subscriptions',
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
                  _CDropdownField(
                    label: billersAsync.isLoading
                        ? 'Loading providers…'
                        : 'Choose Provider',
                    value: _selectedProvider?.name,
                    leadingLogo: _selectedProvider?.icon,
                    onTap: _showProviderSheet,
                  ),
                  const SizedBox(height: 16),

                  // ── Smart card number ──
                  _CFloatingField(
                    controller: _cardController,
                    focusNode: _cardFocus,
                    label: 'Smart Card / IUC Number',
                    hint: 'Enter customer number',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    suffix: _selectedProvider?.icon != null
                        ? Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(_selectedProvider!.icon!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Package dropdown ──
                  _CDropdownField(
                    label: itemsLoading ? 'Loading packages…' : 'Choose Package',
                    value: _selectedPackage?.name,
                    sublabel: _selectedPackage != null
                        ? [
                            '₦${_selectedPackage!.price}',
                            _selectedPackage!.subtitle,
                          ].where((p) => p.isNotEmpty).join(' · ')
                        : null,
                    enabled: _selectedProvider != null,
                    onTap: _showPackageSheet,
                  ),

                  const SizedBox(height: 24),
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
          _CCta(
            enabled: _isFormValid,
            label: _selectedPackage != null
                ? 'Pay Cable TV — ₦${_selectedPackage!.price}'
                : 'Continue',
            onTap: _handleNext,
          ),
        ],
      ),
    );
  }
}

// ── Provider bottom sheet ─────────────────────────────────────────────────────

class _CableProviderSheet extends StatelessWidget {
  final List<CableProvider> providers;
  final CableProvider? selected;
  final void Function(CableProvider) onSelect;

  const _CableProviderSheet({
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
                Text('Choose Provider',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
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
                        final image = billerImage(asset: p.icon, url: p.logoUrl);
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).scaffoldBackgroundColor,
                            image: image == null
                                ? null
                                : DecorationImage(
                                    image: image,
                                    fit: BoxFit.cover,
                                    onError: (_, __) {},
                                  ),
                          ),
                          child: image == null
                              ? Center(
                                  child: Text(
                                    billerInitials(p.name),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF166C46)),
                                  ),
                                )
                              : null,
                        );
                      }),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(p.name,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.goldPrimary
                                    : Theme.of(context).colorScheme.onSurface)),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF166C46), size: 20),
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

// ── Package bottom sheet ──────────────────────────────────────────────────────

class _PackageSheet extends StatelessWidget {
  final String providerName;
  final List<CablePackage> packages;
  final CablePackage? selected;
  final void Function(CablePackage) onSelect;

  const _PackageSheet({
    required this.providerName,
    required this.packages,
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text('$providerName Packages',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).scaffoldBackgroundColor),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: packages.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 20, color: Theme.of(context).scaffoldBackgroundColor),
              itemBuilder: (_, i) {
                final pkg = packages[i];
                final isSelected = selected?.id == pkg.id;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(pkg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(pkg.name,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? AppColors.goldPrimary
                                              : Theme.of(context).colorScheme.onSurface)),
                                  if (pkg.popular) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('Popular',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Theme.of(context).cardColor,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(pkg.subtitle,
                                  style: TextStyle(
                                      fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₦${pkg.price}',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? AppColors.goldPrimary
                                        : Theme.of(context).colorScheme.onSurface)),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF166C46), size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────

class _CDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final String? sublabel;
  final String? leadingLogo;
  final bool enabled;
  final VoidCallback onTap;

  const _CDropdownField({
    required this.label,
    this.value,
    this.sublabel,
    this.leadingLogo,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    final leftPad = (hasValue && leadingLogo != null) ? 56.0 : 16.0;
    final hasSublabel = hasValue && sublabel != null && sublabel!.isNotEmpty;
    final fieldHeight = hasSublabel ? 70.0 : 60.0;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: fieldHeight,
        decoration: BoxDecoration(
          color: enabled ? Theme.of(context).cardColor : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !enabled
                ? Theme.of(context).dividerColor
                : hasValue
                    ? const Color(0xFF166C46).withOpacity(0.4)
                    : Theme.of(context).dividerColor,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
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
                    color: !enabled
                        ? Theme.of(context).dividerColor
                        : hasValue
                            ? const Color(0xFF166C46)
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  child: Text(label),
                ),
              ),
            ),
            if (hasValue)
              Positioned(
                left: leftPad,
                right: 48,
                top: 27,
                child: IgnorePointer(
                  child: Text(
                    value!,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (hasSublabel)
              Positioned(
                left: leftPad,
                right: 48,
                top: 46,
                child: IgnorePointer(
                  child: Text(
                    sublabel!,
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: !enabled
                      ? Theme.of(context).dividerColor
                      : hasValue
                          ? const Color(0xFF166C46)
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

// ── Floating label text field ─────────────────────────────────────────────────

class _CFloatingField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final Widget? suffix;

  const _CFloatingField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.suffix,
  });

  @override
  State<_CFloatingField> createState() => _CFloatingFieldState();
}

class _CFloatingFieldState extends State<_CFloatingField> {
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
                  ? const Color(0xFF166C46).withOpacity(0.4)
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
                  color: Theme.of(context).colorScheme.onSurface),
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

// ── CTA button ────────────────────────────────────────────────────────────────

class _CCta extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback? onTap;

  const _CCta({required this.enabled, required this.label, this.onTap});

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
                color: enabled ? Theme.of(context).cardColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
