import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class DataPlan {
  final String id;
  final String name;
  final String data;
  final String validity;
  final double price;
  final String description;

  DataPlan({
    required this.id,
    required this.name,
    required this.data,
    required this.validity,
    required this.price,
    required this.description,
  });
}

class NetworkProvider {
  final String id;
  final String name;
  final String code;
  final Color color;
  final String logo;
  final List<DataPlan> plans;

  NetworkProvider({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    required this.logo,
    required this.plans,
  });
}

class DataPurchaseScreen extends StatefulWidget {
  const DataPurchaseScreen({super.key});

  @override
  State<DataPurchaseScreen> createState() => _DataPurchaseScreenState();
}

class _DataPurchaseScreenState extends State<DataPurchaseScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  NetworkProvider? _selectedNetwork;
  DataPlan? _selectedPlan;
  bool _isLoading = false;
  bool _saveAsBeneficiary = false;

  final List<NetworkProvider> _networks = [
    NetworkProvider(
      id: 'mtn',
      name: 'MTN',
      code: 'MTN',
      color: const Color(0xFFFFCC02),
      logo: '📱',
      plans: [
        DataPlan(
          id: 'mtn_500mb',
          name: '500MB',
          data: '500MB',
          validity: '30 days',
          price: 300,
          description: 'Perfect for basic browsing',
        ),
        DataPlan(
          id: 'mtn_1gb',
          name: '1GB',
          data: '1GB',
          validity: '30 days',
          price: 500,
          description: 'Great for social media',
        ),
        DataPlan(
          id: 'mtn_2gb',
          name: '2GB',
          data: '2GB',
          validity: '30 days',
          price: 1000,
          description: 'Ideal for streaming',
        ),
        DataPlan(
          id: 'mtn_5gb',
          name: '5GB',
          data: '5GB',
          validity: '30 days',
          price: 2000,
          description: 'Heavy usage',
        ),
        DataPlan(
          id: 'mtn_10gb',
          name: '10GB',
          data: '10GB',
          validity: '30 days',
          price: 3500,
          description: 'Premium package',
        ),
      ],
    ),
    NetworkProvider(
      id: 'airtel',
      name: 'Airtel',
      code: 'AIRTEL',
      color: const Color(0xFFE60012),
      logo: '📲',
      plans: [
        DataPlan(
          id: 'airtel_500mb',
          name: '500MB',
          data: '500MB',
          validity: '30 days',
          price: 250,
          description: 'Basic browsing',
        ),
        DataPlan(
          id: 'airtel_1gb',
          name: '1GB',
          data: '1GB',
          validity: '30 days',
          price: 450,
          description: 'Social media',
        ),
        DataPlan(
          id: 'airtel_2gb',
          name: '2GB',
          data: '2GB',
          validity: '30 days',
          price: 900,
          description: 'Video streaming',
        ),
        DataPlan(
          id: 'airtel_5gb',
          name: '5GB',
          data: '5GB',
          validity: '30 days',
          price: 1800,
          description: 'Heavy browsing',
        ),
      ],
    ),
    NetworkProvider(
      id: 'glo',
      name: 'Globacom',
      code: 'GLO',
      color: const Color(0xFF00B04F),
      logo: '📞',
      plans: [
        DataPlan(
          id: 'glo_500mb',
          name: '500MB',
          data: '500MB',
          validity: '30 days',
          price: 200,
          description: 'Basic package',
        ),
        DataPlan(
          id: 'glo_1gb',
          name: '1GB',
          data: '1GB',
          validity: '30 days',
          price: 400,
          description: 'Standard package',
        ),
        DataPlan(
          id: 'glo_3gb',
          name: '3GB',
          data: '3GB',
          validity: '30 days',
          price: 1000,
          description: 'Popular choice',
        ),
        DataPlan(
          id: 'glo_7gb',
          name: '7GB',
          data: '7GB',
          validity: '30 days',
          price: 2000,
          description: 'Power user',
        ),
      ],
    ),
    NetworkProvider(
      id: '9mobile',
      name: '9Mobile',
      code: '9MOBILE',
      color: const Color(0xFF00A651),
      logo: '📳',
      plans: [
        DataPlan(
          id: '9mobile_750mb',
          name: '750MB',
          data: '750MB',
          validity: '30 days',
          price: 500,
          description: 'Smart choice',
        ),
        DataPlan(
          id: '9mobile_1_5gb',
          name: '1.5GB',
          data: '1.5GB',
          validity: '30 days',
          price: 900,
          description: 'Good value',
        ),
        DataPlan(
          id: '9mobile_4gb',
          name: '4GB',
          data: '4GB',
          validity: '30 days',
          price: 1800,
          description: 'Best value',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _phoneController.addListener(_detectNetwork);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    _animationController.forward();
  }

  void _detectNetwork() {
    final phone = _phoneController.text.replaceAll(' ', '');
    if (phone.length >= 4) {
      final prefix = phone.substring(0, 4);
      NetworkProvider? detectedNetwork;
      
      if (['0803', '0806', '0810', '0813', '0814', '0816', '0903', '0906'].contains(prefix)) {
        detectedNetwork = _networks.firstWhere((n) => n.id == 'mtn');
      } else if (['0802', '0808', '0812', '0901', '0902', '0904', '0907'].contains(prefix)) {
        detectedNetwork = _networks.firstWhere((n) => n.id == 'airtel');
      } else if (['0805', '0807', '0811', '0815', '0905'].contains(prefix)) {
        detectedNetwork = _networks.firstWhere((n) => n.id == 'glo');
      } else if (['0809', '0817', '0818', '0908', '0909'].contains(prefix)) {
        detectedNetwork = _networks.firstWhere((n) => n.id == '9mobile');
      }
      
      if (detectedNetwork != _selectedNetwork) {
        setState(() {
          _selectedNetwork = detectedNetwork;
          _selectedPlan = null; // Reset plan when network changes
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    if (!_formKey.currentState!.validate() || 
        _selectedNetwork == null || 
        _selectedPlan == null) {
      _showErrorMessage('Please select network, plan and fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      final transactionId = await transactionProvider.processTransaction(
        type: TransactionType.data,
        amount: _selectedPlan!.price,
        recipient: '${_selectedNetwork!.name} Data',
        description: _phoneController.text,
        network: _selectedNetwork!.name,
        plan: _selectedPlan!.name,
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        context.push('/pin-verification', extra: {
          'transactionId': transactionId,
          'type': 'Data Purchase',
          'amount': _selectedPlan!.price.toString(),
          'recipient': '${_selectedNetwork!.name} - ${_phoneController.text}',
          'network': _selectedNetwork!.name,
          'plan': _selectedPlan!.name,
          'phoneNumber': _phoneController.text,
          'canSaveBeneficiary': _saveAsBeneficiary,
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Transaction failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final cleanPhone = value.replaceAll(' ', '');
    if (!RegExp(r'^0[7-9][0-1][0-9]{8}$').hasMatch(cleanPhone)) {
      return 'Please enter a valid Nigerian phone number';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: AppColors.neutral0,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios),
          color: AppColors.neutral600,
        ),
        title: Text(
          languageProvider.t('data'),
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.responsivePadding(context)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceHeader(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildPhoneNumberField(languageProvider),
                  const SizedBox(height: AppSpacing.xl),
                  _buildNetworkSelection(),
                  const SizedBox(height: AppSpacing.xl),
                  if (_selectedNetwork != null) ...[
                    _buildDataPlans(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  _buildBeneficiaryOption(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildPurchaseButton(languageProvider),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.responsiveCardPadding(context)),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Center(
                  child: Text('📶', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buy Data',
                      style: AppTextStyles.heading4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Data bundles for all networks',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberField(LanguageProvider languageProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.t('phoneNumber'),
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _phoneController,
          validator: _validatePhone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: InputDecoration(
            hintText: '08012345678',
            prefixIcon: const Icon(Icons.phone_outlined),
            suffixIcon: _selectedNetwork != null
              ? Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _selectedNetwork!.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      _selectedNetwork!.logo,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : null,
          ),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildNetworkSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Network',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 3.5,
          ),
          itemCount: _networks.length,
          itemBuilder: (context, index) {
            final network = _networks[index];
            final isSelected = _selectedNetwork?.id == network.id;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedNetwork = network;
                  _selectedPlan = null; // Reset plan
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? network.color.withOpacity(0.1) : AppColors.neutral0,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? network.color : AppColors.neutral200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(network.logo, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        network.name,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected ? network.color : AppColors.neutral700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildDataPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Data Plan',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedNetwork!.plans.length,
          itemBuilder: (context, index) {
            final plan = _selectedNetwork!.plans[index];
            final isSelected = _selectedPlan?.id == plan.id;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlan = plan;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected ? _selectedNetwork!.color.withOpacity(0.1) : AppColors.neutral0,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? _selectedNetwork!.color : AppColors.neutral200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedNetwork!.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Center(
                        child: Text(
                          '📊',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                plan.data,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.neutral900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₦${plan.price.toStringAsFixed(0)}',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: _selectedNetwork!.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                plan.description,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                              Text(
                                plan.validity,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: _selectedNetwork!.color,
                        size: 20,
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

  Widget _buildBeneficiaryOption() {
    return Row(
      children: [
        Checkbox(
          value: _saveAsBeneficiary,
          onChanged: (value) {
            setState(() {
              _saveAsBeneficiary = value ?? false;
            });
          },
          activeColor: AppColors.primary500,
        ),
        Expanded(
          child: Text(
            'Save as beneficiary for future transactions',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(LanguageProvider languageProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary500.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        ),
        child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Buy Data',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}