import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class CableProvider {
  final String id;
  final String name;
  final Color color;
  final Color bgColor;
  final String icon;
  final String? logo;

  CableProvider({
    required this.id,
    required this.name,
    required this.color,
    required this.bgColor,
    required this.icon,
    this.logo,
  });
}

class CablePackage {
  final String id;
  final String name;
  final String channels;
  final String validity;
  final String price;
  final PackageCategory category;
  final bool popular;

  CablePackage({
    required this.id,
    required this.name,
    required this.channels,
    required this.validity,
    required this.price,
    required this.category,
    this.popular = false,
  });
}

class RecentPurchase {
  final String id;
  final String customerName;
  final String customerNumber;
  final String avatar;
  final String initial;
  final String lastUsed;
  final String package;
  final String provider;

  RecentPurchase({
    required this.id,
    required this.customerName,
    required this.customerNumber,
    required this.avatar,
    required this.initial,
    required this.lastUsed,
    required this.package,
    required this.provider,
  });
}

enum PackageCategory { basic, premium, sports }

enum CableStep { form, confirm, processing }

class CablePurchaseScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(Map<String, dynamic>)? onSuccess;

  const CablePurchaseScreen({
    super.key,
    this.onBack,
    this.onSuccess,
  });

  @override
  State<CablePurchaseScreen> createState() => _CablePurchaseScreenState();
}

class _CablePurchaseScreenState extends State<CablePurchaseScreen> with TickerProviderStateMixin {
  CableStep step = CableStep.form;
  final TextEditingController customerNumberController = TextEditingController(text: '1234567890');
  CablePackage? selectedPackage;
  CableProvider? selectedProvider;
  PackageCategory selectedCategory = PackageCategory.basic;
  bool isProcessing = false;

  late AnimationController _animationController;
  late AnimationController _processingController;

  final List<CableProvider> cableProviders = [
    CableProvider(
      id: 'dstv',
      name: 'DSTV',
      color: const Color(0xFFFF6B35),
      bgColor: const Color(0xFFFFF4F2),
      icon: 'assets/images/Dstv.jpeg',
    ),
    CableProvider(
      id: 'gotv',
      name: 'GOTV',
      color: const Color(0xFF00A651),
      bgColor: const Color(0xFFF0F9F4),
      icon: 'assets/images/Gotv.jpeg',
    ),
    CableProvider(
      id: 'startimes',
      name: 'STARTIMES',
      color: const Color(0xFF1E40AF),
      bgColor: const Color(0xFFEFF6FF),
      icon: 'assets/images/Startimes.jpeg',
    ),
    CableProvider(
      id: 'showmax',
      name: 'SHOWMAX',
      color: const Color(0xFFDC2626),
      bgColor: const Color(0xFFFEF2F2),
      icon: 'assets/images/Showmax.png',
    ),
  ];

  final Map<String, List<CablePackage>> cablePackages = {
    'dstv': [
      // Basic Plans
      CablePackage(id: 'dstv_access', name: 'DStv Access', channels: '95+ Channels', validity: '1 Month', price: '2,950', category: PackageCategory.basic),
      CablePackage(id: 'dstv_family', name: 'DStv Family', channels: '120+ Channels', validity: '1 Month', price: '4,615', category: PackageCategory.basic),
      CablePackage(id: 'dstv_compact', name: 'DStv Compact', channels: '180+ Channels', validity: '1 Month', price: '9,000', category: PackageCategory.basic, popular: true),

      // Premium Plans
      CablePackage(id: 'dstv_compact_plus', name: 'DStv Compact Plus', channels: '230+ Channels', validity: '1 Month', price: '14,250', category: PackageCategory.premium, popular: true),
      CablePackage(id: 'dstv_premium', name: 'DStv Premium', channels: '280+ Channels', validity: '1 Month', price: '21,000', category: PackageCategory.premium),

      // Sports Plans
      CablePackage(id: 'dstv_confam', name: 'DStv Confam', channels: '105+ Channels', validity: '1 Month', price: '5,500', category: PackageCategory.sports),
      CablePackage(id: 'dstv_yanga', name: 'DStv Yanga', channels: '85+ Channels', validity: '1 Month', price: '2,565', category: PackageCategory.sports),
    ],
    'gotv': [
      // Basic Plans
      CablePackage(id: 'gotv_smallie', name: 'GOtv Smallie', channels: '25+ Channels', validity: '1 Month', price: '900', category: PackageCategory.basic),
      CablePackage(id: 'gotv_jinja', name: 'GOtv Jinja', channels: '45+ Channels', validity: '1 Month', price: '1,900', category: PackageCategory.basic),
      CablePackage(id: 'gotv_jolli', name: 'GOtv Jolli', channels: '65+ Channels', validity: '1 Month', price: '2,800', category: PackageCategory.basic, popular: true),

      // Premium Plans
      CablePackage(id: 'gotv_max', name: 'GOtv Max', channels: '75+ Channels', validity: '1 Month', price: '4,150', category: PackageCategory.premium, popular: true),
      CablePackage(id: 'gotv_supa', name: 'GOtv Supa', channels: '85+ Channels', validity: '1 Month', price: '5,500', category: PackageCategory.premium),

      // Sports Plans
      CablePackage(id: 'gotv_lite', name: 'GOtv Lite', channels: '35+ Channels', validity: '1 Month', price: '610', category: PackageCategory.sports),
    ],
    'startimes': [
      // Basic Plans
      CablePackage(id: 'startimes_nova', name: 'Nova', channels: '35+ Channels', validity: '1 Month', price: '900', category: PackageCategory.basic),
      CablePackage(id: 'startimes_basic', name: 'Basic', channels: '50+ Channels', validity: '1 Month', price: '1,700', category: PackageCategory.basic, popular: true),
      CablePackage(id: 'startimes_smart', name: 'Smart', channels: '65+ Channels', validity: '1 Month', price: '2,500', category: PackageCategory.basic),

      // Premium Plans
      CablePackage(id: 'startimes_classic', name: 'Classic', channels: '80+ Channels', validity: '1 Month', price: '2,750', category: PackageCategory.premium, popular: true),
      CablePackage(id: 'startimes_super', name: 'Super', channels: '95+ Channels', validity: '1 Month', price: '4,200', category: PackageCategory.premium),

      // Sports Plans
      CablePackage(id: 'startimes_unique', name: 'Unique Sports', channels: '40+ Channels', validity: '1 Month', price: '1,200', category: PackageCategory.sports),
    ],
    'showmax': [
      // Basic Plans
      CablePackage(id: 'showmax_mobile', name: 'Mobile', channels: 'Mobile Only', validity: '1 Month', price: '1,200', category: PackageCategory.basic),

      // Premium Plans
      CablePackage(id: 'showmax_standard', name: 'Standard', channels: '2 Devices', validity: '1 Month', price: '2,900', category: PackageCategory.premium, popular: true),
      CablePackage(id: 'showmax_pro', name: 'Pro', channels: '4 Devices + Sports', validity: '1 Month', price: '6,300', category: PackageCategory.premium),

      // Sports Plans
      CablePackage(id: 'showmax_sport', name: 'Sport Add-on', channels: 'Live Sports', validity: '1 Month', price: '3,200', category: PackageCategory.sports),
    ],
  };

  final List<RecentPurchase> recentPurchases = [
    RecentPurchase(
      id: '1',
      customerName: 'My DStv',
      customerNumber: '1234567890',
      avatar: '',
      initial: 'K',
      lastUsed: '2 hours ago',
      package: 'DStv Compact',
      provider: 'DSTV',
    ),
    RecentPurchase(
      id: '2',
      customerName: 'Family GOtv',
      customerNumber: '0987654321',
      avatar: '',
      initial: 'F',
      lastUsed: 'Yesterday',
      package: 'GOtv Max',
      provider: 'GOTV',
    ),
    RecentPurchase(
      id: '3',
      customerName: 'Office TV',
      customerNumber: '5678901234',
      avatar: '',
      initial: 'O',
      lastUsed: '3 days ago',
      package: 'StarTimes Classic',
      provider: 'STARTIMES',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _processingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    customerNumberController.dispose();
    _animationController.dispose();
    _processingController.dispose();
    super.dispose();
  }

  void handleCustomerNumberChange(String value) {
    final cleanValue = value.replaceAll(RegExp(r'\D'), '');
    if (cleanValue.length <= 12) {
      setState(() {
        customerNumberController.text = cleanValue;
        customerNumberController.selection = TextSelection.fromPosition(
          TextPosition(offset: cleanValue.length),
        );
      });
    }
  }

  String formatCustomerNumber(String number) {
    if (number.length >= 4) {
      return number.replaceAllMapped(
        RegExp(r'(\d{4})(\d{3})(\d{3})'),
        (match) => '${match[1]} ${match[2]} ${match[3]}',
      );
    }
    return number;
  }

  void handleContactSelect(RecentPurchase contact) {
    final provider = cableProviders.firstWhere(
      (p) => p.name == contact.provider,
      orElse: () => cableProviders.first,
    );
    setState(() {
      customerNumberController.text = contact.customerNumber;
      selectedProvider = provider;
      selectedPackage = null;
    });
  }

  void handleNext() {
    if (isFormValid) {
      setState(() {
        step = CableStep.processing;
        isProcessing = true;
      });

      _processingController.repeat();

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          isProcessing = false;
        });

        // if (widget.onSuccess != null) {
        //   widget.onSuccess!({
        //     'type': 'Cable TV Purchase',
        //     'amount': selectedPackage!.price,
        //     'recipient': '${selectedProvider?.name} - ${formatCustomerNumber(customerNumberController.text)}',
        //     'provider': selectedProvider?.name,
        //     'plan': selectedPackage!.name,
        //   });
        // }
        if (mounted) {
          HapticFeedback.lightImpact();
          context.push('/pin-verification', extra: {
            'type': 'Cable TV Purchase',
            'amount': selectedPackage!.price,
            'recipient': '${selectedProvider?.name} - ${formatCustomerNumber(customerNumberController.text)}',
            'provider': selectedProvider?.name,
            'plan': selectedPackage!.name,
          });
        }
      });
    }
  }

  bool get isFormValid => customerNumberController.text.length >= 8 && selectedPackage != null && selectedProvider != null;

  List<CablePackage> getCurrentPackages() {
    if (selectedProvider == null) return [];
    return cablePackages[selectedProvider!.id]?.where((pkg) => pkg.category == selectedCategory).toList() ?? [];
  }

  Widget _buildProcessingScreen() {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: AnimatedBuilder(
            animation: _processingController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00B252), Color(0xFF00A651)],
                      ),
                    ),
                    child: Transform.rotate(
                      angle: _processingController.value * 2 * 3.14159,
                      child: const Icon(
                        Icons.payment,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const Text(
                    'Processing Payment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait while we process your cable TV subscription...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
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
                          final progress = (_processingController.value + delay) % 1.0;
                          final scale = 1.0 + 0.2 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0);

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00B252),
                            ),
                            transform: Matrix4.identity()..scale(scale),
                          );
                        },
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (step == CableStep.processing) {
      return _buildProcessingScreen();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF667085)),
        onPressed: widget.onBack ?? () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage("assets/images/AppIcon.png"),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Cable TV',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00B252),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '🇳🇬',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextButton(
            onPressed: isFormValid ? handleNext : null,
            style: TextButton.styleFrom(
              backgroundColor: isFormValid ? const Color(0xFF00B252) : const Color(0xFFF2F4F7),
              foregroundColor: isFormValid ? Colors.white : const Color(0xFF98A2B3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomerNumberSection(),
          const SizedBox(height: 20),
          _buildProviderSelection(),
          const SizedBox(height: 20),
          if (selectedProvider != null) ...[
            _buildCategorySelection(),
            const SizedBox(height: 20),
            _buildPackageSelection(),
            const SizedBox(height: 20),
          ],
          _buildRecentPurchases(),
        ],
      ),
    );
  }

  Widget _buildCustomerNumberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Smart Card / Customer Number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF667085),
              ),
            ),
            GestureDetector(
              onTap: () {}, // Handle saved contacts
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.person, size: 12, color: Color(0xFF00B252)),
                  SizedBox(width: 4),
                  Text(
                    'Saved',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF00B252),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 10, color: Color(0xFF00B252)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            TextFormField(
              controller: customerNumberController,
              onChanged: handleCustomerNumberChange,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF101828),
              ),
              decoration: InputDecoration(
                hintText: '1234567890',
                contentPadding: const EdgeInsets.fromLTRB(12, 12, 56, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFD0D5DD),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF00B252),
                    width: 2,
                  ),
                ),
                suffixIcon: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF98A2B3),
                  size: 14,
                ),
              ),
            ),
            if (selectedProvider != null)
              Positioned(
                right: 32,
                top: 12,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: AssetImage(selectedProvider?.icon ?? "")),
                    color: selectedProvider!.bgColor,
                  ),
                ),
              ),
          ],
        ),
        if (customerNumberController.text.isNotEmpty && customerNumberController.text.length < 8)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Please enter a valid customer number (minimum 8 digits)',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Provider',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF667085),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: cableProviders.length,
          itemBuilder: (context, index) {
            final provider = cableProviders[index];
            final isSelected = selectedProvider?.id == provider.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedProvider = provider;
                  selectedPackage = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF2F4F7),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(
                                provider.icon,
                              ),
                              fit: BoxFit.cover,
                            ),
                            color: provider.color,
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00B252),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 0,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF065F46) : const Color(0xFF101828),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'TV Subscription',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? const Color(0xFF059669) : const Color(0xFF667085),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Package Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF667085),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildCategoryButton('basic', 'Basic', '📺'),
            const SizedBox(width: 8),
            _buildCategoryButton('premium', 'Premium', '⭐'),
            const SizedBox(width: 8),
            _buildCategoryButton('sports', 'Sports', '⚽'),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryButton(String id, String label, String icon) {
    final category = PackageCategory.values.firstWhere(
      (e) => e.toString().split('.').last == id,
    );
    final isSelected = selectedCategory == category;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = category;
            selectedPackage = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00B252) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF00B252) : const Color(0xFFD0D5DD),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 4),
              Text(
                label,
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
  }

  Widget _buildPackageSelection() {
    final packages = getCurrentPackages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Package',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF667085),
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: packages.map((pkg) {
            final isSelected = selectedPackage?.id == pkg.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPackage = pkg;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00B252) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00B252) : const Color(0xFFD0D5DD),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      if (pkg.popular)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Popular',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pkg.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pkg.channels,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white.withOpacity(0.8) : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pkg.validity,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white.withOpacity(0.7) : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₦${pkg.price}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildRecentPurchases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.access_time,
              size: 14,
              color: Color(0xFF667085),
            ),
            SizedBox(width: 6),
            Text(
              'Recent Subscriptions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ...recentPurchases.map((contact) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => handleContactSelect(contact),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00B252).withOpacity(0.1),
                            ),
                            child: Center(
                              child: Text(
                                contact.initial,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF047857),
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
                                        contact.customerName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF101828),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      contact.provider,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF059669),
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
                                        contact.customerNumber,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF667085),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      contact.lastUsed,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF98A2B3),
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
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B252).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'View All Recent Subscriptions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF059669),
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
