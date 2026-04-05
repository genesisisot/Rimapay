import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class CableProvider {
  final String id;
  final String name;
  final String icon;

  const CableProvider({required this.id, required this.name, required this.icon});
}

class CablePackage {
  final String id;
  final String name;
  final String channels;
  final String validity;
  final String price;
  final bool popular;

  const CablePackage({
    required this.id,
    required this.name,
    required this.channels,
    required this.validity,
    required this.price,
    this.popular = false,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CablePurchaseScreen extends StatefulWidget {
  const CablePurchaseScreen({super.key});

  @override
  State<CablePurchaseScreen> createState() => _CablePurchaseScreenState();
}

class _CablePurchaseScreenState extends State<CablePurchaseScreen>
    with SingleTickerProviderStateMixin {
  CableProvider? _selectedProvider;
  CablePackage? _selectedPackage;

  final _cardController = TextEditingController();
  final _cardFocus = FocusNode();

  late AnimationController _processingController;

  final List<CableProvider> _providers = const [
    CableProvider(id: 'dstv', name: 'DSTV', icon: 'assets/images/Dstv.jpeg'),
    CableProvider(id: 'gotv', name: 'GOTV', icon: 'assets/images/Gotv.jpeg'),
    CableProvider(id: 'startimes', name: 'StarTimes', icon: 'assets/images/Startimes.jpeg'),
    CableProvider(id: 'showmax', name: 'Showmax', icon: 'assets/images/Showmax.png'),
  ];

  final Map<String, List<CablePackage>> _packages = const {
    'dstv': [
      CablePackage(id: 'dstv_access', name: 'DStv Access', channels: '95+ Channels', validity: '1 Month', price: '2,950'),
      CablePackage(id: 'dstv_family', name: 'DStv Family', channels: '120+ Channels', validity: '1 Month', price: '4,615'),
      CablePackage(id: 'dstv_compact', name: 'DStv Compact', channels: '180+ Channels', validity: '1 Month', price: '9,000', popular: true),
      CablePackage(id: 'dstv_compact_plus', name: 'DStv Compact Plus', channels: '230+ Channels', validity: '1 Month', price: '14,250', popular: true),
      CablePackage(id: 'dstv_premium', name: 'DStv Premium', channels: '280+ Channels', validity: '1 Month', price: '21,000'),
      CablePackage(id: 'dstv_confam', name: 'DStv Confam', channels: '105+ Channels', validity: '1 Month', price: '5,500'),
      CablePackage(id: 'dstv_yanga', name: 'DStv Yanga', channels: '85+ Channels', validity: '1 Month', price: '2,565'),
    ],
    'gotv': [
      CablePackage(id: 'gotv_lite', name: 'GOtv Lite', channels: '35+ Channels', validity: '1 Month', price: '610'),
      CablePackage(id: 'gotv_smallie', name: 'GOtv Smallie', channels: '25+ Channels', validity: '1 Month', price: '900'),
      CablePackage(id: 'gotv_jinja', name: 'GOtv Jinja', channels: '45+ Channels', validity: '1 Month', price: '1,900'),
      CablePackage(id: 'gotv_jolli', name: 'GOtv Jolli', channels: '65+ Channels', validity: '1 Month', price: '2,800', popular: true),
      CablePackage(id: 'gotv_max', name: 'GOtv Max', channels: '75+ Channels', validity: '1 Month', price: '4,150', popular: true),
      CablePackage(id: 'gotv_supa', name: 'GOtv Supa', channels: '85+ Channels', validity: '1 Month', price: '5,500'),
    ],
    'startimes': [
      CablePackage(id: 'st_nova', name: 'Nova', channels: '35+ Channels', validity: '1 Month', price: '900'),
      CablePackage(id: 'st_basic', name: 'Basic', channels: '50+ Channels', validity: '1 Month', price: '1,700', popular: true),
      CablePackage(id: 'st_smart', name: 'Smart', channels: '65+ Channels', validity: '1 Month', price: '2,500'),
      CablePackage(id: 'st_classic', name: 'Classic', channels: '80+ Channels', validity: '1 Month', price: '2,750', popular: true),
      CablePackage(id: 'st_super', name: 'Super', channels: '95+ Channels', validity: '1 Month', price: '4,200'),
    ],
    'showmax': [
      CablePackage(id: 'sm_mobile', name: 'Mobile', channels: 'Mobile Only', validity: '1 Month', price: '1,200'),
      CablePackage(id: 'sm_standard', name: 'Standard', channels: '2 Devices', validity: '1 Month', price: '2,900', popular: true),
      CablePackage(id: 'sm_pro', name: 'Pro', channels: '4 Devices + Sports', validity: '1 Month', price: '6,300'),
      CablePackage(id: 'sm_sport', name: 'Sport Add-on', channels: 'Live Sports', validity: '1 Month', price: '3,200'),
    ],
  };

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

  void _handleNext() {
    if (!_isFormValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Cable TV'},
        if (_selectedProvider != null) {'label': 'Provider', 'value': _selectedProvider!.name},
        if (_selectedPackage != null) {'label': 'Package', 'value': _selectedPackage!.name},
        {'label': 'Card No.', 'value': _cardController.text},
        if (_selectedPackage != null) {'label': 'Amount', 'value': '₦${_selectedPackage!.price}'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        context.pushReplacement('/success', extra: SuccessScreenProps(
          transactionType: 'Cable TV',
          amount: _selectedPackage?.price ?? '0',
          recipient: '${_selectedProvider?.name} – ${_cardController.text}',
        ));
      },
    );
  }

  void _showProviderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CableProviderSheet(
        providers: _providers,
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
    final pkgs = _packages[_selectedProvider!.id] ?? [];
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                    label: 'Choose Provider',
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
                    suffix: _selectedProvider != null
                        ? Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(_selectedProvider!.icon),
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
                    label: 'Choose Package',
                    value: _selectedPackage?.name,
                    sublabel: _selectedPackage != null
                        ? '₦${_selectedPackage!.price} · ${_selectedPackage!.channels}'
                        : null,
                    enabled: _selectedProvider != null,
                    onTap: _showPackageSheet,
                  ),

                  const SizedBox(height: 24),
                  const BillDailyLimitCard(),
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text('Choose Provider',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: providers.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 68, color: Color(0xFFF3F4F6)),
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              image: AssetImage(p.icon), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(p.name,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.goldPrimary
                                    : const Color(0xFF101828))),
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text('$providerName Packages',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: packages.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, color: Color(0xFFF3F4F6)),
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
                                              : const Color(0xFF101828))),
                                  if (pkg.popular) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Popular',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('${pkg.channels} · ${pkg.validity}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF6B7280))),
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
                                        : const Color(0xFF101828))),
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
          color: enabled ? Colors.white : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !enabled
                ? const Color(0xFFE4E7EC)
                : hasValue
                    ? const Color(0xFF166C46).withOpacity(0.4)
                    : const Color(0xFFE4E7EC),
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
                        ? const Color(0xFFD0D5DD)
                        : hasValue
                            ? const Color(0xFF166C46)
                            : const Color(0xFF9CA3AF),
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
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828)),
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
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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
                      ? const Color(0xFFD0D5DD)
                      : hasValue
                          ? const Color(0xFF166C46)
                          : const Color(0xFF9CA3AF),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused
              ? AppColors.goldPrimary
              : _hasValue
                  ? const Color(0xFF166C46).withOpacity(0.4)
                  : const Color(0xFFE4E7EC),
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
                      : const Color(0xFF9CA3AF),
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
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101828)),
              decoration: InputDecoration(
                hintText: isActive ? widget.hint : null,
                hintStyle: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFD0D5DD),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
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
            color: enabled ? null : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
