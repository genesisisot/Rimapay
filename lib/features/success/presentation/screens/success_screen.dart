import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/features/receipt/presentation/screens/receipt_screen.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';

class SuccessScreenProps {
  final String transactionType;
  final String amount;
  final String recipient;
  final String transactionId;
  final bool canSaveBeneficiary;
  final BeneficiaryData? beneficiaryData;

  SuccessScreenProps({
    this.transactionType = "Payment",
    this.amount = "2000.00",
    this.recipient = "Service Provider",
    String? transactionId,
    this.canSaveBeneficiary = true,
    this.beneficiaryData,
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

class SavedBeneficiaryData {
  final String name;
  final String accountNumber;
  final String bank;
  final String nickname;
  final bool isFavorite;
  final String dateAdded;

  SavedBeneficiaryData({
    required this.name,
    required this.accountNumber,
    required this.bank,
    required this.nickname,
    required this.isFavorite,
    required this.dateAdded,
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

  bool _showSaveBeneficiary = false;
  String _beneficiaryNickname = '';
  bool _markAsFavorite = false;

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
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _iconRotationController.dispose();
    super.dispose();
  }

  void _onHome() {
    context.go('/home');
  }

  void _handleShare() {
    final shareText = "${widget.props.transactionType} of ${widget.props.amount} successful. Transaction ID: ${widget.props.transactionId}";
    Share.share(shareText, subject: 'RimaPay Transaction Receipt');
  }

  void _handleDownload() {
    // Implement download receipt functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt saved to downloads'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onRepeatTransaction() {
    final type = widget.props.transactionType.toLowerCase();
    if (type.contains('airtime')) {
      context.go('/airtime');
    } else if (type.contains('data')) {
      context.go('/data');
    } else if (type.contains('electricity')) {
      context.go('/electricity');
    } else if (type.contains('cable')) {
      context.go('/cable');
    } else if (type.contains('transfer')) {
      context.go('/transfer');
    } else { context.go('/airtime');
    }
  }

  void _onSaveBeneficiary(SavedBeneficiaryData beneficiaryData) {
    // Implement save beneficiary functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beneficiary saved successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSaveBeneficiary() {
    if (widget.props.beneficiaryData != null) {
      final savedData = SavedBeneficiaryData(
        name: widget.props.beneficiaryData!.name,
        accountNumber: widget.props.beneficiaryData!.accountNumber,
        bank: widget.props.beneficiaryData!.bank,
        nickname: _beneficiaryNickname.isEmpty 
            ? widget.props.beneficiaryData!.name.split(' ')[0]
            : _beneficiaryNickname,
        isFavorite: _markAsFavorite,
        dateAdded: DateTime.now().toIso8601String(),
      );
      _onSaveBeneficiary(savedData);
    }
    setState(() {
      _showSaveBeneficiary = false;
      _beneficiaryNickname = '';
      _markAsFavorite = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = widget.props.transactionType.toLowerCase().contains('transfer');
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC), // slate-50
              Color(0xFFF0FDF4), // green-50/30
              Color(0xFFECFDF5), // emerald-50/50
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(

                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        
                        // Success Icon
                        _buildSuccessIcon(),
                        
                        const SizedBox(height: 32),
                        
                        // Success Message
                        _buildSuccessMessage(isTransfer),
                        
                        const SizedBox(height: 32),
                        
                        // Transaction Details
                        _buildTransactionDetails(),
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        _buildActionButtons(),
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
                          Color(0xFF4ADE80), // green-400
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
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A), // neutral-900
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your ${widget.props.transactionType.toLowerCase()} has been processed successfully',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B), // neutral-600
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
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                        widget.props.amount,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A), // neutral-900
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Transaction Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280), // neutral-500
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Transaction Info
                  _buildDetailRow('Service', widget.props.transactionType),
                  _buildDetailRow('Recipient', widget.props.recipient),
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
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280), // neutral-500
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A), // neutral-900
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
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280), // neutral-500
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981), // green-500
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Successful',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669), // green-600
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
                // Save Beneficiary Button (for transfers)
                if (widget.props.canSaveBeneficiary && widget.props.beneficiaryData != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showSaveBeneficiary = true;
                        });
                      },
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Save as Beneficiary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDF4), // green-50
                        foregroundColor: const Color(0xFF166534), // green-700
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFBBF7D0)), // green-200
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                
                // Share and Download Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleShare,
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.7),
                          foregroundColor: const Color(0xFF4B5563), // neutral-600
                          elevation: 0,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleDownload,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.7),
                          foregroundColor: const Color(0xFF4B5563), // neutral-600
                          elevation: 0,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // // Repeat Transaction Button
                // Container(
                //   width: double.infinity,
                //   margin: const EdgeInsets.only(bottom: 12),
                //   child: ElevatedButton.icon(
                //     onPressed: _onRepeatTransaction,
                //     icon: const Icon(Icons.refresh, size: 16),
                //     label: const Text('Repeat Transaction'),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: const Color(0xFFEFF6FF), // blue-50
                //       foregroundColor: const Color(0xFF1D4ED8), // blue-700
                //       elevation: 0,
                //       side: const BorderSide(color: Color(0xFFBFDBFE)), // blue-200
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //     ),
                //   ),
                // ),
                
                // // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _onHome,
                    icon: const Icon(Icons.home, size: 16),
                    label: const Text('Back to Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A), // green-600
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF16A34A).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            child: Text(
              'Transaction processed securely by RimaPay',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF9CA3AF).withOpacity(0.8), // neutral-400
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime() {
    final now = DateTime.now();
    final time = TimeOfDay.fromDateTime(now);
    return "${now.day}/${now.month}/${now.year} ${time.format(context)}";
  }

  // Save Beneficiary Modal
  Widget _buildSaveBeneficiaryModal() {
    if (!_showSaveBeneficiary) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSaveBeneficiary = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismissal when tapping on modal
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Save Beneficiary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A), // neutral-900
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showSaveBeneficiary = false;
                          });
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6), // neutral-100
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF4B5563), // neutral-600
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Beneficiary Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB), // neutral-50
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.props.beneficiaryData?.name ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A), // neutral-900
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.props.beneficiaryData?.accountNumber} • ${widget.props.beneficiaryData?.bank}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563), // neutral-600
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Nickname Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nickname (Optional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151), // neutral-700
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _beneficiaryNickname = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: widget.props.beneficiaryData?.name.split(' ')[0] ?? 'Enter nickname',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)), // neutral-200
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10B981)), // green-500
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        style: const TextStyle(fontSize: 14),
                        maxLength: 20,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mark as Favorite
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _markAsFavorite = !_markAsFavorite;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _markAsFavorite 
                              ? const Color(0xFFF59E0B) // yellow-500
                              : const Color(0xFFE5E7EB), // neutral-200
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _markAsFavorite 
                            ? const Color(0xFFFEF3C7) // yellow-50
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _markAsFavorite ? Icons.star : Icons.star_border,
                            color: _markAsFavorite 
                                ? const Color(0xFFF59E0B) // yellow-500
                                : const Color(0xFF9CA3AF), // neutral-400
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mark as Favorite',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _markAsFavorite 
                                        ? const Color(0xFFA16207) // yellow-700
                                        : const Color(0xFF374151), // neutral-700
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Quick access for future transfers',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280), // neutral-500
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showSaveBeneficiary = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFFE5E7EB)), // neutral-200
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151), // neutral-700
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSaveBeneficiary,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981), // green-500
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: Stack(
  //       children: [
  //         // Main content
  //         Container(
  //           decoration: const BoxDecoration(
  //             gradient: LinearGradient(
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //               colors: [
  //                 Color(0xFFF8FAFC), // slate-50
  //                 Color(0xFFF0FDF4), // green-50/30
  //                 Color(0xFFECFDF5), // emerald-50/50
  //               ],
  //             ),
  //           ),
  //           child: SafeArea(
  //             child: Column(
  //               children: [
  //                 // Main content
  //                 Expanded(
  //                   child: Padding(
  //                     padding: const EdgeInsets.all(16.0),
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         const SizedBox(height: 32),
                          
  //                         // Success Icon
  //                         _buildSuccessIcon(),
                          
  //                         const SizedBox(height: 32),
                          
  //                         // Success Message
  //                         _buildSuccessMessage(widget.props.transactionType.toLowerCase().contains('transfer')),
                          
  //                         const SizedBox(height: 32),
                          
  //                         // Transaction Details
  //                         _buildTransactionDetails(),
                          
  //                         const SizedBox(height: 32),
                          
  //                         // Action Buttons
  //                         _buildActionButtons(),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
                  
  //                 // Footer
  //                 _buildFooter(),
  //               ],
  //             ),
  //           ),
  //         ),
          
  //         // Save Beneficiary Modal
  //         if (_showSaveBeneficiary) _buildSaveBeneficiaryModal(),
  //       ],
  //     ),
  //   );
  }