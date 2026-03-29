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

enum PurchaseStep { form, processing }

enum PlanCategory { daily, weekly, monthly }

class DataPlan {
  final String id;
  final String name;
  final String data;
  final String validity;
  final String price;
  final PlanCategory category;

  DataPlan({
    required this.id,
    required this.name,
    required this.data,
    required this.validity,
    required this.price,
    required this.category,
  });
}

class NetworkProvider {
  final String id;
  final String name;
  final String code;
  final Color color;
  final Color bgColor;
  final String logo;

  NetworkProvider({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    required this.bgColor,
    required this.logo,
  });
}

class RecentPurchase {
  final String id;
  final String name;
  final String number;
  final String initial;
  final String lastUsed;
  final String plan;
  final String data;

  RecentPurchase({
    required this.id,
    required this.name,
    required this.number,
    required this.initial,
    required this.lastUsed,
    required this.plan,
    required this.data,
  });
}

class DataPurchaseScreen extends ConsumerStatefulWidget {
  const DataPurchaseScreen({super.key});

  @override
  ConsumerState<DataPurchaseScreen> createState() => _DataPurchaseScreenState();
}

class _DataPurchaseScreenState extends ConsumerState<DataPurchaseScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '08137954069');

  late AnimationController _animationController;
  late AnimationController _processingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  NetworkProvider? _selectedNetwork;
  DataPlan? _selectedPlan;
  PlanCategory _selectedCategory = PlanCategory.monthly;
  PurchaseStep _currentStep = PurchaseStep.form;
  bool _isProcessing = false;

  final List<NetworkProvider> _networks = [
    NetworkProvider(
      id: 'mtn',
      name: 'MTN',
      code: 'MTN',
      color: const Color(0xFFFFCC02),
      bgColor: const Color(0xFFFFF8E1),
      logo: 'assets/images/Mtn.png',
    ),
    NetworkProvider(
      id: 'airtel',
      name: 'AIRTEL',
      code: 'AIRTEL',
      color: const Color(0xFFFF0000),
      bgColor: const Color(0xFFFFEBEE),
      logo: 'assets/images/Airtel.png',
    ),
    NetworkProvider(
      id: 'glo',
      name: 'GLO',
      code: 'GLO',
      color: const Color(0xFF00A651),
      bgColor: const Color(0xFFE8F5E8),
      logo: 'assets/images/Glo.png',
    ),
    NetworkProvider(
      id: '9mobile',
      name: '9MOBILE',
      code: '9MOBILE',
      color: const Color(0xFF00A86B),
      bgColor: const Color(0xFFE8F6F3),
      logo: 'assets/images/9mobile.png',
    ),
  ];
  final Map<String, List<DataPlan>> _dataPlans = {
    'mtn': [
      // Daily Plans
      DataPlan(id: 'mtn_daily_1', name: '1GB Daily', data: '1GB', validity: '1 Day', price: '300', category: PlanCategory.daily),
      DataPlan(id: 'mtn_daily_2', name: '2GB Daily', data: '2GB', validity: '1 Day', price: '500', category: PlanCategory.daily),
      DataPlan(id: 'mtn_daily_3', name: '3GB Daily', data: '3GB', validity: '1 Day', price: '750', category: PlanCategory.daily),

      // Weekly Plans
      DataPlan(id: 'mtn_weekly_1', name: '1.5GB Weekly', data: '1.5GB', validity: '7 Days', price: '1,200', category: PlanCategory.weekly),
      DataPlan(id: 'mtn_weekly_2', name: '3GB Weekly', data: '3GB', validity: '7 Days', price: '2,000', category: PlanCategory.weekly),
      DataPlan(id: 'mtn_weekly_3', name: '7GB Weekly', data: '7GB', validity: '7 Days', price: '3,500', category: PlanCategory.weekly),

      // Monthly Plans
      DataPlan(id: 'mtn_monthly_1', name: '2GB Monthly', data: '2GB', validity: '30 Days', price: '1,500', category: PlanCategory.monthly),
      DataPlan(id: 'mtn_monthly_2', name: '5GB Monthly', data: '5GB', validity: '30 Days', price: '2,500', category: PlanCategory.monthly),
      DataPlan(id: 'mtn_monthly_3', name: '10GB Monthly', data: '10GB', validity: '30 Days', price: '4,000', category: PlanCategory.monthly),
      DataPlan(id: 'mtn_monthly_4', name: '15GB Monthly', data: '15GB', validity: '30 Days', price: '6,000', category: PlanCategory.monthly),
      DataPlan(id: 'mtn_monthly_5', name: '20GB Monthly', data: '20GB', validity: '30 Days', price: '8,000', category: PlanCategory.monthly),
      DataPlan(id: 'mtn_monthly_6', name: '40GB Monthly', data: '40GB', validity: '30 Days', price: '15,000', category: PlanCategory.monthly),
    ],
    'airtel': [
      // Daily Plans
      DataPlan(id: 'airtel_daily_1', name: '1GB Daily', data: '1GB', validity: '1 Day', price: '300', category: PlanCategory.daily),
      DataPlan(id: 'airtel_daily_2', name: '2GB Daily', data: '2GB', validity: '1 Day', price: '500', category: PlanCategory.daily),

      // Weekly Plans
      DataPlan(id: 'airtel_weekly_1', name: '1.5GB Weekly', data: '1.5GB', validity: '7 Days', price: '1,200', category: PlanCategory.weekly),
      DataPlan(id: 'airtel_weekly_2', name: '4GB Weekly', data: '4GB', validity: '7 Days', price: '2,000', category: PlanCategory.weekly),

      // Monthly Plans
      DataPlan(id: 'airtel_monthly_1', name: '2GB Monthly', data: '2GB', validity: '30 Days', price: '1,500', category: PlanCategory.monthly),
      DataPlan(id: 'airtel_monthly_2', name: '6GB Monthly', data: '6GB', validity: '30 Days', price: '2,500', category: PlanCategory.monthly),
      DataPlan(id: 'airtel_monthly_3', name: '12GB Monthly', data: '12GB', validity: '30 Days', price: '4,000', category: PlanCategory.monthly),
      DataPlan(id: 'airtel_monthly_4', name: '20GB Monthly', data: '20GB', validity: '30 Days', price: '8,000', category: PlanCategory.monthly),
      DataPlan(id: 'airtel_monthly_5', name: '40GB Monthly', data: '40GB', validity: '30 Days', price: '15,000', category: PlanCategory.monthly),
    ],
    'glo': [
      // Daily Plans
      DataPlan(id: 'glo_daily_1', name: '1GB Daily', data: '1GB', validity: '1 Day', price: '300', category: PlanCategory.daily),
      DataPlan(id: 'glo_daily_2', name: '2GB Daily', data: '2GB', validity: '1 Day', price: '500', category: PlanCategory.daily),

      // Weekly Plans
      DataPlan(id: 'glo_weekly_1', name: '2GB Weekly', data: '2GB', validity: '7 Days', price: '1,200', category: PlanCategory.weekly),
      DataPlan(id: 'glo_weekly_2', name: '5GB Weekly', data: '5GB', validity: '7 Days', price: '2,000', category: PlanCategory.weekly),

      // Monthly Plans
      DataPlan(id: 'glo_monthly_1', name: '3GB Monthly', data: '3GB', validity: '30 Days', price: '1,500', category: PlanCategory.monthly),
      DataPlan(id: 'glo_monthly_2', name: '8GB Monthly', data: '8GB', validity: '30 Days', price: '2,500', category: PlanCategory.monthly),
      DataPlan(id: 'glo_monthly_3', name: '15GB Monthly', data: '15GB', validity: '30 Days', price: '4,000', category: PlanCategory.monthly),
      DataPlan(id: 'glo_monthly_4', name: '25GB Monthly', data: '25GB', validity: '30 Days', price: '8,000', category: PlanCategory.monthly),
    ],
    '9mobile': [
      // Daily Plans
      DataPlan(id: '9mobile_daily_1', name: '1GB Daily', data: '1GB', validity: '1 Day', price: '300', category: PlanCategory.daily),
      DataPlan(id: '9mobile_daily_2', name: '2GB Daily', data: '2GB', validity: '1 Day', price: '500', category: PlanCategory.daily),

      // Weekly Plans
      DataPlan(id: '9mobile_weekly_1', name: '1.5GB Weekly', data: '1.5GB', validity: '7 Days', price: '1,200', category: PlanCategory.weekly),
      DataPlan(id: '9mobile_weekly_2', name: '3GB Weekly', data: '3GB', validity: '7 Days', price: '2,000', category: PlanCategory.weekly),

      // Monthly Plans
      DataPlan(id: '9mobile_monthly_1', name: '2GB Monthly', data: '2GB', validity: '30 Days', price: '1,500', category: PlanCategory.monthly),
      DataPlan(id: '9mobile_monthly_2', name: '5GB Monthly', data: '5GB', validity: '30 Days', price: '2,500', category: PlanCategory.monthly),
      DataPlan(id: '9mobile_monthly_3', name: '11GB Monthly', data: '11GB', validity: '30 Days', price: '4,000', category: PlanCategory.monthly),
      DataPlan(id: '9mobile_monthly_4', name: '15GB Monthly', data: '15GB', validity: '30 Days', price: '8,000', category: PlanCategory.monthly),
    ],
  };

  final List<RecentPurchase> _recentPurchases = [
    RecentPurchase(
      id: '1',
      name: 'My Number',
      number: '08137954069',
      initial: 'K',
      lastUsed: '2 hours ago',
      plan: '5GB Monthly',
      data: '5GB',
    ),
    RecentPurchase(
      id: '2',
      name: 'Adebayo Johnson',
      number: '08123456789',
      initial: 'A',
      lastUsed: 'Yesterday',
      plan: '2GB Monthly',
      data: '2GB',
    ),
    RecentPurchase(
      id: '3',
      name: 'Sarah Williams',
      number: '08198765432',
      initial: 'S',
      lastUsed: '3 days ago',
      plan: '10GB Monthly',
      data: '10GB',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _phoneController.addListener(_detectNetwork);
    _detectNetwork(); // Auto-detect on initial load
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _processingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _processingController,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _processingController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _detectNetwork() {
    final phone = _phoneController.text.replaceAll(' ', '');
    if (phone.length >= 4) {
      final prefix = phone.substring(0, 4);
      NetworkProvider? detectedNetwork;

      final Map<String, String> prefixes = {
        '0803': 'mtn',
        '0806': 'mtn',
        '0810': 'mtn',
        '0813': 'mtn',
        '0814': 'mtn',
        '0816': 'mtn',
        '0903': 'mtn',
        '0906': 'mtn',
        '0913': 'mtn',
        '0916': 'mtn',
        '0805': 'glo',
        '0807': 'glo',
        '0815': 'glo',
        '0811': 'glo',
        '0905': 'glo',
        '0915': 'glo',
        '0802': 'airtel',
        '0808': 'airtel',
        '0812': 'airtel',
        '0701': 'airtel',
        '0902': 'airtel',
        '0907': 'airtel',
        '0901': 'airtel',
        '0809': '9mobile',
        '0818': '9mobile',
        '0817': '9mobile',
        '0908': '9mobile',
        '0909': '9mobile'
      };

      final networkId = prefixes[prefix];
      if (networkId != null) {
        detectedNetwork = _networks.firstWhere((n) => n.id == networkId);
      }

      if (detectedNetwork != _selectedNetwork) {
        setState(() {
          _selectedNetwork = detectedNetwork;
          _selectedPlan = null; // Reset plan when network changes
        });
      }
    }
  }

  String _formatPhoneNumber(String phone) {
    if (phone.length >= 4) {
      return phone.replaceAllMapped(
        RegExp(r'(\d{4})(\d{3})(\d{4})'),
        (match) => '${match[1]} ${match[2]} ${match[3]}',
      );
    }
    return phone;
  }

  void _handleContactSelect(RecentPurchase contact) {
    _phoneController.text = contact.number;
    _detectNetwork();
  }

  List<DataPlan> _getCurrentPlans() {
    if (_selectedNetwork == null) return [];
    return _dataPlans[_selectedNetwork!.id]?.where((plan) => plan.category == _selectedCategory).toList() ?? [];
  }

  bool get _isFormValid => _phoneController.text.length == 11 && _selectedPlan != null && _selectedNetwork != null;

  void _showDataPinSheet() {
    if (!_isFormValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Data Bundle'},
        {'label': 'Network', 'value': _selectedNetwork!.name},
        {'label': 'Phone', 'value': _phoneController.text},
        {'label': 'Plan', 'value': _selectedPlan!.name},
        {'label': 'Amount', 'value': '₦${_selectedPlan!.price}'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        _handleNext();
      },
    );
  }

  void _showPlanSheet() {
    if (_selectedNetwork == null) return;
    final allPlans = _dataPlans[_selectedNetwork!.id] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanPickerSheet(
        plans: allPlans,
        selected: _selectedPlan,
        onSelect: (plan) {
          setState(() => _selectedPlan = plan);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _handleNext() async {
    if (!_isFormValid) return;
    HapticFeedback.lightImpact();
    if (mounted) {
      context.pushReplacement('/success', extra: SuccessScreenProps(
        transactionType: 'Data Purchase',
        amount: _selectedPlan!.price,
        recipient: '${_selectedNetwork!.name} - ${_phoneController.text}',
      ));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _processingController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == PurchaseStep.processing) {
      return _buildProcessingScreen((_) => '');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // ── Green header with tabs ──
          BillGreenHeader(
            title: 'Mobile Top-Up',
            subtitle: 'Buy airtime and data bundles',
            showAccountCard: false,
            tabs: const ['Airtime', 'Data'],
            selectedTab: 1,
            onTabChanged: (i) {
              if (i == 0) context.go('/bills/airtime');
            },
          ),

          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account card
                  const BillAccountCard(),
                  const SizedBox(height: 10),
                  const BillPaginationDots(count: 2, active: 1),
                  const SizedBox(height: 20),

                  // Phone number
                  _DataFloatingField(
                    controller: _phoneController,
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
                            child: ClipOval(
                              child: Image.asset(
                                _selectedNetwork!.logo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(),
                              ),
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // Frequent Beneficiaries
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
                      itemCount: _recentPurchases.length,
                      itemBuilder: (_, i) {
                        final c = _recentPurchases[i];
                        final colors = [
                          const Color(0xFF00B252),
                          const Color(0xFF7C3AED),
                          const Color(0xFFEF4444),
                        ];
                        final bgColor = colors[i % colors.length];
                        return GestureDetector(
                          onTap: () => setState(() {
                            _phoneController.text = c.number;
                            _detectNetwork();
                          }),
                          child: Container(
                            margin: EdgeInsets.only(
                                right: i == _recentPurchases.length - 1 ? 0 : 12),
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
                                  '${c.number.substring(0, 7)}...',
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

                  // Network selection
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
                      final isSelected = _selectedNetwork?.id == network.id;
                      final isLast = e.key == _networks.length - 1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedNetwork = network;
                            _selectedPlan = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(right: isLast ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                                ClipOval(
                                  child: Image.asset(
                                    network.logo,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(
                                      network.name[0],
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: network.color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
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

                  if (_selectedNetwork != null) ...[
                    const SizedBox(height: 24),

                    // Plan dropdown
                    const Text(
                      'Select Plan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _showPlanSheet,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedPlan != null
                                ? const Color(0xFF00B252).withOpacity(0.5)
                                : const Color(0xFFE4E7EC),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _selectedPlan != null
                                  ? Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _selectedPlan!.data,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF00B252),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _selectedPlan!.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF101828),
                                                ),
                                              ),
                                              Text(
                                                '${_selectedPlan!.validity} · ₦${_selectedPlan!.price}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Tap to select a data plan',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF9CA3AF),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const BillDailyLimitCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // CTA
          _DataCTA(
            enabled: _isFormValid,
            plan: _selectedPlan,
            onTap: _showDataPinSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingScreen(Function(String) language) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _processingController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Center(
                          child: Text('💰', style: TextStyle(fontSize: 32)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Processing Payment',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we process your data purchase...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _processingController,
                    builder: (context, child) {
                      final delay = index * 0.2;
                      final animationValue = (_processingController.value + delay) % 1.0;
                      final scale = animationValue < 0.5 ? 1.0 + (animationValue * 0.4) : 1.4 - ((animationValue - 0.5) * 0.4);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary500,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(Function(String) language, BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent,
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),

            // Center content
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/AppIcon.png",
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 16,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Center(
                      child: Text(
                        '🇳🇬',
                        style: TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Next button
            GestureDetector(
              onTap: _isFormValid ? _handleNext : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: _isFormValid ? AppColors.primaryGradient : null,
                  color: _isFormValid ? null : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isFormValid ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberSection(Function(String) language, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Handle contacts tap
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 12,
                    color: AppColors.primary600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    language('contacts'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary600,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 10,
                    color: AppColors.primary600,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BillSimpleInput(
          controller: _phoneController,
          placeholder: 'Enter phone number',
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
                    image: DecorationImage(
                      image: AssetImage(_selectedNetwork!.logo),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : null,
        ),
        if (_phoneController.text.isNotEmpty && _phoneController.text.length < 11)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Please enter a complete 11-digit phone number',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkSection(Function(String) language, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Network',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: _networks.length,
          itemBuilder: (context, index) {
            final network = _networks[index];
            final isSelected = _selectedNetwork?.id == network.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedNetwork = network;
                  _selectedPlan = null; // Reset plan when network changes
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: network.bgColor,
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(
                          network.logo,
                        ),
                      ),
                      border: isSelected ? Border.all(color: AppColors.primary500, width: 2) : null,
                    ),
                    child: Stack(
                      children: [
                        if (isSelected)
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.primary500,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    network.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection(Function(String) language, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan Duration',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
          ),
          itemCount: 3,
          itemBuilder: (context, index) {
            final categories = [
              {'id': PlanCategory.daily, 'label': 'Daily', 'icon': '📅'},
              {'id': PlanCategory.weekly, 'label': 'Weekly', 'icon': '📆'},
              {'id': PlanCategory.monthly, 'label': 'Monthly', 'icon': '🗓️'},
            ];

            final category = categories[index];
            final isSelected = _selectedCategory == category['id'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'] as PlanCategory;
                  _selectedPlan = null; // Reset plan when category changes
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary500 : const Color(0xFFE5E7EB),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category['icon'] as String,
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataPlansSection(Function(String) language, bool isSmallScreen) {
    final plans = _getCurrentPlans();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Data Plan',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, mainAxisExtent: 100),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            final isSelected = _selectedPlan?.id == plan.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlan = plan;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary500 : const Color(0xFFE5E7EB),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.data,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.validity,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₦${plan.price}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentPurchasesSection(Function(String) language, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 14,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              'Recent Purchases',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              ...List.generate(_recentPurchases.length, (index) {
                final contact = _recentPurchases[index];
                return Container(
                  margin: EdgeInsets.only(bottom: index == _recentPurchases.length - 1 ? 0 : 6),
                  child: GestureDetector(
                    onTap: () => _handleContactSelect(contact),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                contact.initial,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        contact.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF111827),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      contact.data,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        contact.number,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      contact.lastUsed,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  // Handle view all
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E8).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'View All Recent Purchases',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Plan Picker Sheet ────────────────────────────────────────────────────────

class _PlanPickerSheet extends StatefulWidget {
  final List<DataPlan> plans;
  final DataPlan? selected;
  final void Function(DataPlan) onSelect;

  const _PlanPickerSheet({
    required this.plans,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_PlanPickerSheet> createState() => _PlanPickerSheetState();
}

class _PlanPickerSheetState extends State<_PlanPickerSheet> {
  final _searchController = TextEditingController();
  PlanCategory? _filterCategory;
  String _query = '';

  List<DataPlan> get _filtered {
    return widget.plans.where((p) {
      final matchCat =
          _filterCategory == null || p.category == _filterCategory;
      final matchQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.data.toLowerCase().contains(_query.toLowerCase()) ||
          p.price.contains(_query);
      return matchCat && matchQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plans = _filtered;
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE4E7EC),
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Select Data Plan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4E7EC)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search plans...',
                  hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF9CA3AF), size: 18),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _chip('All', null),
                const SizedBox(width: 8),
                _chip('Daily', PlanCategory.daily),
                const SizedBox(width: 8),
                _chip('Weekly', PlanCategory.weekly),
                const SizedBox(width: 8),
                _chip('Monthly', PlanCategory.monthly),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Plan list
          Expanded(
            child: plans.isEmpty
                ? const Center(
                    child: Text(
                      'No plans found',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: plans.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final plan = plans[i];
                      final isSelected =
                          widget.selected?.id == plan.id;
                      return GestureDetector(
                        onTap: () => widget.onSelect(plan),
                        child: Container(
                          padding: const EdgeInsets.all(14),
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
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00B252)
                                          .withOpacity(0.12)
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    plan.data,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? const Color(0xFF00B252)
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF00B252)
                                            : const Color(0xFF101828),
                                      ),
                                    ),
                                    Text(
                                      'Valid for ${plan.validity}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₦${plan.price}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF00B252)
                                      : const Color(0xFF101828),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF00B252), size: 18),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _chip(String label, PlanCategory? cat) {
    final isSelected = _filterCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _filterCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFF00B252) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ── Floating Label Input ──────────────────────────────────────────────────────

class _DataFloatingField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final Widget? suffix;

  const _DataFloatingField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.suffix,
  });

  @override
  State<_DataFloatingField> createState() => _DataFloatingFieldState();
}

class _DataFloatingFieldState extends State<_DataFloatingField> {
  final _focusNode = FocusNode();
  bool _focused = false;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _hasValue = widget.controller.text.isNotEmpty;
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
    widget.controller.addListener(() {
      final v = widget.controller.text.isNotEmpty;
      if (v != _hasValue) setState(() => _hasValue = v);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
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
          Positioned(
            left: 14,
            right: widget.suffix != null ? 48 : 14,
            top: isActive ? 28 : 18,
            bottom: 6,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
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

// ── Data CTA Button ───────────────────────────────────────────────────────────

class _DataCTA extends StatelessWidget {
  final bool enabled;
  final DataPlan? plan;
  final VoidCallback? onTap;

  const _DataCTA({required this.enabled, this.plan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = plan != null ? 'Buy ${plan!.data} — ₦${plan!.price}' : 'Continue';

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
