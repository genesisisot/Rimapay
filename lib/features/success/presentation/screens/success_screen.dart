import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/features/receipt/presentation/screens/receipt_screen.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dart:math' as math;
import '../../../../shared/widgets/rimapay_logo.dart';
import '../../../../shared/receipt/receipt_pdf.dart';
import '../../../../core/Utils/haptics.dart';
import 'dart:math' show Random;
import 'package:intl/intl.dart';

import '../../../../core/localization/l10n.dart';
class SuccessScreenProps {
  final String transactionType;
  final String amount;
  final String recipient;
  final String transactionId;
  final bool canSaveBeneficiary;
  final BeneficiaryData? beneficiaryData;

  /// Recipient account number and bank, shown on the receipt when the flow
  /// knows them (bank transfers). Null for bills/airtime.
  final String? recipientAccount;
  final String? recipientBank;

  SuccessScreenProps({
    this.transactionType = "Payment",
    this.amount = "2000.00",
    this.recipient = "Service Provider",
    String? transactionId,
    this.canSaveBeneficiary = true,
    this.beneficiaryData,
    this.recipientAccount,
    this.recipientBank,
  }) : transactionId = transactionId ?? "TXN${DateTime.now().millisecondsSinceEpoch}";
}

class BeneficiaryData {
  final String name;
  final String accountNumber;
  final String bank;

  BeneficiaryData({
    required this.name,
    required this.accountNumber,
    required this.bank,
  });
}

class SuccessScreen extends ConsumerStatefulWidget {
  final SuccessScreenProps props;

  const SuccessScreen({
    super.key,
    required this.props,
  });

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen> 
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _iconRotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideUpAnimation;
  late Animation<double> _iconRotateAnimation;
  late Animation<double> _iconScaleAnimation;

  late AnimationController _confettiController;
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _iconRotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideUpAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _iconRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconRotationController,
      curve: Curves.easeInOut,
    ));

    _iconScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _iconRotationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    HapticFeedback.lightImpact();
    _mainAnimationController.forward();
    _iconRotationController.repeat(reverse: true);
    // Confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    final rng = Random();
    _particles = List.generate(60, (_) => _ConfettiParticle(rng));
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _iconRotationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onHome() {
    context.go('/home');
  }

  bool _receiptBusy = false;

  /// Saves the receipt as a styled PDF or as a PNG of the same page: share
  /// sheet on Android/iOS (Files, Photos, WhatsApp…), a download on web.
  Future<void> _saveReceipt({required bool asImage}) async {
    if (_receiptBusy) return;
    Haptics.press();
    setState(() => _receiptBusy = true);
    try {
      final p = widget.props;
      final l10n = context.l10n;
      final user = context.read<AuthProvider>().user;
      final senderName = user?.displayName ?? '';
      final senderAccount = user?.accountNumber ?? '';
      final data = ReceiptPdfData(
        title: p.transactionType,
        amount: p.amount,
        reference: p.transactionId,
        dateText: DateFormat('d MMM yyyy, h:mm a').format(DateTime.now()),
        details: [
          ReceiptRow(
            'Beneficiary Details',
            p.recipient,
            sub: [p.recipientBank, p.recipientAccount]
                .where((v) => (v ?? '').isNotEmpty)
                .join('  |  '),
          ),
          if (senderName.isNotEmpty)
            ReceiptRow(
              'Sender Details',
              senderName,
              sub: [
                'Rima MFB',
                if (senderAccount.isNotEmpty) senderAccount,
              ].join('  |  '),
            ),
          ReceiptRow('Payment Type', p.transactionType),
        ],
      );
      if (asImage) {
        await shareReceiptImage(data, l10n: l10n);
      } else {
        await shareReceiptPdf(data, l10n: l10n);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.couldnTCreateTheReceiptPlease),
          backgroundColor: Color(0xFFD33B31),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _receiptBusy = false);
    }
  }

  /// Screen that repeats this payment, or null when there isn't one (the
  /// Repeat button is hidden rather than dropping the user on Home).
  (String, Object?)? get _repeatTarget {
    final type = widget.props.transactionType.toLowerCase();
    if (type.contains('airtime to cash')) return null;
    if (type == 'transfer') return ('/transfer', null);
    if (type.contains('airtime')) return ('/bills/airtime', 0);
    if (type.contains('data')) return ('/bills/airtime', 1); // Data tab
    if (type.contains('electricity')) return ('/bills/electricity', null);
    if (type.contains('cable')) return ('/bills/cable', null);
    if (type == 'internet') return ('/bills/internet', null);
    return null;
  }

  void _onRepeatTransaction() {
    final target = _repeatTarget;
    if (target == null) return;
    Haptics.press();
    context.go(target.$1, extra: target.$2);
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = widget.props.transactionType.toLowerCase().contains('transfer');

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.97),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),

                          // RimaPay Logo
                          const RimapayLogo(
                            height: 56,
                            width: 56,
                          ),

                          const SizedBox(height: 20),

                          // Success Icon
                          _buildSuccessIcon(),

                          const SizedBox(height: 24),

                          // Success Message
                          _buildSuccessMessage(isTransfer),

                          const SizedBox(height: 24),

                          // Transaction Details
                          _buildTransactionDetails(),

                          const SizedBox(height: 24),

                          // Action Buttons
                          _buildActionButtons(),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                _buildFooter(),
              ],
            ),
          ),

          // Confetti overlay
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                  size: MediaQuery.of(context).size,
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedBuilder(
            animation: _iconRotationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _iconScaleAnimation.value,
                child: Transform.rotate(
                  angle: _iconRotateAnimation.value * 0.1, // Small rotation
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFD4AF37), // green-400
                          Color(0xFF16A34A), // green-600
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).cardColor,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSuccessMessage(bool isTransfer) {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideUpAnimation.value),
            child: Column(
              children: [
                Text(
                  isTransfer ? 'Transfer Successful! 🎉' : 'Payment Successful! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(context.l10n.yourTransactiontypeHasBeenProcessedSuccessfully(widget.props.transactionType.toLowerCase()),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionDetails() {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideUpAnimation.value),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Transaction Amount
                  Column(
                    children: [
                      Text(
                        formatNaira(widget.props.amount),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(context.l10n.transactionAmount,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), // neutral-500
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Transaction Info
                  _buildDetailRow('Service', widget.props.transactionType),
                  _buildDetailRow('Recipient', widget.props.recipient),
                  if ((widget.props.recipientAccount ?? '').isNotEmpty)
                    _buildDetailRow('Account', widget.props.recipientAccount!),
                  if ((widget.props.recipientBank ?? '').isNotEmpty)
                    _buildDetailRow('Bank', widget.props.recipientBank!),
                  _buildDetailRow('Transaction ID', widget.props.transactionId),
                  _buildDetailRow('Date & Time', _formatDateTime()),
                  _buildStatusRow(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), // neutral-500
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.status,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), // neutral-500
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF166C46), // green-500
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(context.l10n.successful,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A), // green-500
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideUpAnimation.value),
            child: Column(
              children: [
                // Receipt as PDF or image
                Row(
                  children: [
                    Expanded(
                      child: _outlineBtn(
                        icon: Icons.picture_as_pdf_outlined,
                        label: context.l10n.receiptPdf,
                        onTap: () => _saveReceipt(asImage: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _outlineBtn(
                        icon: Icons.image_outlined,
                        label: context.l10n.receiptImage,
                        onTap: () => _saveReceipt(asImage: true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Repeat (when there's a screen for it) + Close
                Row(
                  children: [
                    if (_repeatTarget != null) ...[
                      Expanded(
                        child: _outlineBtn(
                          icon: Icons.refresh,
                          label: context.l10n.repeat,
                          onTap: _onRepeatTransaction,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _onHome,
                        icon: const Icon(Icons.close, size: 16),
                        label: Text(context.l10n.close),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(0xFF16A34A).withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.85);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: c),
      label: Text(label, style: TextStyle(color: c, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: c.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: c.withOpacity(0.05),
      ),
    );
  }

  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(context.l10n.processedSecurelyBy,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4).withOpacity(0.8), // neutral-400
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime() {
    return DateFormat('d MMM yyyy, h:mm a').format(DateTime.now());
  }

}

// ── Confetti ──────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x; // 0..1 relative to screen width
  final double startY;
  final double speed; // 0..1 per animation cycle
  final double size;
  final Color color;
  final double wobble; // horizontal sway amplitude
  final double wobbleSpeed;

  _ConfettiParticle(Random rng)
      : x = rng.nextDouble(),
        startY = -0.1 - rng.nextDouble() * 0.3,
        speed = 0.4 + rng.nextDouble() * 0.6,
        size = 5 + rng.nextDouble() * 7,
        color = _confettiColors[rng.nextInt(_confettiColors.length)],
        wobble = 20 + rng.nextDouble() * 40,
        wobbleSpeed = 2 + rng.nextDouble() * 3;

  static const _confettiColors = [
    Color(0xFF16A34A),
    Color(0xFFD4AF37),
    Color(0xFFFBBF24),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFFA78BFA),
    Color(0xFFFB7185),
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final t = ((progress * p.speed) % 1.0);
      if (t <= 0) continue;
      final dy = p.startY + t * 1.3;
      if (dy > 1.1) continue;
      final dx = p.x + math.sin(t * math.pi * 2 * p.wobbleSpeed) * p.wobble / size.width;
      paint.color = p.color.withOpacity((1 - t * 0.6).clamp(0, 1));
      canvas.save();
      canvas.translate(dx * size.width, dy * size.height);
      canvas.rotate(t * math.pi * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

