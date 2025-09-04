import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class ElectricityProvider {
  final String id;
  final String name;
  final String code;
  final Color color;
  final String logo;
  final List<String> meterTypes;

  ElectricityProvider({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    required this.logo,
    required this.meterTypes,
  });
}

class ElectricityPurchaseScreen extends StatefulWidget {
  const ElectricityPurchaseScreen({super.key});

  @override
  State<ElectricityPurchaseScreen> createState() => _ElectricityPurchaseScreenState();
}

class _ElectricityPurchaseScreenState extends State<ElectricityPurchaseScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _meterController = TextEditingController();
  final _amountController = TextEditingController();
  final _customerNameController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  ElectricityProvider? _selectedProvider;
  String? _selectedMeterType;
  bool _isLoading = false;
  bool _saveAsBeneficiary = false;
  bool _isVerifyingMeter = false;
  bool _meterVerified = false;

  final List<ElectricityProvider> _providers = [
    ElectricityProvider(
      id: 'aedc',
      name: 'Abuja Electric (AEDC)',
      code: 'AEDC',
      color: const Color(0xFF1E88E5),
      logo: '⚡',
      meterTypes: ['Prepaid', 'Postpaid'],
    ),
    ElectricityProvider(
      id: 'eko',
      name: 'Eko Electric (EKEDC)',
      code: 'EKEDC',
      color: const Color(0xFF43A047),
      logo: '🔌',
      meterTypes: ['Prepaid', 'Postpaid'],
    ),
    ElectricityProvider(
      id: 'ikeja',
      name: 'Ikeja Electric (IKEDC)',
      code: 'IKEDC',
      color: const Color(0xFFE53935),
      logo: '💡',
      meterTypes: ['Prepaid', 'Postpaid'],
    ),
    ElectricityProvider(
      id: 'kano',
      name: 'Kano Electric (KEDCO)',
      code: 'KEDCO',
      color: const Color(0xFFFB8C00),
      logo: '⚡',
      meterTypes: ['Prepaid', 'Postpaid'],
    ),
    ElectricityProvider(
      id: 'phed',
      name: 'Port Harcourt Electric (PHED)',
      code: 'PHED',
      color: const Color(0xFF8E24AA),
      logo: '🔋',
      meterTypes: ['Prepaid', 'Postpaid'],
    ),
    ElectricityProvider(
      id: 'benin',
      name: 'Benin Electric (BEDC)',
      code: 'BEDC',
      color: const Color(0xFF00ACC1),
      logo: '💡',
      meterTypes: ['Prepaid', 'Postpaid'],
    ),
  ];

  final List<String> _quickAmounts = ['1000', '2000', '5000', '10000', '15000', '20000'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  @override
  void dispose() {
    _animationController.dispose();
    _meterController.dispose();
    _amountController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _verifyMeter() async {
    if (_selectedProvider == null || _meterController.text.isEmpty) {
      _showErrorMessage('Please select provider and enter meter number');
      return;
    }

    setState(() {
      _isVerifyingMeter = true;
    });

    try {
      // Simulate API call for meter verification
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock customer data
      setState(() {
        _meterVerified = true;
        _customerNameController.text = 'John Doe';
      });
      
      _showSuccessMessage('Meter verified successfully');
    } catch (e) {
      _showErrorMessage('Failed to verify meter. Please try again.');
    } finally {
      setState(() {
        _isVerifyingMeter = false;
      });
    }
  }

  Future<void> _handlePurchase() async {
    if (!_formKey.currentState!.validate() || 
        _selectedProvider == null || 
        _selectedMeterType == null ||
        !_meterVerified) {
      _showErrorMessage('Please complete all fields and verify meter');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      final transactionId = await transactionProvider.processTransaction(
        type: TransactionType.electricity,
        amount: double.parse(_amountController.text),
        recipient: '${_selectedProvider!.name} ${_selectedMeterType}',
        description: 'Meter: ${_meterController.text}',
        provider: _selectedProvider!.name,
        accountNumber: _meterController.text,
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        context.push('/pin-verification', extra: {
          'transactionId': transactionId,
          'type': 'Electricity Bill',
          'amount': _amountController.text,
          'recipient': '${_selectedProvider!.name} - ${_customerNameController.text}',
          'provider': _selectedProvider!.name,
          'meterNumber': _meterController.text,
          'meterType': _selectedMeterType,
          'customerName': _customerNameController.text,
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateMeter(String? value) {
    if (value == null || value.isEmpty) {
      return 'Meter number is required';
    }
    
    if (value.length < 10) {
      return 'Please enter a valid meter number';
    }
    
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    if (amount == null || amount < 100) {
      return 'Minimum amount is ₦100';
    }
    
    if (amount > 100000) {
      return 'Maximum amount is ₦100,000';
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
          languageProvider.t('electricity'),
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
                  _buildProviderSelection(),
                  const SizedBox(height: AppSpacing.xl),
                  if (_selectedProvider != null) ...[
                    _buildMeterTypeSelection(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  _buildMeterNumberField(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildVerifyButton(),
                  const SizedBox(height: AppSpacing.xl),
                  if (_meterVerified) ...[
                    _buildCustomerInfo(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
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
        gradient: const LinearGradient(
          colors: [Color(0xFFEAB308), Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Center(
              child: Text('⚡', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Electricity Bills',
                  style: AppTextStyles.heading4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Pay electricity bills for all DISCOs',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Electricity Provider',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _providers.length,
          itemBuilder: (context, index) {
            final provider = _providers[index];
            final isSelected = _selectedProvider?.id == provider.id;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedProvider = provider;
                  _selectedMeterType = null;
                  _meterVerified = false;
                  _customerNameController.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected ? provider.color.withOpacity(0.1) : AppColors.neutral0,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? provider.color : AppColors.neutral200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: provider.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Center(
                        child: Text(
                          provider.logo,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        provider.name,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected ? provider.color : AppColors.neutral700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: provider.color,
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

  Widget _buildMeterTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meter Type',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: _selectedProvider!.meterTypes.map((type) {
            final isSelected = _selectedMeterType == type;
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMeterType = type;
                    _meterVerified = false;
                    _customerNameController.clear();
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: type == _selectedProvider!.meterTypes.last ? 0 : AppSpacing.sm,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedProvider!.color.withOpacity(0.1) : AppColors.neutral0,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSelected ? _selectedProvider!.color : AppColors.neutral200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? _selectedProvider!.color : AppColors.neutral700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
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

  Widget _buildMeterNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meter Number',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _meterController,
          validator: _validateMeter,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(13),
          ],
          decoration: InputDecoration(
            hintText: 'Enter meter number',
            prefixIcon: const Icon(Icons.electrical_services),
            suffixIcon: _meterVerified
              ? Icon(
                  Icons.verified,
                  color: AppColors.success,
                )
              : null,
          ),
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            if (_meterVerified) {
              setState(() {
                _meterVerified = false;
                _customerNameController.clear();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isVerifyingMeter ? null : _verifyMeter,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        child: _isVerifyingMeter
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Verify Meter',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Meter Verified',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow('Customer Name', _customerNameController.text),
          _buildInfoRow('Meter Number', _meterController.text),
          _buildInfoRow('Meter Type', _selectedMeterType ?? ''),
          _buildInfoRow('Provider', _selectedProvider?.name ?? ''),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            hintText: '5000',
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
              'Pay Bill',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}