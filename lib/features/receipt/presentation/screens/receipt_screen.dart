import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rimapay/core/router/app_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/rimapay_logo.dart';
import '../../../../shared/receipt/receipt_pdf.dart';

class ReceiptScreen extends StatefulWidget {
  final ReceiptData receiptData;

  const ReceiptScreen({
    super.key,
    required this.receiptData,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _statusAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _statusScaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _statusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _statusScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _statusAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statusAnimationController.dispose();
    super.dispose();
  }

  /// "Money In" / "Money Out" — the thing a receipt must never leave ambiguous.
  String get _directionLabel =>
      widget.receiptData.isCredit ? 'Money In' : 'Money Out';

  Color get _directionColor =>
      widget.receiptData.isCredit ? const Color(0xFF166C46) : const Color(0xFFB45309);

  /// Amount with a +/- sign so inflow and outflow can't be confused.
  String get _signedAmount =>
      '${widget.receiptData.isCredit ? '+' : '-'}${_formatAmount(widget.receiptData.amount)}';

  /// Credits come FROM someone; debits go TO someone.
  String get _partyLabel => widget.receiptData.isCredit ? 'From:' : 'To:';

  String _formatAmount(String amount) {
    // Remove currency symbol and format
    final cleanAmount = amount.replaceAll(RegExp(r'[^\d.,]'), '');
    return '₦$cleanAmount';
  }

  String _getTransactionIcon(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('airtime')) return '📱';
    if (lowerType.contains('data')) return '📡';
    if (lowerType.contains('cable')) return '📺';
    if (lowerType.contains('electricity')) return '⚡';
    if (lowerType.contains('education')) return '🎓';
    if (lowerType.contains('betting')) return '🎲';
    if (lowerType.contains('transport')) return '🚗';
    if (lowerType.contains('flight')) return '✈️';
    if (lowerType.contains('government')) return '🏛️';
    if (lowerType.contains('transfer')) return '💸';
    return '💳';
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    final isDark = context.isDark;
    switch (status.toLowerCase()) {
      case 'success':
        return {
          'bg': isDark ? const Color(0xFF0B2417) : Colors.green.shade50,
          'border': isDark ? const Color(0xFF1E4D33) : Colors.green.shade200,
          'text': isDark ? Colors.green.shade200 : Colors.green.shade800,
          'icon': isDark ? Colors.green.shade400 : Colors.green.shade600,
          'label': 'Successful',
          'iconData': Icons.check_circle,
        };
      case 'pending':
        return {
          'bg': isDark ? const Color(0xFF2A1A08) : Colors.orange.shade50,
          'border': isDark ? const Color(0xFF5C3A12) : Colors.orange.shade200,
          'text': isDark ? Colors.orange.shade200 : Colors.orange.shade800,
          'icon': isDark ? Colors.orange.shade400 : Colors.orange.shade600,
          'label': 'Pending',
          'iconData': Icons.access_time,
        };
      case 'failed':
        return {
          'bg': isDark ? const Color(0xFF2A0B08) : Colors.red.shade50,
          'border': isDark ? const Color(0xFF5C1A12) : Colors.red.shade200,
          'text': isDark ? Colors.red.shade200 : Colors.red.shade800,
          'icon': isDark ? Colors.red.shade400 : Colors.red.shade600,
          'label': 'Failed',
          'iconData': Icons.error,
        };
      default:
        return {
          'bg': isDark ? const Color(0xFF242938) : Colors.grey.shade50,
          'border': isDark ? const Color(0xFF3D4456) : Colors.grey.shade200,
          'text': isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          'icon': isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          'label': 'Unknown',
          'iconData': Icons.info,
        };
    }
  }

  Future<void> _copyReference() async {
    await Clipboard.setData(ClipboardData(text: widget.receiptData.reference));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reference copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  String _generateReceiptContent() {
    final statusConfig = _getStatusConfig(widget.receiptData.status);

    return '''
RIMAPAY TRANSACTION RECEIPT
===========================

Transaction Details:
----------------------------
Type: ${widget.receiptData.type} ($_directionLabel)
Amount: $_signedAmount
${widget.receiptData.isCredit ? 'From' : 'To'}: ${widget.receiptData.recipient}
Reference: ${widget.receiptData.reference}
Date: ${widget.receiptData.date}
Time: ${widget.receiptData.time}
Status: ${statusConfig['label']}

${widget.receiptData.network != null ? 'Network: ${widget.receiptData.network}' : ''}
${widget.receiptData.plan != null ? 'Plan: ${widget.receiptData.plan}' : ''}
${widget.receiptData.customer != null ? 'Customer: ${widget.receiptData.customer}' : ''}
${widget.receiptData.provider != null ? 'Provider: ${widget.receiptData.provider}' : ''}
${widget.receiptData.accountNumber != null ? 'Account: ${widget.receiptData.accountNumber}' : ''}
${widget.receiptData.bank != null ? 'Bank: ${widget.receiptData.bank}' : ''}
${widget.receiptData.fee != null ? 'Fee: ${_formatAmount(widget.receiptData.fee!)}' : ''}
${widget.receiptData.description != null ? 'Description: ${widget.receiptData.description}' : ''}

----------------------------
Thank you for using RimaPay
Contact: support@rimapay.com
www.rimapay.com
===========================
    ''';
  }

  /// Styled PDF via the share sheet (Save to Files/Downloads, WhatsApp…);
  /// downloads on web. Replaces the old save into the hidden app folder.
  Future<void> _downloadReceipt() async {
    final d = widget.receiptData;
    final status = _getStatusConfig(d.status)['label']?.toString() ?? 'Successful';
    try {
      await shareReceiptPdf(ReceiptPdfData(
        title: d.type,
        amount: d.amount,
        isCredit: d.isCredit,
        status: status,
        reference: d.reference,
        dateText: '${d.date}, ${d.time}',
        details: [
          MapEntry('Transaction', d.type),
          MapEntry(d.isCredit ? 'From' : 'To', d.recipient),
          if (d.network != null) MapEntry('Network', d.network!),
          if (d.plan != null) MapEntry('Plan', d.plan!),
          if (d.customer != null) MapEntry('Customer', d.customer!),
          if (d.provider != null) MapEntry('Provider', d.provider!),
          if (d.accountNumber != null) MapEntry('Account', d.accountNumber!),
          if (d.bank != null) MapEntry('Bank', d.bank!),
          if (d.fee != null) MapEntry('Fee', _formatAmount(d.fee!)),
        ],
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't create the receipt. Please try again."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareReceipt() async {
    final receiptContent = _generateReceiptContent();
    try {
      await Share.share(
        receiptContent,
        subject: 'RimaPay Transaction Receipt',
      );
    } catch (error) {
      // Fallback - copy to clipboard
      await Clipboard.setData(ClipboardData(text: receiptContent));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt copied to clipboard'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(widget.receiptData.status);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: context.bgPage,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Custom Header
                Container(
                  color: Theme.of(context).cardColor,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: context.border,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Back Button
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.bgCardElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  AppNavigation.goToHome(context);
                                },
                                child: Icon(
                                  Icons.arrow_back,
                                  color: context.textPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          // Logo and Title
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // RimaPay Logo placeholder
                                // Image.asset(
                                //   "assets/images/mild.png",
                                //   width: 24,
                                //   height: 24,
                                // ),
                                // const SizedBox(width: 8),
                                Text(
                                  "Receipt",
                                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 16 : 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Spacer for centering
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      children: [
                        // Status Card
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                                decoration: BoxDecoration(
                                  color: statusConfig['bg'],
                                  border: Border.all(
                                    color: statusConfig['border'],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    ScaleTransition(
                                      scale: _statusScaleAnimation,
                                      child: Container(
                                        width: isSmallScreen ? 48 : 64,
                                        height: isSmallScreen ? 48 : 64,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: widget.receiptData.status.toLowerCase() == 'success'
                                              ? Icon(
                                                  Icons.check,
                                                  color: statusConfig['icon'],
                                                  size: isSmallScreen ? 24 : 32,
                                                )
                                              : Text(
                                                  _getTransactionIcon(widget.receiptData.type),
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 18 : 24,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Transaction ${statusConfig['label']}',
                                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 16 : 20,
                                        color: statusConfig['text'],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your ${widget.receiptData.type.toLowerCase()} transaction has been ${statusConfig['label'].toString().toLowerCase()}',
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: statusConfig['text'],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Transaction Details Card
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // RimaPay Logo Header
                                    Container(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: context.border,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          RimapayLogo(
                                            width: isSmallScreen ? 24 : 32,
                                            height: isSmallScreen ? 24 : 32,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'RimaPay',
                                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isSmallScreen ? 16 : 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Amount
                                    Column(
                                      children: [
                                        Text(
                                          'Amount',
                                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _signedAmount,
                                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                            fontWeight: FontWeight.w900,
                                            fontSize: isSmallScreen ? 24 : 32,
                                            color: _directionColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _directionColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                                color: _directionColor.withOpacity(0.35)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                widget.receiptData.isCredit
                                                    ? Icons.arrow_downward_rounded
                                                    : Icons.arrow_upward_rounded,
                                                size: 13,
                                                color: _directionColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _directionLabel,
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 11 : 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: _directionColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.receiptData.fee != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Fee: ${_formatAmount(widget.receiptData.fee!)}',
                                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                              fontSize: isSmallScreen ? 10 : 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Transaction Info
                                    Column(
                                      children: [
                                        _buildDetailRow('Type:', widget.receiptData.type, isSmallScreen),
                                        _buildDetailRow(_partyLabel, widget.receiptData.recipient, isSmallScreen),
                                        if (widget.receiptData.network != null) _buildDetailRow('Network:', widget.receiptData.network!, isSmallScreen),
                                        if (widget.receiptData.plan != null) _buildDetailRow('Plan:', widget.receiptData.plan!, isSmallScreen),
                                        if (widget.receiptData.customer != null) _buildDetailRow('Customer:', widget.receiptData.customer!, isSmallScreen),
                                        if (widget.receiptData.provider != null) _buildDetailRow('Provider:', widget.receiptData.provider!, isSmallScreen),
                                        if (widget.receiptData.accountNumber != null) _buildDetailRow('Account:', widget.receiptData.accountNumber!, isSmallScreen, isMonospace: true),
                                        if (widget.receiptData.bank != null) _buildDetailRow('Bank:', widget.receiptData.bank!, isSmallScreen),
                                        _buildDetailRow('Date:', widget.receiptData.date, isSmallScreen),
                                        _buildDetailRow('Time:', widget.receiptData.time, isSmallScreen),
                                        if (widget.receiptData.description != null) _buildDetailRow('Description:', widget.receiptData.description!, isSmallScreen),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Reference Card
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Transaction Reference',
                                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                              fontSize: isSmallScreen ? 10 : 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.receiptData.reference,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).colorScheme.onSurface,
                                            fontSize: isSmallScreen ? 11 : 13,
                                          ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: _copyReference,
                                          child: Icon(
                                            Icons.copy,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Column(
                                children: [
                                  // Download PDF Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _downloadReceipt,
                                      icon: const Icon(Icons.download, size: 16),
                                      label: Text(
                                        'Download PDF Receipt',
                                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                          fontSize: isSmallScreen ? 14 : 16,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary500,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Share Receipt Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: _shareReceipt,
                                      icon: const Icon(Icons.share, size: 16),
                                      label: Text(
                                        'Share Receipt',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary600,
                                          fontSize: isSmallScreen ? 13 : 15,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: context.isDark ? const Color(0xFF1E4D33) : Colors.green.shade200,
                                          width: 2,
                                        ),
                                        backgroundColor: context.bgBrandSubtle,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Footer
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Column(
                                children: [
                                  Text(
                                    'Thank you for using RimaPay',
                                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      fontSize: isSmallScreen ? 11 : 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Questions? Contact support@rimapay.com',
                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontSize: isSmallScreen ? 10 : 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 12 : 14,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// Updated ReceiptData class with additional properties to match TypeScript interface
class ReceiptData {
  final String id;
  final String type;
  final String amount;
  final String recipient;
  final String date;
  final String time;
  final String status; // 'success' | 'pending' | 'failed'
  final String reference;
  final String? network;
  final String? plan;
  final String? customer;
  final String? provider;
  final String? accountNumber;
  final String? bank;
  final String? description;
  final String? fee;

  /// True when money came IN (credit); false for money going out (debit).
  final bool isCredit;

  const ReceiptData({
    required this.id,
    required this.type,
    required this.amount,
    required this.recipient,
    required this.date,
    required this.time,
    required this.status,
    required this.reference,
    this.network,
    this.plan,
    this.customer,
    this.provider,
    this.accountNumber,
    this.bank,
    this.description,
    this.fee,
    this.isCredit = false,
  });

  // Factory constructor for creating ReceiptData from JSON
  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: json['amount'] as String,
      recipient: json['recipient'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      status: json['status'] as String,
      reference: json['reference'] as String,
      network: json['network'] as String?,
      plan: json['plan'] as String?,
      customer: json['customer'] as String?,
      provider: json['provider'] as String?,
      accountNumber: json['accountNumber'] as String?,
      bank: json['bank'] as String?,
      description: json['description'] as String?,
      fee: json['fee'] as String?,
      isCredit: json['isCredit'] == true,
    );
  }

  // Method for converting ReceiptData to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'recipient': recipient,
      'date': date,
      'time': time,
      'status': status,
      'reference': reference,
      if (network != null) 'network': network,
      if (plan != null) 'plan': plan,
      if (customer != null) 'customer': customer,
      if (provider != null) 'provider': provider,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (bank != null) 'bank': bank,
      if (description != null) 'description': description,
      if (fee != null) 'fee': fee,
      'isCredit': isCredit,
    };
  }

  // CopyWith method for creating modified copies
  ReceiptData copyWith({
    String? id,
    String? type,
    String? amount,
    String? recipient,
    String? date,
    String? time,
    String? status,
    String? reference,
    String? network,
    String? plan,
    String? customer,
    String? provider,
    String? accountNumber,
    String? bank,
    String? description,
    String? fee,
  }) {
    return ReceiptData(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      recipient: recipient ?? this.recipient,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      network: network ?? this.network,
      plan: plan ?? this.plan,
      customer: customer ?? this.customer,
      provider: provider ?? this.provider,
      accountNumber: accountNumber ?? this.accountNumber,
      bank: bank ?? this.bank,
      description: description ?? this.description,
      fee: fee ?? this.fee,
    );
  }

  // Helper methods
  bool get isSuccessful => status.toLowerCase() == 'success';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
  String get formattedAmount => '₦$amount';
  String? get formattedFee => fee != null ? '₦$fee' : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReceiptData &&
        other.id == id &&
        other.type == type &&
        other.amount == amount &&
        other.recipient == recipient &&
        other.date == date &&
        other.time == time &&
        other.status == status &&
        other.reference == reference &&
        other.network == network &&
        other.plan == plan &&
        other.customer == customer &&
        other.provider == provider &&
        other.accountNumber == accountNumber &&
        other.bank == bank &&
        other.description == description &&
        other.fee == fee;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      amount,
      recipient,
      date,
      time,
      status,
      reference,
      network,
      plan,
      customer,
      provider,
      accountNumber,
      bank,
      description,
      fee,
    );
  }

  @override
  String toString() {
    return 'ReceiptData(id: $id, type: $type, amount: $amount, recipient: $recipient, date: $date, time: $time, status: $status, reference: $reference, network: $network, plan: $plan, customer: $customer, provider: $provider, accountNumber: $accountNumber, bank: $bank, description: $description, fee: $fee)';
  }
}
