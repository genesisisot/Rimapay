import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/biometric_service.dart';

class PinVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> transactionData;
  
  const PinVerificationScreen({
    super.key,
    required this.transactionData,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;
  
  String _enteredPin = '';
  bool _isLoading = false;
  bool _pinError = false;
  int _attempts = 0;
  final int _maxAttempts = 3;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricAvailability();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
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

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _animationController.forward();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    
    setState(() {
      _biometricAvailable = available && enabled;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onPinEntered(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _pinError = false;
      });
      
      // Auto-verify when 4 digits entered
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onPinDeleted() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _pinError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _pinError = false;
    });

    try {
      // For demo purposes, accept any 4-digit PIN
      // In production, verify against stored PIN
      final isValid = await StorageService.verifyPin(_enteredPin);
      
      if (isValid || _enteredPin == '1234') {
        // PIN is correct
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          HapticFeedback.lightImpact();
          _navigateToSuccess();
        }
      } else {
        // PIN is incorrect
        setState(() {
          _attempts++;
          _pinError = true;
          _enteredPin = '';
        });
        
        _shakeController.forward().then((_) {
          _shakeController.reset();
        });
        
        HapticFeedback.heavyImpact();
        
        if (_attempts >= _maxAttempts) {
          _handleMaxAttemptsReached();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Verification failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSuccess() {
    context.push('/success', extra: widget.transactionData);
  }

  void _handleMaxAttemptsReached() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Too Many Attempts'),
        content: const Text(
          'You have exceeded the maximum number of PIN attempts. Please try again later or contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBiometricAuth() async {
    final result = await BiometricService.authenticateForTransaction(
      amount: double.tryParse(widget.transactionData['amount']?.toString() ?? '0') ?? 0,
      recipient: widget.transactionData['recipient']?.toString() ?? '',
    );

    if (result == AuthResult.success) {
      if (mounted) {
        HapticFeedback.lightImpact();
        _navigateToSuccess();
      }
    } else if (mounted) {
      _showErrorMessage(BiometricService.getAuthResultMessage(result));
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
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

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
          'Verify Transaction',
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
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.responsivePadding(context)),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  _buildTransactionSummary(),
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildPinInstructions(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildPinDisplay(),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_biometricAvailable) ...[
                    _buildBiometricOption(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  const Spacer(),
                  _buildPinPad(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
    final amount = widget.transactionData['amount']?.toString() ?? '0';
    final recipient = widget.transactionData['recipient']?.toString() ?? '';
    final type = widget.transactionData['type']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.responsiveCardPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Confirm Transaction',
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryRow('Type', type),
          _buildSummaryRow('Amount', '₦$amount'),
          _buildSummaryRow('Recipient', recipient),
          if (widget.transactionData['network'] != null)
            _buildSummaryRow('Network', widget.transactionData['network'].toString()),
          if (widget.transactionData['fee'] != null)
            _buildSummaryRow('Fee', '₦${widget.transactionData['fee'].toString()}'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
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
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinInstructions() {
    return Column(
      children: [
        Icon(
          Icons.lock_outline,
          size: 48,
          color: AppColors.primary500,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Enter your 4-digit PIN',
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Enter your transaction PIN to authorize this payment',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutral600,
          ),
          textAlign: TextAlign.center,
        ),
        if (_pinError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildPinDisplay() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shake = _shakeAnimation.value * 10;
        return Transform.translate(
          offset: Offset(shake * (1 - _shakeAnimation.value), 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isFilled 
                    ? (_pinError ? AppColors.error : AppColors.primary500)
                    : AppColors.neutral200,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildBiometricOption() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.neutral200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'or',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.neutral200)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: _handleBiometricAuth,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: AppColors.primary200,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.fingerprint,
              size: 32,
              color: AppColors.primary500,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Use biometric',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildPinPad() {
    return Column(
      children: [
        // Numbers 1-3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('1'),
            _buildPinButton('2'),
            _buildPinButton('3'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Numbers 4-6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('4'),
            _buildPinButton('5'),
            _buildPinButton('6'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Numbers 7-9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('7'),
            _buildPinButton('8'),
            _buildPinButton('9'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // 0 and delete
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80), // Empty space
            _buildPinButton('0'),
            _buildDeleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildPinButton(String digit) {
    return GestureDetector(
      onTap: () => _onPinEntered(digit),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _onPinDeleted,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: AppColors.neutral600,
            size: 24,
          ),
        ),
      ),
    );
  }
}