import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dart:math' as math;
class SuccessScreen extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const SuccessScreen({
    super.key,
    required this.transactionData,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _saveAsBeneficiary = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));
  }

  void _startAnimations() {
    HapticFeedback.lightImpact();
    _animationController.forward();
    _confettiController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _goHome() {
    context.go('/home');
  }

  void _viewReceipt() {
    final receiptData = {
      'id': widget.transactionData['transactionId'] ?? 'TX${DateTime.now().millisecondsSinceEpoch}',
      'type': widget.transactionData['type'] ?? 'Transaction',
      'amount': widget.transactionData['amount'] ?? '0',
      'recipient': widget.transactionData['recipient'] ?? '',
      'date': DateTime.now().toLocal().toString().split(' ')[0],
      'time': TimeOfDay.now().format(context),
      'status': 'success',
      'reference': 'RMP${DateTime.now().millisecondsSinceEpoch}',
      'network': widget.transactionData['network'],
      'phoneNumber': widget.transactionData['phoneNumber'],
      'fee': widget.transactionData['fee'] ?? '10.00',
    };

    context.push('/receipt', extra: receiptData);
  }

  void _repeatTransaction() {
    final type = widget.transactionData['type']?.toString().toLowerCase() ?? '';

    if (type.contains('airtime')) {
      context.go('/airtime');
    } else if (type.contains('data')) {
      context.go('/data');
    } else if (type.contains('electricity')) {
      context.go('/electricity');
    } else if (type.contains('cable')) {
      context.go('/cable');
    } else {
      context.go('/bills');
    }
  }

  void _saveBeneficiary() {
    // TODO: Implement save beneficiary logic
    setState(() {
      _saveAsBeneficiary = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Beneficiary saved successfully'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final amount = widget.transactionData['amount']?.toString() ?? '0';
    final recipient = widget.transactionData['recipient']?.toString() ?? '';
    final type = widget.transactionData['type']?.toString() ?? 'Transaction';

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.responsivePadding(context)),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // Success animation and icon
              _buildSuccessIcon(),

              const SizedBox(height: AppSpacing.xxl),

              // Success message
              _buildSuccessMessage(type, amount),

              const SizedBox(height: AppSpacing.xl),

              // Transaction details
              _buildTransactionDetails(type, amount, recipient),

              const SizedBox(height: AppSpacing.xl),

              // Beneficiary option
              if (widget.transactionData['canSaveBeneficiary'] == true) _buildBeneficiaryOption(),

              const Spacer(),

              // Action buttons
              _buildActionButtons(languageProvider),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle with animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),

        // Success checkmark
        ScaleTransition(
          scale: _scaleAnimation,
          child: const Icon(
            Icons.check,
            size: 48,
            color: Colors.white,
          ),
        ),

        // Confetti effect
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(200, 200),
              painter: ConfettiPainter(_confettiController.value),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuccessMessage(String type, String amount) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Text(
              'Transaction Successful!',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your $type of ₦$amount was completed successfully',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(String type, String amount, String recipient) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
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
            _buildDetailRow('Transaction', type),
            _buildDetailRow('Amount', '₦$amount'),
            _buildDetailRow('Recipient', recipient),
            _buildDetailRow('Date', DateTime.now().toLocal().toString().split(' ')[0]),
            _buildDetailRow('Time', TimeOfDay.now().format(context)),
            _buildDetailRow('Reference', 'RMP${DateTime.now().millisecondsSinceEpoch}'),
            if (widget.transactionData['network'] != null) _buildDetailRow('Network', widget.transactionData['network'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryOption() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.responsiveCardPadding(context)),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.primary200),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _saveAsBeneficiary,
              onChanged: (value) {
                if (value == true) {
                  _saveBeneficiary();
                }
              },
              activeColor: AppColors.primary500,
            ),
            Expanded(
              child: Text(
                'Save recipient as beneficiary for quick access',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(LanguageProvider languageProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // View Receipt Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _viewReceipt,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_outlined, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'View Receipt',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Secondary buttons row
          Row(
            children: [
              // Repeat Transaction
              Expanded(
                child: OutlinedButton(
                  onPressed: _repeatTransaction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary500,
                    side: const BorderSide(color: AppColors.primary500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                  child: Text(
                    'Repeat',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.primary500,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Go Home
              Expanded(
                child: OutlinedButton(
                  onPressed: _goHome,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neutral600,
                    side: const BorderSide(color: AppColors.neutral300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                  child: Text(
                    languageProvider.t('home'),
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class ConfettiPainter extends CustomPainter {
  final double animationValue;

  ConfettiPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);

    const particleCount = 20;
    const stepDeg = 360 / particleCount;
    final radius = 80 * animationValue;
    final opacity = (1 - animationValue).clamp(0.0, 1.0).toDouble();

    final colors = <Color>[
      AppColors.primary500,
      AppColors.accentBlue,
      AppColors.accentPurple,
      AppColors.accentPink,
      AppColors.accentOrange,
    ];

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * stepDeg) * (math.pi / 180.0);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      paint.color = colors[i % colors.length].withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

