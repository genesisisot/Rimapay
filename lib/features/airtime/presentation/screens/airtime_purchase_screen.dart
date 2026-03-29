import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

class NetworkProvider {
  final String id;
  final String name;
  final String code;
  final Color color;
  final Color bgColor;
  final String icon;
  final String? logo;

  NetworkProvider({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    required this.bgColor,
    required this.icon,
    this.logo,
  });
}

class RecentContact {
  final String id;
  final String name;
  final String number;
  final String initial;
  final String lastUsed;
  final String amount;

  RecentContact({
    required this.id,
    required this.name,
    required this.number,
    required this.initial,
    required this.lastUsed,
    required this.amount,
  });
}

enum PurchaseStep { form, processing }

class AirtimePurchaseScreen extends ConsumerStatefulWidget {
  const AirtimePurchaseScreen({super.key});

  @override
  ConsumerState<AirtimePurchaseScreen> createState() =>
      _AirtimePurchaseScreenState();
}

class _AirtimePurchaseScreenState
    extends ConsumerState<AirtimePurchaseScreen>
    with TickerProviderStateMixin {
  final _phoneController =
      TextEditingController(text: '08137954069');
  final _amountController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _amountFocus = FocusNode();

  late final AnimationController _processingController;

  NetworkProvider? _selectedNetwork;
  PurchaseStep _currentStep = PurchaseStep.form;
  int _selectedTab = 0;

  final List<NetworkProvider> _networks = [
    NetworkProvider(
      id: 'mtn',
      name: 'MTN',
      code: 'MTN',
      color: const Color(0xFFFFCC02),
      bgColor: const Color(0xFFFFF8E1),
      icon: '📶',
      logo: 'assets/images/Mtn.png',
    ),
    NetworkProvider(
      id: 'airtel',
      name: 'AIRTEL',
      code: 'AIRTEL',
      color: const Color(0xFFFF0000),
      bgColor: const Color(0xFFFFEBEE),
      icon: '📡',
      logo: 'assets/images/Airtel.png',
    ),
    NetworkProvider(
      id: 'glo',
      name: 'GLO',
      code: 'GLO',
      color: const Color(0xFF00A651),
      bgColor: const Color(0xFFE8F5E8),
      icon: '🌐',
      logo: 'assets/images/Glo.png',
    ),
    NetworkProvider(
      id: '9mobile',
      name: '9MOBILE',
      code: '9MOBILE',
      color: const Color(0xFF00A86B),
      bgColor: const Color(0xFFE8F6F3),
      icon: '📱',
      logo: 'assets/images/9mobile.png',
    ),
  ];

  final List<String> _quickAmounts = ['100', '500', '1000', '3000'];

  final List<RecentContact> _recentContacts = [
    RecentContact(
      id: '1',
      name: 'My Number',
      number: '08137954069',
      initial: 'M',
      lastUsed: '2 hours ago',
      amount: '₦1,000',
    ),
    RecentContact(
      id: '2',
      name: 'Adebayo Johnson',
      number: '08123456789',
      initial: 'A',
      lastUsed: 'Yesterday',
      amount: '₦500',
    ),
    RecentContact(
      id: '3',
      name: 'Sarah Williams',
      number: '08198765432',
      initial: 'S',
      lastUsed: '3 days ago',
      amount: '₦2,000',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _processingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _phoneController.addListener(_detectNetwork);
    _phoneFocus.addListener(() => setState(() {}));
    _amountFocus.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectNetwork();
    });
  }

  void _detectNetwork() {
    final phone = _phoneController.text.replaceAll(' ', '');
    if (phone.length < 4) return;
    final prefix = phone.substring(0, 4);
    final prefixMap = {
      'mtn': [
        '0803','0806','0810','0813','0814','0816','0903','0906','0913','0916'
      ],
      'glo': ['0805','0807','0815','0811','0905','0915'],
      'airtel': ['0802','0808','0812','0701','0902','0907','0901'],
      '9mobile': ['0809','0818','0817','0908','0909'],
    };

    NetworkProvider? found;
    for (final entry in prefixMap.entries) {
      if (entry.value.contains(prefix)) {
        found = _networks.firstWhere((n) => n.id == entry.key);
        break;
      }
    }
    if (found != _selectedNetwork) {
      setState(() => _selectedNetwork = found);
    }
  }

  bool get _isValid =>
      _phoneController.text.replaceAll(' ', '').length == 11 &&
      _amountController.text.isNotEmpty &&
      _selectedNetwork != null;

  void _showPinSheet() {
    if (!_isValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Airtime'},
        {'label': 'Network', 'value': _selectedNetwork!.name},
        {'label': 'Phone', 'value': _phoneController.text},
        {'label': 'Amount', 'value': '₦${_amountController.text}'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        _proceed();
      },
    );
  }

  Future<void> _proceed() async {
    if (!_isValid) return;
    HapticFeedback.lightImpact();
    try {
      final txProvider = ref.read(transactionProviders.notifier);
      await txProvider.processTransaction(
        type: TransactionType.airtime,
        amount: double.parse(_amountController.text),
        recipient: '${_selectedNetwork!.name} Airtime',
        description: _phoneController.text,
        network: _selectedNetwork!.name,
      );
    } catch (_) {}

    if (mounted) {
      context.pushReplacement('/success', extra: SuccessScreenProps(
        transactionType: 'Airtime Purchase',
        amount: _amountController.text,
        recipient: '${_selectedNetwork!.name} - ${_phoneController.text}',
      ));
    }
  }

  @override
  void dispose() {
    _processingController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _phoneFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == PurchaseStep.processing) {
      return _buildProcessing();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // ── Green header (no account card) ──
          BillGreenHeader(
            title: 'Mobile Top-Up',
            subtitle: 'Buy airtime and data bundles',
            showAccountCard: false,
            tabs: const ['Airtime', 'Data'],
            selectedTab: _selectedTab,
            onTabChanged: (i) {
              if (i == 1) {
                context.go('/bills/data');
              } else {
                setState(() => _selectedTab = 0);
              }
            },
          ),

          // ── Scrollable form ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Account Card (content area) ──
                  const BillAccountCard(),
                  const SizedBox(height: 10),
                  const BillPaginationDots(count: 2, active: 0),
                  const SizedBox(height: 20),

                  // ── Phone number (floating label) ──
                  _FloatingField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    label: 'Phone Number',
                    hint: '0801 234 5678',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    onChanged: (_) => setState(() {}),
                    suffix: _selectedNetwork != null
                        ? Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: _selectedNetwork!.bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _selectedNetwork!.icon,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // ── Frequent Beneficiaries ──
                  const Text(
                    'Frequent Beneficiaries',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentContacts.length,
                      itemBuilder: (_, i) {
                        final c = _recentContacts[i];
                        final colors = [
                          const Color(0xFF00B252),
                          const Color(0xFF7C3AED),
                          const Color(0xFFEF4444),
                          const Color(0xFFF59E0B),
                        ];
                        final bgColor = colors[i % colors.length];
                        return GestureDetector(
                          onTap: () => setState(() {
                            _phoneController.text = c.number;
                            _detectNetwork();
                          }),
                          child: Container(
                            margin: EdgeInsets.only(
                                right: i == _recentContacts.length - 1
                                    ? 0
                                    : 12),
                            width: 72,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: bgColor,
                                  child: Text(
                                    c.initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  c.number.substring(0, 7) + '...',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Network selection ──
                  const Text(
                    'Choose Network',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _networks.asMap().entries.map((e) {
                      final network = e.value;
                      final isSelected =
                          _selectedNetwork?.id == network.id;
                      final isLast = e.key == _networks.length - 1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _selectedNetwork = network),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin:
                                EdgeInsets.only(right: isLast ? 0 : 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? network.bgColor
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? network.color
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(network.icon,
                                    style:
                                        const TextStyle(fontSize: 20)),
                                const SizedBox(height: 4),
                                Text(
                                  network.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? network.color
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Quick Select Amount ──
                  const Text(
                    'Quick Select Amount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _quickAmounts.asMap().entries.map((e) {
                      final amt = e.value;
                      final isLast = e.key == _quickAmounts.length - 1;
                      final isSelected =
                          _amountController.text == amt;
                      final label = int.parse(amt) >= 1000
                          ? '₦${int.parse(amt) ~/ 1000},000'
                          : '₦$amt';
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _amountController.text = amt;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin:
                                EdgeInsets.only(right: isLast ? 0 : 8),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00B252)
                                    : const Color(0xFFE5E7EB),
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
                                      ? const Color(0xFF00B252)
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Enter Amount ──
                  const Text(
                    'Enter Amount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AmountInputCard(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20),

                  // ── Daily Limit Card ──
                  const BillDailyLimitCard(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── Fixed CTA ──
          _AirtimeCTA(
            enabled: _isValid,
            amount: _amountController.text,
            onTap: _showPinSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _processingController,
          builder: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle:
                    _processingController.value * 2 * 3.14159,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we process your payment',
                style: TextStyle(
                    fontSize: 14, color: Color(0xFF667085)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Floating Label Input Field ────────────────────────────────────────────────

class _FloatingField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final Widget? suffix;

  const _FloatingField({
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
  State<_FloatingField> createState() => _FloatingFieldState();
}

class _FloatingFieldState extends State<_FloatingField> {
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
              ? const Color(0xFF00B252)
              : _hasValue
                  ? const Color(0xFF00B252).withOpacity(0.4)
                  : const Color(0xFFE4E7EC),
          width: _focused ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Floating label — slides up when active
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
                      ? const Color(0xFF00B252)
                      : const Color(0xFF9CA3AF),
                ),
                child: Text(widget.label),
              ),
            ),
          ),
          // TextField — sits in the lower portion when label is floating
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
                color: Color(0xFF101828),
              ),
              decoration: InputDecoration(
                hintText: isActive ? widget.hint : null,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFD0D5DD),
                  fontWeight: FontWeight.normal,
                ),
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
          // Suffix
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

// ── Amount Input Card ────────────────────────────────────────────────────────

class _AmountInputCard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String)? onChanged;

  const _AmountInputCard({
    required this.controller,
    required this.focusNode,
    this.onChanged,
  });

  @override
  State<_AmountInputCard> createState() => _AmountInputCardState();
}

class _AmountInputCardState extends State<_AmountInputCard> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _focused ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? const Color(0xFF00B252) : const Color(0xFFE5E7EB),
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
                Text(
                  '₦',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _focused
                        ? const Color(0xFF111827)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    onChanged: widget.onChanged,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 36,
                        color: Color(0xFFD1D5DB),
                        fontWeight: FontWeight.w300,
                      ),
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
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  'Min: ₦50, Max: ₦50,000',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Airtime CTA Button ────────────────────────────────────────────────────────

class _AirtimeCTA extends StatelessWidget {
  final bool enabled;
  final String amount;
  final VoidCallback? onTap;

  const _AirtimeCTA({
    required this.enabled,
    required this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = amount.isNotEmpty
        ? 'Buy Airtime — ₦$amount'
        : 'Continue';

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
                ? const LinearGradient(
                    colors: [Color(0xFF00B252), Color(0xFF00A651)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: enabled ? null : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
