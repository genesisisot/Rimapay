import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class ElectricityProvider {
  final String id;
  final String name;
  final String shortName;
  final String logo;
  final Color color;
  final Color bgColor;

  ElectricityProvider({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logo,
    required this.color,
    required this.bgColor,
  });
}

enum ProcessingStep { form, confirm, processing }

enum MeterType { prepaid, postpaid }

class ElectricityPurchaseScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final Function(Map<String, dynamic>)? onSuccess;

  const ElectricityPurchaseScreen({
    super.key,
    this.onBack,
    this.onSuccess,
  });

  @override
  ConsumerState<ElectricityPurchaseScreen> createState() => _ElectricityPurchaseScreenState();
}

class _ElectricityPurchaseScreenState extends ConsumerState<ElectricityPurchaseScreen> with TickerProviderStateMixin {
  ProcessingStep _currentStep = ProcessingStep.form;
  ElectricityProvider? _selectedProvider;
  String _amount = '';
  String _meterNumber = '';
  String _customerName = '';
  MeterType _meterType = MeterType.prepaid;
  bool _isValidating = false;
  bool _isProcessing = false;

  late AnimationController _processingController;
  late AnimationController _mainController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<ElectricityProvider> _electricityProviders = [
    ElectricityProvider(
      id: 'aedc',
      name: 'Abuja Electricity Distribution Company',
      shortName: 'AEDC',
      logo: 'assets/images/AEDC.png',
      color: const Color(0xFF3B82F6),
      bgColor: const Color(0xFFEBF8FF),
    ),
    ElectricityProvider(
      id: 'ekedc',
      name: 'Eko Electricity Distribution Company',
      shortName: 'EKEDC',
      logo: 'assets/images/EKEDC.jpg',
      color: const Color(0xFFF97316),
      bgColor: const Color(0xFFFFF7ED),
    ),
    ElectricityProvider(
      id: 'ikedc',
      name: 'Ikeja Electric Distribution Company',
      shortName: 'IKEDC',
      logo: 'assets/images/IKEDC.jpg',
      color: const Color(0xFFEAB308),
      bgColor: const Color(0xFFFEFCE8),
    ),
    ElectricityProvider(
      id: 'phed',
      name: 'Port Harcourt Electricity Distribution',
      shortName: 'PHED',
      logo: 'assets/images/PHED.png',
      color: const Color(0xFF10B981),
      bgColor: const Color(0xFFECFDF5),
    ),
    ElectricityProvider(
      id: 'kedco',
      name: 'Kano Electricity Distribution Company',
      shortName: 'KEDCO',
      logo: 'assets/images/KEDCO.png',
      color: const Color(0xFF8B5CF6),
      bgColor: const Color(0xFFF3E8FF),
    ),
    ElectricityProvider(
      id: 'jedc',
      name: 'Jos Electricity Distribution Company',
      shortName: 'JEDC',
      logo: 'assets/images/JEDC.png',
      color: const Color(0xFFEF4444),
      bgColor: const Color(0xFFFEF2F2),
    ),
  ];

  final List<String> _amountOptions = ['1,000', '2,000', '3,000', '5,000', '10,000', '15,000'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _processingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _processingController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _processingController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    _mainController.forward();
  }

  @override
  void dispose() {
    _processingController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  Future<void> _validateMeter() async {
    if (_meterNumber.length < 10) return;

    setState(() {
      _isValidating = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _customerName = 'John Adebayo Okafor';
      _isValidating = false;
    });
  }

  void _handleAmountSelect(String amountStr) {
    final numericAmount = amountStr.replaceAll(',', '');
    setState(() {
      _amount = numericAmount;
    });
  }

  void _handleNext() {
    if (_isFormValid) {
      setState(() {
        _currentStep = ProcessingStep.processing;
        _isProcessing = true;
      });

      _processingController.repeat();

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isProcessing = false;
        });
        _processingController.stop();

        final details = {
          'type': 'Electricity Bill Payment',
          'amount': _amount,
          'recipient': '${_selectedProvider?.shortName} - $_meterNumber',
          'network': _selectedProvider?.shortName,
          'customer': _customerName,
          'provider': _selectedProvider?.name,
        };
        if (mounted) {
          HapticFeedback.lightImpact();
          context.push(
            '/pin-verification',
            extra: details,
          );
        }
        // widget.onSuccess?.call(details);
      });
    }
  }

  bool get _isFormValid => _meterNumber.length >= 10 && _amount.isNotEmpty && _selectedProvider != null && _customerName.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_currentStep == ProcessingStep.processing) {
      return _buildProcessingView();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCompactHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary500,
                                AppColors.primary600,
                                AppColors.primary700,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 32,
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
                    'Please wait while we process your electricity payment...',
                    style: AppTextStyles.bodySmall.copyWith(
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
                          final scale = 1.0 + (0.2 * (1.0 - (animationValue - 0.5).abs() * 2));

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.primary500,
                                  shape: BoxShape.circle,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral100),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onBack ?? () => context.pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.neutral700,
                  size: 16,
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(
                        image: AssetImage('assets/images/AppIcon.png'),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Electricity',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
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
              onTap: _handleNext,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: _isFormValid
                      ? LinearGradient(
                          colors: [AppColors.primary500, AppColors.primary600],
                        )
                      : null,
                  color: _isFormValid ? null : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Next',
                  style: AppTextStyles.bodySmall.copyWith(
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

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeterNumberSection(),
              const SizedBox(height: 20),
              _buildProviderSection(),
              const SizedBox(height: 20),
              _buildMeterTypeSection(),
              const SizedBox(height: 20),
              _buildAmountSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeterNumberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meter Number',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (value) {
            setState(() {
              _meterNumber = value;
              if (_customerName.isNotEmpty) {
                _customerName = '';
              }
            });
            if (value.length >= 10 && _customerName.isEmpty && !_isValidating) {
              _validateMeter();
            }
          },
          keyboardType: TextInputType.number,
          style: AppTextStyles.bodyMedium.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
            color: const Color(0xFF101828),
          ),
          decoration: InputDecoration(
            hintText: 'Enter meter number',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
            suffixIcon: _isValidating
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.tag, color: AppColors.neutral400),
          ),
        ),
        if (_meterNumber.isNotEmpty && _meterNumber.length < 10)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Please enter a complete meter number',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontSize: 11,
              ),
            ),
          ),
        if (_customerName.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meter Validated',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _customerName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProviderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Provider',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: _electricityProviders.map((provider) {
            final isSelected = _selectedProvider?.id == provider.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedProvider = provider;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.neutral50,
                  border: Border.all(
                    color: isSelected ? AppColors.success.withOpacity(0.3) : AppColors.neutral100,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: provider.color,
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage(provider.logo),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.shortName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? AppColors.success : AppColors.neutral900,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              provider.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isSelected ? AppColors.success.withOpacity(0.8) : AppColors.neutral500,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMeterTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meter Type',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMeterTypeButton(MeterType.prepaid, 'Prepaid', '🔋'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMeterTypeButton(MeterType.postpaid, 'Postpaid', '📄'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeterTypeButton(MeterType type, String label, String icon) {
    final isSelected = _meterType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _meterType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [AppColors.primary500, AppColors.primary600]) : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary500 : AppColors.neutral200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
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
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.0,
          children: _amountOptions.map((amountOption) {
            final numericAmount = amountOption.replaceAll(',', '');
            final isSelected = _amount == numericAmount;

            return GestureDetector(
              onTap: () => _handleAmountSelect(amountOption),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(colors: [AppColors.primary500, AppColors.primary600]) : null,
                  color: isSelected ? null : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primary500 : AppColors.neutral200,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '₦$amountOption',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.neutral700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text(
          'Or enter custom amount',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          onChanged: (value) {
            setState(() {
              _amount = value;
            });
          },
          keyboardType: TextInputType.number,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF101828),
          ),
          decoration: const InputDecoration(
            hintText: '₦0.00',
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
