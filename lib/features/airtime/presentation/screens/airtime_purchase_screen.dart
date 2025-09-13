import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

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
  final String avatar;
  final String initial;
  final String lastUsed;
  final String amount;

  RecentContact({
    required this.id,
    required this.name,
    required this.number,
    required this.avatar,
    required this.initial,
    required this.lastUsed,
    required this.amount,
  });
}

enum PurchaseStep { form, confirm, processing }

class AirtimePurchaseScreen extends ConsumerStatefulWidget {
  const AirtimePurchaseScreen({super.key});

  @override
  ConsumerState<AirtimePurchaseScreen> createState() => _AirtimePurchaseScreenState();
}

class _AirtimePurchaseScreenState extends ConsumerState<AirtimePurchaseScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '08137954069');
  final _amountController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _processingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  NetworkProvider? _selectedNetwork;
  PurchaseStep _currentStep = PurchaseStep.form;
  bool _isProcessing = false;

  final List<NetworkProvider> _networks = [
    NetworkProvider(
      id: 'mtn',
      name: 'MTN',
      code: 'MTN',
      color: const Color(0xFFFFCC02),
      bgColor: const Color(0xFFFFF8E1),
      icon: '📶',
      logo: 'assets/images/Mtn.png', // You'll need to add these assets
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

  final List<String> _quickAmounts = ['200', '500', '1,000', '2,000', '3,000', '5,000'];

  final List<RecentContact> _recentContacts = [
    RecentContact(
      id: '1',
      name: 'My Number',
      number: '08137954069',
      avatar: '',
      initial: 'K',
      lastUsed: '2 hours ago',
      amount: '₦1,000',
    ),
    RecentContact(
      id: '2',
      name: 'Adebayo Johnson',
      number: '08123456789',
      avatar: '',
      initial: 'A',
      lastUsed: 'Yesterday',
      amount: '₦500',
    ),
    RecentContact(
      id: '3',
      name: 'Sarah Williams',
      number: '08198765432',
      avatar: '',
      initial: 'S',
      lastUsed: '3 days ago',
      amount: '₦2,000',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _phoneController.addListener(_detectNetwork);

    // Auto-detect network on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_phoneController.text.length >= 4) {
        _detectNetwork();
      }
    });
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

      final prefixMap = {
        'mtn': ['0803', '0806', '0810', '0813', '0814', '0816', '0903', '0906', '0913', '0916'],
        'glo': ['0805', '0807', '0815', '0811', '0905', '0915'],
        'airtel': ['0802', '0808', '0812', '0701', '0902', '0907', '0901'],
        '9mobile': ['0809', '0818', '0817', '0908', '0909'],
      };

      for (final entry in prefixMap.entries) {
        if (entry.value.contains(prefix)) {
          detectedNetwork = _networks.firstWhere((n) => n.id == entry.key);
          break;
        }
      }

      if (detectedNetwork != _selectedNetwork) {
        setState(() {
          _selectedNetwork = detectedNetwork;
        });
      }
    }
  }

  String _formatPhoneNumber(String phone) {
    if (phone.length >= 11) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  void _handleAmountSelect(String amount) {
    final numericAmount = amount.replaceAll(',', '');
    setState(() {
      _amountController.text = numericAmount;
    });
  }

  void _handleContactSelect(RecentContact contact) {
    _phoneController.text = contact.number;
    final network = _detectNetworkFromPhone(contact.number);
    if (network != null) {
      setState(() {
        _selectedNetwork = network;
      });
    }
  }

  NetworkProvider? _detectNetworkFromPhone(String phone) {
    final cleanPhone = phone.replaceAll(' ', '');
    if (cleanPhone.length >= 4) {
      final prefix = cleanPhone.substring(0, 4);
      final prefixMap = {
        'mtn': ['0803', '0806', '0810', '0813', '0814', '0816', '0903', '0906', '0913', '0916'],
        'glo': ['0805', '0807', '0815', '0811', '0905', '0915'],
        'airtel': ['0802', '0808', '0812', '0701', '0902', '0907', '0901'],
        '9mobile': ['0809', '0818', '0817', '0908', '0909'],
      };

      for (final entry in prefixMap.entries) {
        if (entry.value.contains(prefix)) {
          return _networks.firstWhere((n) => n.id == entry.key);
        }
      }
    }
    return null;
  }

  bool get _isFormValid {
    return _phoneController.text.replaceAll(' ', '').length == 11 && _amountController.text.isNotEmpty && _selectedNetwork != null;
  }

  Future<void> _handleNext() async {
    if (!_isFormValid) return;

    setState(() {
      _currentStep = PurchaseStep.processing;
      _isProcessing = true;
    });

    _processingController.repeat();

    // Simulate processing
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      _processingController.stop();

      // Navigate to success or continue with transaction flow
      final transactionProvider = ref.read(transactionProviders.notifier);

      try {
        final transactionId = await transactionProvider.processTransaction(
          type: TransactionType.airtime,
          amount: double.parse(_amountController.text),
          recipient: '${_selectedNetwork!.name} Airtime',
          description: _phoneController.text,
          network: _selectedNetwork!.name,
        );

        if (mounted) {
          HapticFeedback.lightImpact();
          context.push('/pin-verification', extra: {
            'transactionId': transactionId,
            'type': 'Airtime Purchase',
            'amount': _amountController.text,
            'recipient': '${_selectedNetwork!.name} - ${_formatPhoneNumber(_phoneController.text)}',
            'network': _selectedNetwork!.name,
            'phoneNumber': _phoneController.text,
          });
        }
      } catch (e) {
        setState(() {
          _currentStep = PurchaseStep.form;
          _isProcessing = false;
        });
        _showErrorMessage('Transaction failed. Please try again.');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _processingController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.read(languageTranslationsProvider);

    if (_currentStep == PurchaseStep.processing) {
      return _buildProcessingScreen(language);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCompactHeader(language),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPhoneNumberSection(language),
                          const SizedBox(height: AppSpacing.xl),
                          _buildNetworkSelection(language),
                          const SizedBox(height: AppSpacing.xl),
                          _buildAmountSection(language),
                          const SizedBox(height: AppSpacing.xl),
                          _buildRecentPurchasesSection(language),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingScreen(Function(String) language) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _processingController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
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
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  language('processingPayment'),
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  language('processingPaymentMessage'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _processingController,
                      builder: (context, child) {
                        final delay = index * 0.2;
                        final animationValue = (_processingController.value - delay) % 1.0;
                        final scale = animationValue < 0.5 ? 1.0 + (animationValue * 0.4) : 1.4 - ((animationValue - 0.5) * 0.4);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactHeader(Function(String) language) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral100, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent,
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: AppColors.neutral700,
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/AppIcon.png",
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    language('airtime'),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 16,
                    height: 10,
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
            GestureDetector(
              onTap: _isFormValid ? _handleNext : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: _isFormValid ? AppColors.primaryGradient : null,
                  color: _isFormValid ? null : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  language('next'),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _isFormValid ? Colors.white : AppColors.neutral400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberSection(Function(String) language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Phone Number',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Handle contacts tap
              },
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 12,
                    color: AppColors.primary600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    language('contacts'),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 10,
                    color: AppColors.primary600,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          style: AppTextStyles.bodyMedium.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
            color: const Color(0xFF101828),
          ),
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: '0801 234 5678',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              fontFamily: 'monospace',
              color: AppColors.neutral400,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedNetwork != null) ...[
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _selectedNetwork!.bgColor,
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(_selectedNetwork?.logo ?? ""),
                      ),
                    ),
                  ),
                ],
                const Icon(
                  Icons.person_outline,
                  color: AppColors.neutral400,
                  size: 14,
                ),
                const SizedBox(width: 12),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.neutral200, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary500, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: _phoneController.text.isNotEmpty ? AppColors.primary500 : AppColors.neutral200,
                width: 2,
              ),
            ),
          ),
        ),
        if (_phoneController.text.isNotEmpty && _phoneController.text.replaceAll(' ', '').length < 11)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              language('pleaseEnterCompletePhoneNumber'),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.red,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkSelection(Function(String) language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Network',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: _networks.map((network) {
            final isSelected = _selectedNetwork?.id == network.id;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedNetwork = network;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: network.bgColor,
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(network.logo ?? ""),
                              ),
                              border: isSelected ? Border.all(color: AppColors.primary500, width: 2) : null,
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary500,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        network.name,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.neutral700,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
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

  Widget _buildAmountSection(Function(String) language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Amount',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
          ),
          itemCount: _quickAmounts.length,
          itemBuilder: (context, index) {
            final amount = _quickAmounts[index];
            final numericAmount = amount.replaceAll(',', '');
            final isSelected = _amountController.text == numericAmount;

            return GestureDetector(
              onTap: () => _handleAmountSelect(amount),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primary500 : AppColors.neutral200,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    '₦$amount',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.neutral700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'or Enter Custom Amount',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF101828),
          ),
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: '₦0.00',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.neutral200, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary500, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: _amountController.text.isNotEmpty ? AppColors.primary500 : AppColors.neutral200,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPurchasesSection(Function(String) language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time,
              color: AppColors.neutral500,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Recent Purchases',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              ..._recentContacts.map((contact) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => _handleContactSelect(contact),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0x1A00B252),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                contact.initial,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary700,
                                  fontWeight: FontWeight.w600,
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
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.neutral900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      contact.amount,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary600,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
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
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.neutral600,
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      contact.lastUsed,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.neutral400,
                                        fontSize: 10,
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
                  // Handle view all recent purchases
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0x0D00B252),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      language('viewAllRecentPurchases'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary600,
                        fontWeight: FontWeight.w500,
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
