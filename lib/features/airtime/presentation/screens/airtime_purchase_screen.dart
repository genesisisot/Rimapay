import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  final String logo;

  NetworkProvider({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    required this.logo,
  });
}

class AirtimePurchaseScreen extends StatefulWidget {
  const AirtimePurchaseScreen({super.key});

  @override
  State<AirtimePurchaseScreen> createState() => _AirtimePurchaseScreenState();
}

class _AirtimePurchaseScreenState extends State<AirtimePurchaseScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  NetworkProvider? _selectedNetwork;
  bool _isLoading = false;
  bool _saveAsBeneficiary = false;

  final List<NetworkProvider> _networks = [
    NetworkProvider(
      id: 'mtn',
      name: 'MTN',
      code: 'MTN',
      color: const Color(0xFFFFCC02),
      logo: '📱',
    ),
    NetworkProvider(
      id: 'airtel',
      name: 'Airtel',
      code: 'AIRTEL',
      color: const Color(0xFFE60012),
      logo: '📲',
    ),
    NetworkProvider(
      id: 'glo',
      name: 'Globacom',
      code: 'GLO',
      color: const Color(0xFF00B04F),
      logo: '📞',
    ),
    NetworkProvider(
      id: '9mobile',
      name: '9Mobile',
      code: '9MOBILE',
      color: const Color(0xFF00A651),
      logo: '📳',
    ),
  ];

  final List<String> _quickAmounts = ['100', '200', '500', '1000', '2000', '5000'];

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
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    if (!_formKey.currentState!.validate() || _selectedNetwork == null) {
      _showErrorMessage('Please select a network and fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
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
          'recipient': '${_selectedNetwork!.name} - ${_phoneController.text}',
          'network': _selectedNetwork!.name,
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

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    if (amount == null || amount < 50) {
      return 'Minimum amount is ₦50';
    }
    
    if (amount > 10000) {
      return 'Maximum amount is ₦10,000';
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
          languageProvider.t('airtime'),
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
                  _buildNetworkSelection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildPhoneNumberField(languageProvider),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAmountField(languageProvider),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickAmounts(),
                  const SizedBox(height: AppSpacing.xl),
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
                  child: Text('📱', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buy Airtime',
                      style: AppTextStyles.heading4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Instant airtime top-up for all networks',
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

  Widget _buildAmountField(LanguageProvider languageProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _amountController,
          validator: _validateAmount,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: const InputDecoration(
            hintText: '1000',
            prefixText: '₦ ',
            prefixIcon: Icon(Icons.money),
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildQuickAmounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Amounts',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _quickAmounts.map((amount) {
            return GestureDetector(
              onTap: () {
                _amountController.text = amount;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Text(
                  '₦$amount',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
              ),
            );
          }).toList(),
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
              'Buy Airtime',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}