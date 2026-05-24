import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

// ── Data Models ───────────────────────────────────────────────────────────────

enum PlanCategory { daily, weekly, monthly }

class DataPlan {
  final String id;
  final String data;
  final String validity;
  final String price;
  final PlanCategory category;

  const DataPlan({
    required this.id,
    required this.data,
    required this.validity,
    required this.price,
    required this.category,
  });
}

class NetworkProvider {
  final String id;
  final String name;
  final Color color;
  final Color bgColor;
  final String icon;

  const NetworkProvider({
    required this.id,
    required this.name,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}

class _Contact {
  final String name;
  final String number;
  final String initial;
  const _Contact(this.name, this.number, this.initial);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AirtimePurchaseScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const AirtimePurchaseScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AirtimePurchaseScreen> createState() =>
      _AirtimePurchaseScreenState();
}

class _AirtimePurchaseScreenState extends ConsumerState<AirtimePurchaseScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────
  final _phoneController = TextEditingController(text: '08137954069');
  final _amountController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _amountFocus = FocusNode();

  late final AnimationController _processingController;

  // ── Shared state ─────────────────────────────────────────────────────────
  late int _selectedTab; // 0 = Airtime, 1 = Data
  NetworkProvider? _selectedNetwork;

  // ── Airtime state ─────────────────────────────────────────────────────────
  final List<String> _quickAmounts = ['100', '500', '1000', '3000'];

  // ── Data state ────────────────────────────────────────────────────────────
  DataPlan? _selectedPlan;
  PlanCategory _planCategory = PlanCategory.monthly;

  // ── Static data ───────────────────────────────────────────────────────────
  static const _networks = [
    NetworkProvider(
        id: 'mtn', name: 'MTN', color: Color(0xFFFFCC02), bgColor: Color(0xFFFFF8E1), icon: '📶'),
    NetworkProvider(
        id: 'airtel', name: 'AIRTEL', color: Color(0xFFFF0000), bgColor: Color(0xFFFFEBEE), icon: '📡'),
    NetworkProvider(
        id: 'glo', name: 'GLO', color: Color(0xFF166C46), bgColor: Color(0xFFF2F7F3), icon: '🌐'),
    NetworkProvider(
        id: '9mobile', name: '9MOBILE', color: Color(0xFF00A86B), bgColor: Color(0xFFE8F6F3), icon: '📱'),
  ];

  static const _contacts = [
    _Contact('My Number', '08137954069', 'M'),
    _Contact('Adebayo Johnson', '08123456789', 'A'),
    _Contact('Sarah Williams', '08198765432', 'S'),
  ];

  static const Map<String, List<DataPlan>> _dataPlans = {
    'mtn': [
      DataPlan(id: 'mtn_d1', data: '1GB', validity: '1 Day', price: '300', category: PlanCategory.daily),
      DataPlan(id: 'mtn_d2', data: '2GB', validity: '1 Day', price: '500', category: PlanCategory.daily),
      DataPlan(id: 'mtn_d3', data: '3GB', validity: '1 Day', price: '750', category: PlanCategory.daily),
      DataPlan(id: 'mtn_w1', data: '1.5GB', validity: '7 Days', price: '1,200', category: PlanCategory.weekly),
      DataPlan(id: 'mtn_w2', data: '3GB', validity: '7 Days', price: '2,000', category: PlanCategory.weekly),
      DataPlan(id: 'mtn_w3', data: '7GB', validity: '7 Days', price: '3,500', category: PlanCategory.weekly),
      DataPlan(id: 'mtn_m1', data: '2GB', validity: '30 Days', price: '1,500', category: PlanCategory.monthly),
      DataPlan(id: 'mtn_m2', data: '5GB', validity: '30 Days', price: '2,500', category: PlanCategory.monthly),
      DataPlan(id: 'mtn_m3', data: '10GB', validity: '30 Days', price: '4,000', category: PlanCategory.monthly),
      DataPlan(id: 'mtn_m4', data: '20GB', validity: '30 Days', price: '8,000', category: PlanCategory.monthly),
      DataPlan(id: 'mtn_m5', data: '40GB', validity: '30 Days', price: '15,000', category: PlanCategory.monthly),
    ],
    'airtel': [
      DataPlan(id: 'a_d1', data: '1GB', validity: '1 Day', price: '300', category: PlanCategory.daily),
      DataPlan(id: 'a_d2', data: '2GB', validity: '1 Day', price: '500', category: PlanCategory.daily),
      DataPlan(id: 'a_w1', data: '1.5GB', validity: '7 Days', price: '1,200', category: PlanCategory.weekly),
      DataPlan(id: 'a_w2', data: '4GB', validity: '7 Days', price: '2,000', category: PlanCategory.weekly),
      DataPlan(id: 'a_m1', data: '2GB', validity: '30 Days', price: '1,500', category: PlanCategory.monthly),
      DataPlan(id: 'a_m2', data: '6GB', validity: '30 Days', price: '2,500', category: PlanCategory.monthly),
      DataPlan(id: 'a_m3', data: '12GB', validity: '30 Days', price: '4,000', category: PlanCategory.monthly),
      DataPlan(id: 'a_m4', data: '20GB', validity: '30 Days', price: '8,000', category: PlanCategory.monthly),
    ],
    'glo': [
      DataPlan(id: 'g_d1', data: '1GB', validity: '1 Day', price: '300', category: PlanCategory.daily),
      DataPlan(id: 'g_d2', data: '2GB', validity: '1 Day', price: '500', category: PlanCategory.daily),
      DataPlan(id: 'g_w1', data: '2GB', validity: '7 Days', price: '1,200', category: PlanCategory.weekly),
      DataPlan(id: 'g_w2', data: '5GB', validity: '7 Days', price: '2,000', category: PlanCategory.weekly),
      DataPlan(id: 'g_m1', data: '3GB', validity: '30 Days', price: '1,500', category: PlanCategory.monthly),
      DataPlan(id: 'g_m2', data: '8GB', validity: '30 Days', price: '2,500', category: PlanCategory.monthly),
      DataPlan(id: 'g_m3', data: '15GB', validity: '30 Days', price: '4,000', category: PlanCategory.monthly),
      DataPlan(id: 'g_m4', data: '25GB', validity: '30 Days', price: '8,000', category: PlanCategory.monthly),
    ],
    '9mobile': [
      DataPlan(id: 'n_d1', data: '1GB', validity: '1 Day', price: '300', category: PlanCategory.daily),
      DataPlan(id: 'n_d2', data: '2GB', validity: '1 Day', price: '500', category: PlanCategory.daily),
      DataPlan(id: 'n_w1', data: '1.5GB', validity: '7 Days', price: '1,200', category: PlanCategory.weekly),
      DataPlan(id: 'n_w2', data: '3GB', validity: '7 Days', price: '2,000', category: PlanCategory.weekly),
      DataPlan(id: 'n_m1', data: '2GB', validity: '30 Days', price: '1,500', category: PlanCategory.monthly),
      DataPlan(id: 'n_m2', data: '5GB', validity: '30 Days', price: '2,500', category: PlanCategory.monthly),
      DataPlan(id: 'n_m3', data: '11GB', validity: '30 Days', price: '4,000', category: PlanCategory.monthly),
      DataPlan(id: 'n_m4', data: '15GB', validity: '30 Days', price: '8,000', category: PlanCategory.monthly),
    ],
  };

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _processingController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
    _phoneController.addListener(_detectNetwork);
    _phoneFocus.addListener(() => setState(() {}));
    _amountFocus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectNetwork());
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

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _detectNetwork() {
    final phone = _phoneController.text.replaceAll(' ', '');
    if (phone.length < 4) return;
    final prefix = phone.substring(0, 4);
    const prefixMap = {
      'mtn': ['0803','0806','0810','0813','0814','0816','0903','0906','0913','0916'],
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
    if (found != _selectedNetwork) setState(() => _selectedNetwork = found);
  }

  List<DataPlan> get _currentPlans {
    if (_selectedNetwork == null) return [];
    return (_dataPlans[_selectedNetwork!.id] ?? [])
        .where((p) => p.category == _planCategory)
        .toList();
  }

  bool get _airtimeValid =>
      _phoneController.text.replaceAll(' ', '').length == 11 &&
      _amountController.text.isNotEmpty &&
      _selectedNetwork != null;

  bool get _dataValid =>
      _phoneController.text.replaceAll(' ', '').length == 11 &&
      _selectedPlan != null &&
      _selectedNetwork != null;

  // ── Actions ───────────────────────────────────────────────────────────────
  void _buyAirtime() {
    if (!_airtimeValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Airtime'},
        {'label': 'Network', 'value': _selectedNetwork!.name},
        {'label': 'Phone', 'value': _phoneController.text},
        {'label': 'Amount', 'value': '₦${_amountController.text}'},
      ],
      onConfirmed: (_) async {
        Navigator.pop(context);
        try {
          await ref.read(transactionProviders.notifier).processTransaction(
            type: TransactionType.airtime,
            amount: double.parse(_amountController.text),
            recipient: '${_selectedNetwork!.name} Airtime',
            description: _phoneController.text,
            network: _selectedNetwork!.name,
          );
        } catch (_) {}
        if (mounted) {
          context.pushReplacement('/success',
              extra: SuccessScreenProps(
                transactionType: 'Airtime Purchase',
                amount: _amountController.text,
                recipient:
                    '${_selectedNetwork!.name} - ${_phoneController.text}',
              ));
        }
      },
    );
  }

  void _buyData() {
    if (!_dataValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Data Bundle'},
        {'label': 'Network', 'value': _selectedNetwork!.name},
        {'label': 'Phone', 'value': _phoneController.text},
        {'label': 'Plan', 'value': '${_selectedPlan!.data} — ${_selectedPlan!.validity}'},
        {'label': 'Amount', 'value': '₦${_selectedPlan!.price}'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        if (mounted) {
          context.pushReplacement('/success',
              extra: SuccessScreenProps(
                transactionType: 'Data Purchase',
                amount: _selectedPlan!.price,
                recipient:
                    '${_selectedNetwork!.name} - ${_phoneController.text}',
              ));
        }
      },
    );
  }

  // ── Data plan bottom sheet ─────────────────────────────────────────────────
  void _showPlanSheet() {
    if (_selectedNetwork == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DataPlanSheet(
        network: _selectedNetwork!,
        plans: _dataPlans[_selectedNetwork!.id] ?? [],
        selectedPlan: _selectedPlan,
        onSelect: (plan) {
          setState(() => _selectedPlan = plan);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Custom green header with pill toggle ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mobile Top-Up',
                            style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Effra')),
                        Text('Airtime & data bundles',
                            style: TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 12,
                                fontFamily: 'Effra')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Pill toggle — same style as Send Money
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _pillTab('Airtime', 0),
                      _pillTab('Data', 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BillAccountCard(),
                  const SizedBox(height: 10),
                  const BillPaginationDots(count: 2, active: 0),
                  const SizedBox(height: 20),
                  _buildPhoneField(),
                  const SizedBox(height: 20),
                  _buildRecentContacts(),
                  const SizedBox(height: 20),
                  _buildNetworkSelector(),
                  const SizedBox(height: 24),
                  if (_selectedTab == 0) ..._buildAirtimeContent(),
                  if (_selectedTab == 1) ..._buildDataContent(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildCTA(),
        ],
      ),
    );
  }

  Widget _pillTab(String label, int index) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = index;
        _selectedPlan = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Effra',
            color: active ? const Color(0xFF0B4F2F) : Colors.white70,
          ),
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildPhoneField() {
    return _FloatingField(
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
                  child: Text(_selectedNetwork!.icon,
                      style: TextStyle(fontSize: 13))),
            )
          : null,
    );
  }

  Widget _buildRecentContacts() {
    const colors = [Color(0xFF166C46), Color(0xFF7C3AED), Color(0xFFD33B31)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequent Beneficiaries',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontFamily: 'Effra')),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _contacts.length,
            itemBuilder: (_, i) {
              final c = _contacts[i];
              return GestureDetector(
                onTap: () => setState(() {
                  _phoneController.text = c.number;
                  _detectNetwork();
                }),
                child: Container(
                  margin: EdgeInsets.only(right: i < _contacts.length - 1 ? 12 : 0),
                  width: 72,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colors[i % colors.length],
                        child: Text(c.initial,
                            style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 18)),
                      ),
                      const SizedBox(height: 6),
                      Text(c.name,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                              fontFamily: 'Effra'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center),
                      Text('${c.number.substring(0, 7)}...',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Effra'),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Network',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontFamily: 'Effra')),
        const SizedBox(height: 10),
        Row(
          children: _networks.asMap().entries.map((e) {
            final net = e.value;
            final isSelected = _selectedNetwork?.id == net.id;
            final isLast = e.key == _networks.length - 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedNetwork = net;
                  _selectedPlan = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: isLast ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? net.bgColor : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? net.color : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(net.icon, style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(net.name,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Effra',
                              color: isSelected
                                  ? net.color
                                  : const Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Airtime form ───────────────────────────────────────────────────────────

  List<Widget> _buildAirtimeContent() {
    return [
      const Text('Quick Select Amount',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              fontFamily: 'Effra')),
      const SizedBox(height: 10),
      Row(
        children: _quickAmounts.asMap().entries.map((e) {
          final amt = e.value;
          final isLast = e.key == _quickAmounts.length - 1;
          final isSelected = _amountController.text == amt;
          final label = int.parse(amt) >= 1000
              ? '₦${int.parse(amt) ~/ 1000},000'
              : '₦$amt';
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _amountController.text = amt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(right: isLast ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF2F7F3)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.goldPrimary
                        : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Effra',
                          color: isSelected
                              ? AppColors.goldPrimary
                              : const Color(0xFF374151))),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
      const Text('Enter Amount',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              fontFamily: 'Effra')),
      const SizedBox(height: 10),
      _AmountInputCard(
        controller: _amountController,
        focusNode: _amountFocus,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 20),
      const BillDailyLimitCard(),
    ];
  }

  // ── Data form ──────────────────────────────────────────────────────────────

  List<Widget> _buildDataContent() {
    return [
      // Plan selector button
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _selectedNetwork == null ? null : _showPlanSheet,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 58,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedPlan != null
                  ? AppColors.goldPrimary.withOpacity(0.4)
                  : const Color(0xFFE4E7EC),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.data_usage_rounded, size: 18, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 10),
                Expanded(
                  child: _selectedPlan != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Data Plan',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.goldPrimary,
                                    fontFamily: 'Effra',
                                    fontWeight: FontWeight.w500)),
                            Text(
                                '${_selectedPlan!.data} · ${_selectedPlan!.validity} · ₦${_selectedPlan!.price}',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontFamily: 'Effra')),
                          ],
                        )
                      : Text(
                          _selectedNetwork == null
                              ? 'Select a network first'
                              : 'Select a data plan',
                          style: TextStyle(
                              fontSize: 15,
                              color: _selectedNetwork == null
                                  ? const Color(0xFFD0D5DD)
                                  : const Color(0xFF98A2B3),
                              fontFamily: 'Effra')),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF9CA3AF), size: 22),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      const BillDailyLimitCard(),
    ];
  }

  // ── CTA ───────────────────────────────────────────────────────────────────

  Widget _buildCTA() {
    final isAirtime = _selectedTab == 0;
    final enabled = isAirtime ? _airtimeValid : _dataValid;
    final label = isAirtime
        ? (_amountController.text.isNotEmpty
            ? 'Buy Airtime — ₦${_amountController.text}'
            : 'Buy Airtime')
        : (_selectedPlan != null
            ? 'Buy ${_selectedPlan!.data} — ₦${_selectedPlan!.price}'
            : 'Select a Plan');

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: GestureDetector(
        onTap: enabled ? (isAirtime ? _buyAirtime : _buyData) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? AppColors.goldGradient
                : null,
            color: enabled ? null : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Effra',
                    color: enabled ? Colors.white : const Color(0xFF9CA3AF))),
          ),
        ),
      ),
    );
  }
}

// ── Floating Label Field ──────────────────────────────────────────────────────

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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused
              ? AppColors.goldPrimary
              : _hasValue
                  ? AppColors.goldPrimary.withOpacity(0.4)
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
                  fontFamily: 'Effra',
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
            top: isActive ? 28 : 0,
            bottom: isActive ? 6 : 0,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Effra',
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
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.suffix != null)
            Positioned(
              right: 14, top: 0, bottom: 0,
              child: Center(child: widget.suffix!),
            ),
        ],
      ),
    );
  }
}

// ── Amount Input Card ─────────────────────────────────────────────────────────

class _AmountInputCard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String)? onChanged;

  const _AmountInputCard(
      {required this.controller, required this.focusNode, this.onChanged});

  @override
  State<_AmountInputCard> createState() => _AmountInputCardState();
}

class _AmountInputCardState extends State<_AmountInputCard> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(
        () => setState(() => _focused = widget.focusNode.hasFocus));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _focused ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _focused ? AppColors.goldPrimary : const Color(0xFFE5E7EB),
          width: _focused ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text('₦',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _focused
                            ? const Color(0xFF111827)
                            : const Color(0xFF6B7280))),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: widget.onChanged,
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                          fontSize: 36,
                          color: Color(0xFFD1D5DB),
                          fontWeight: FontWeight.w300),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Theme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text('Min: ₦50, Max: ₦50,000',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Plan Bottom Sheet ─────────────────────────────────────────────────────

class _DataPlanSheet extends StatefulWidget {
  final NetworkProvider network;
  final List<DataPlan> plans;
  final DataPlan? selectedPlan;
  final ValueChanged<DataPlan> onSelect;

  const _DataPlanSheet({
    required this.network,
    required this.plans,
    required this.selectedPlan,
    required this.onSelect,
  });

  @override
  State<_DataPlanSheet> createState() => _DataPlanSheetState();
}

class _DataPlanSheetState extends State<_DataPlanSheet> {
  PlanCategory _category = PlanCategory.monthly;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DataPlan> get _filtered {
    final byCat = widget.plans.where((p) => p.category == _category).toList();
    if (_query.isEmpty) return byCat;
    return byCat
        .where((p) =>
            p.data.toLowerCase().contains(_query.toLowerCase()) ||
            p.price.contains(_query) ||
            p.validity.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    const categoryLabels = {
      PlanCategory.daily: 'Daily',
      PlanCategory.weekly: 'Weekly',
      PlanCategory.monthly: 'Monthly',
    };

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.network.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(widget.network.icon,
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${widget.network.name} Data Plans',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Effra',
                  ),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: TextStyle(
                          fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontFamily: 'Effra'),
                      decoration: InputDecoration(
                        hintText: 'Search plans…',
                        hintStyle: TextStyle(
                            fontSize: 14, color: Color(0xFF9CA3AF), fontFamily: 'Effra'),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Category pill toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: PlanCategory.values.map((cat) {
                  final sel = _category == cat;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: sel
                              ? [BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            categoryLabels[cat]!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Effra',
                              color: sel
                                  ? const Color(0xFF101828)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Plan list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.42,
            ),
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No plans found',
                          style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Effra')),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: Theme.of(context).scaffoldBackgroundColor, indent: 20, endIndent: 20),
                    itemBuilder: (_, i) {
                      final plan = _filtered[i];
                      final isSelected = widget.selectedPlan?.id == plan.id;
                      return InkWell(
                        onTap: () => widget.onSelect(plan),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.goldPrimary.withOpacity(0.1)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    plan.data,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Effra',
                                      color: isSelected
                                          ? AppColors.goldPrimary
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${plan.data} Data',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontFamily: 'Effra',
                                      ),
                                    ),
                                    Text(
                                      'Valid for ${plan.validity}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                        fontFamily: 'Effra',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₦${plan.price}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Effra',
                                  color: isSelected
                                      ? AppColors.goldPrimary
                                      : const Color(0xFF101828),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.check_circle_rounded,
                                    color: AppColors.goldPrimary, size: 18),
                              ],
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
    );
  }
}
