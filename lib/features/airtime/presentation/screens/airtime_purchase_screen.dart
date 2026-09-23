import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../bills/data/bills_dtos.dart';
import '../../../bills/presentation/providers/bills_providers.dart';
import '../../../bills/presentation/widgets/bill_purchase_flow.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

import '../../../../core/localization/l10n.dart';
// ── Data Models ───────────────────────────────────────────────────────────────

enum PlanCategory { daily, weekly, monthly, yearly }

extension PlanCategoryApi on PlanCategory {
  /// `validityType` query value for GET /api/v1/bills/data/plans.
  String get apiValue {
    switch (this) {
      case PlanCategory.daily:
        return 'Daily';
      case PlanCategory.weekly:
        return 'Weekly';
      case PlanCategory.monthly:
        return 'Monthly';
      case PlanCategory.yearly:
        return 'Yearly';
    }
  }
}

class DataPlan {
  /// Data bundle id (uuid) sent as `dataBundleId` when purchasing.
  final String id;
  final String data;
  final String validity;
  final String price;
  final PlanCategory category;
  final String? name;
  final String? description;

  const DataPlan({
    required this.id,
    required this.data,
    required this.validity,
    required this.price,
    required this.category,
    this.name,
    this.description,
  });

  factory DataPlan.fromBundle(DataBundleDto b, PlanCategory category) {
    final allowance = b.dataAllowance?.trim();
    final validity = b.validityDescription?.trim();
    return DataPlan(
      id: b.id,
      data: (allowance?.isNotEmpty ?? false) ? allowance! : (b.name ?? ''),
      validity: (validity?.isNotEmpty ?? false)
          ? validity!
          : '${b.validityDays} Day${b.validityDays == 1 ? '' : 's'}',
      price: formatBillAmount(b.amount),
      category: category,
      name: b.name,
    );
  }

  /// API plan name when available, else e.g. "1GB Daily Plan".
  String get title {
    if (name?.trim().isNotEmpty ?? false) return name!.trim();
    switch (category) {
      case PlanCategory.daily:
        return '$data Daily Plan';
      case PlanCategory.weekly:
        return '$data Weekly Plan';
      case PlanCategory.monthly:
        return '$data Monthly Plan';
      case PlanCategory.yearly:
        return '$data Yearly Plan';
    }
  }

  String get info =>
      description ?? 'Get $data for ₦$price. Valid for $validity';
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
  final _phoneController = TextEditingController(text: '8137954069');
  final _amountController = TextEditingController();
  final _planSearchController = TextEditingController();
  String _planQuery = '';
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
    _planSearchController.dispose();
    _phoneFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _detectNetwork() {
    final phone = _phoneController.text.replaceAll(' ', '');
    if (phone.length < 3) return;
    final prefix = phone.substring(0, 3);
    const prefixMap = {
      'mtn': ['803','806','810','813','814','816','903','906','913','916'],
      'glo': ['805','807','815','811','905','915'],
      'airtel': ['802','808','812','701','902','907','901'],
      '9mobile': ['809','818','817','908','909'],
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

  List<DataPlan> _filterPlans(List<DataPlan> plans) {
    final q = _planQuery.trim().toLowerCase();
    if (q.isEmpty) return plans;
    return plans
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.data.toLowerCase().contains(q) ||
            p.validity.toLowerCase().contains(q) ||
            p.price.replaceAll(',', '').contains(q.replaceAll(',', '')))
        .toList();
  }

  /// On the Data tab, only networks the backend sells bundles for are tappable.
  bool _isNetworkAvailable(NetworkProvider net) {
    if (_selectedTab != 1) return true;
    final available = ref.watch(dataNetworksProvider).valueOrNull;
    if (available == null || available.isEmpty) return true;
    return available.any((n) => n.toUpperCase() == net.name.toUpperCase());
  }

  bool get _airtimeValid =>
      _phoneController.text.replaceAll(' ', '').length == 10 &&
      _amountController.text.isNotEmpty &&
      _selectedNetwork != null;

  bool get _dataValid =>
      _phoneController.text.replaceAll(' ', '').length == 10 &&
      _selectedPlan != null &&
      _selectedNetwork != null;

  // ── Actions ───────────────────────────────────────────────────────────────
  void _buyAirtime() {
    if (!_airtimeValid) return;
    final network = _selectedNetwork!;
    final phone = _phoneController.text;
    final amountText = _amountController.text;
    runBillPurchase(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Airtime'},
        {'label': 'Network', 'value': network.name},
        {'label': 'Phone', 'value': phone},
        {'label': 'Amount', 'value': '₦$amountText'},
      ],
      submit: (pin, sourceAccount) =>
          ref.read(billsApiServiceProvider).airtimeTopUp(AirtimeTopUpRequest(
                sourceAccount: sourceAccount,
                serviceProvider: network.name,
                mobileNo: localMobileNumber(phone),
                amount: double.tryParse(amountText.replaceAll(',', '')) ?? 0,
                transactionPin: pin,
              )),
      successProps: (result) => SuccessScreenProps(
        transactionType: 'Airtime Purchase',
        amount: amountText,
        recipient: '${network.name} - $phone',
        transactionId: result.transactionReference,
      ),
    );
  }

  void _buyData() {
    if (!_dataValid) return;
    final network = _selectedNetwork!;
    final plan = _selectedPlan!;
    final phone = _phoneController.text;
    runBillPurchase(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Data Bundle'},
        {'label': 'Network', 'value': network.name},
        {'label': 'Phone', 'value': phone},
        {'label': 'Plan', 'value': '${plan.data} — ${plan.validity}'},
        {'label': 'Amount', 'value': '₦${plan.price}'},
      ],
      submit: (pin, sourceAccount) =>
          ref.read(billsApiServiceProvider).purchaseData(DataPurchaseRequest(
                sourceAccount: sourceAccount,
                dataBundleId: plan.id,
                mobileNo: localMobileNumber(phone),
                transactionPin: pin,
              )),
      successProps: (result) => SuccessScreenProps(
        transactionType: 'Data Purchase',
        amount: plan.price,
        recipient: '${network.name} - $phone',
        transactionId: result.transactionReference,
      ),
    );
  }

  /// Selects [plan] then goes straight to PIN confirmation.
  void _buyPlanNow(DataPlan plan) {
    setState(() => _selectedPlan = plan);
    if (!_dataValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterValidTenDigitPhone)),
      );
      return;
    }
    _buyData();
  }

  void _showPlanInfoSheet(DataPlan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanInfoSheet(
        plan: plan,
        onBuyNow: () {
          Navigator.pop(context);
          _buyPlanNow(plan);
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.mobileTopUp,
                            style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Effra')),
                        Text(context.l10n.airtimeAndDataBundles,
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
          color: active ? Theme.of(context).cardColor : Colors.transparent,
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
      label: context.l10n.phoneNumber,
      hint: '801 234 5678',
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: (_) => setState(() {}),
      prefixWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+234',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 1,
            height: 18,
            child: ColoredBox(color: Theme.of(context).dividerColor),
          ),
        ],
      ),
      prefixWidth: 72,
      suffix: _selectedNetwork != null
          ? Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? _selectedNetwork!.color.withOpacity(0.15) : _selectedNetwork!.bgColor,
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
        Text(context.l10n.frequentBeneficiaries,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                              fontFamily: 'Effra'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center),
                      Text(context.l10n.number(c.number.substring(0, 7)),
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
        Text(context.l10n.chooseNetwork,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                fontFamily: 'Effra')),
        const SizedBox(height: 10),
        Row(
          children: _networks.asMap().entries.map((e) {
            final net = e.value;
            final isSelected = _selectedNetwork?.id == net.id;
            final isLast = e.key == _networks.length - 1;
            final netEnabled = _isNetworkAvailable(net);
            return Expanded(
              child: Opacity(
              opacity: netEnabled ? 1 : 0.35,
              child: GestureDetector(
                onTap: netEnabled
                    ? () => setState(() {
                          _selectedNetwork = net;
                          _selectedPlan = null;
                        })
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: isLast ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? net.color.withOpacity(0.15) : net.bgColor) : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? net.color : Theme.of(context).dividerColor,
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
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
                    ],
                  ),
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
      Text(context.l10n.quickSelectAmount,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
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
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Effra',
                          color: isSelected
                              ? AppColors.goldPrimary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
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
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'Effra')),
      const SizedBox(height: 10),
      _AmountInputCard(
        controller: _amountController,
        focusNode: _amountFocus,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 20),
      _limitCard(ref.watch(airtimeLimitProvider).valueOrNull),
    ];
  }

  Widget _limitCard(UtilityLimitDto? limit) => BillDailyLimitCard(
        dailyLimit: limit?.dailyLimit,
        remaining: limit?.remainingLimit,
      );

  // ── Data form ──────────────────────────────────────────────────────────────

  List<Widget> _buildDataContent() {
    if (_selectedNetwork == null) {
      return [
        Container(
          height: 58,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(context.l10n.selectNetworkFirst,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Effra',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const BillDailyLimitCard(),
      ];
    }

    final plansAsync = ref.watch(
        dataPlansProvider((_selectedNetwork!.name, _planCategory.apiValue)));
    final bundles = plansAsync.valueOrNull ?? const <DataBundleDto>[];
    final plans = _filterPlans(
        bundles.map((b) => DataPlan.fromBundle(b, _planCategory)).toList());
    final isLoading = plansAsync.isLoading && !plansAsync.hasValue;
    final limit = bundles.isEmpty
        ? null
        : ref.watch(billLimitProvider(bundles.first.billerCategoryId)).valueOrNull;

    return [
      _PlanSearchField(
        controller: _planSearchController,
        onChanged: (v) => setState(() => _planQuery = v),
      ),
      const SizedBox(height: 16),
      _PlanDurationTabs(
        selected: _planCategory,
        onChanged: (cat) => setState(() {
          _planCategory = cat;
          _selectedPlan = null;
        }),
      ),
      const SizedBox(height: 16),
      if (isLoading)
        ...List.generate(
          3,
          (_) => Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
          ),
        )
      else if (plans.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              _planQuery.trim().isEmpty
                  ? 'No plans available'
                  : 'No plans match "${_planQuery.trim()}"',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Effra',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        )
      else
        ...plans.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanCard(
              plan: plan,
              isSelected: _selectedPlan?.id == plan.id,
              onTap: () => setState(() => _selectedPlan = plan),
              onMoreInfo: () => _showPlanInfoSheet(plan),
              onBuyNow: () => _buyPlanNow(plan),
            ),
          ),
        ),
      const SizedBox(height: 8),
      _limitCard(limit),
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
        border: Border(top: BorderSide(color: Theme.of(context).scaffoldBackgroundColor)),
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
            color: enabled ? null : Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Effra',
                    color: enabled ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
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
  final Widget? prefixWidget;
  final double prefixWidth;

  const _FloatingField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.suffix,
    this.prefixWidget,
    this.prefixWidth = 0,
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
                  : Theme.of(context).dividerColor,
          width: _focused ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          if (widget.prefixWidget != null)
            Positioned(
              left: 14, top: 0, bottom: 0,
              child: Center(child: widget.prefixWidget!),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            top: isActive ? 9 : 20,
            left: widget.prefixWidget != null ? widget.prefixWidth : 16,
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
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                child: Text(widget.label),
              ),
            ),
          ),
          Positioned(
            left: widget.prefixWidget != null ? widget.prefixWidth : 14,
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
        color: _focused ? Theme.of(context).cardColor : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _focused ? AppColors.goldPrimary : Theme.of(context).dividerColor,
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
                      filled: false,
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
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text(context.l10n.min50Max50000,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -- Plan Search Field -------------------------------------------------------

class _PlanSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PlanSearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Effra',
          color: onSurface,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.searchPlans,
          hintStyle: TextStyle(
            fontSize: 14,
            fontFamily: 'Effra',
            color: onSurface.withOpacity(0.4),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: onSurface.withOpacity(0.4),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: onSurface.withOpacity(0.4),
                  ),
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// -- Plan Duration Tabs ------------------------------------------------------

class _PlanDurationTabs extends StatelessWidget {
  final PlanCategory selected;
  final ValueChanged<PlanCategory> onChanged;

  const _PlanDurationTabs({required this.selected, required this.onChanged});

  static const List<PlanCategory> _cats = [
    PlanCategory.daily,
    PlanCategory.weekly,
    PlanCategory.monthly,
    PlanCategory.yearly,
  ];
  static const List<String> _labels = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: List.generate(_cats.length, (i) {
          final isSelected = _cats[i] == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(_cats[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? AppColors.goldPrimary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Effra',
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.goldPrimary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// -- Plan Card ---------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  final DataPlan plan;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onMoreInfo;
  final VoidCallback onBuyNow;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
    required this.onMoreInfo,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.goldPrimary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Effra',
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(context.l10n.price(plan.price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Effra',
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              plan.info,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontFamily: 'Effra',
                color: onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.validForValidity(plan.validity),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Effra',
                fontWeight: FontWeight.w500,
                color: Color(0xFF166C46),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    onTap: onMoreInfo,
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 15,
                            color: AppColors.goldPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(context.l10n.moreInfo,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Effra',
                              fontWeight: FontWeight.w500,
                              color: onSurface.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: GestureDetector(
                    onTap: onBuyNow,
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(context.l10n.buyNow,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Effra',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -- Plan Info Sheet ---------------------------------------------------------

class _PlanInfoSheet extends StatelessWidget {
  final DataPlan plan;
  final VoidCallback onBuyNow;

  const _PlanInfoSheet({required this.plan, required this.onBuyNow});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontFamily: 'Effra',
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.info,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'Effra',
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 18),
                _row(context, 'Data', plan.data),
                _row(context, 'Validity', plan.validity),
                _row(context, 'Price', '₦${plan.price}'),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onBuyNow,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(context.l10n.buyNow,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Effra',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Effra',
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Effra',
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
