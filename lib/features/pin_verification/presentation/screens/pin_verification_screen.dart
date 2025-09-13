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

class _PinVerificationScreenState extends State<PinVerificationScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<String> _pin = ['', '', '', ''];
  bool _isLoading = false;
  String _error = '';
  int _focusIndex = 0;
  bool _showPin = false;
  List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFocusNodes();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _initializeFocusNodes() {
    _focusNodes = List.generate(4, (index) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handlePinInput(int index, String value) {
    if (value.length > 1) return;

    setState(() {
      _pin[index] = value;
      _error = '';
    });

    // Move to next input
    if (value.isNotEmpty && index < 3) {
      setState(() {
        _focusIndex = index + 1;
      });
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _handleKeyDown(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace && _pin[index].isEmpty && index > 0) {
        setState(() {
          _focusIndex = index - 1;
        });
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _handleSubmit() async {
    final pinValue = _pin.join('');

    if (pinValue.length != 4) {
      setState(() {
        _error = 'Please enter your 4-digit PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    _loadingController.repeat();

    // Simulate PIN verification - Made instant (300ms)
    await Future.delayed(const Duration(milliseconds: 300));

    _loadingController.stop();

    // For demo purposes, accept any 4-digit PIN except "0000"
    if (pinValue == '0000') {
      setState(() {
        _error = 'Invalid PIN. Please try again.';
        _isLoading = false;
        _pin = ['', '', '', ''];
        _focusIndex = 0;
      });
      _focusNodes[0].requestFocus();
    } else {
      setState(() {
        _isLoading = false;
      });
      _navigateToSuccess();
    }
  }

  void _navigateToSuccess() {
    // Navigate to success screen or call success callback
    context.go('/success', extra: widget.transactionData);
  }

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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.15, 0.15, 1.0],
            colors: [
              AppColors.primary500,
              AppColors.primary500,
              const Color(0xFFF0F9F4),
              const Color(0xFFF8FCF9),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildTransactionSummary(),
                          const SizedBox(height: 16),
                          _buildPinEntry(),
                          const SizedBox(height: 24),
                          _buildConfirmButton(),
                          SizedBox(height: isSmallScreen ? 16 : 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Confirm Transaction',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSummary() {
    final type = widget.transactionData['type']?.toString() ?? '';
    final amount = widget.transactionData['amount']?.toString() ?? '0';
    final recipient = widget.transactionData['recipient']?.toString() ?? '';
    final network = widget.transactionData['network']?.toString();
    final plan = widget.transactionData['plan']?.toString();
    final customer = widget.transactionData['customer']?.toString();
    final accountNumber = widget.transactionData['accountNumber']?.toString();
    final bank = widget.transactionData['bank']?.toString();
    final provider = widget.transactionData['provider']?.toString();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _getTransactionIcon(type),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipient,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                _formatAmount(amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          if (network != null || plan != null || customer != null || accountNumber != null || bank != null || provider != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFF3F4F6),
            ),
            const SizedBox(height: 12),
            ...[
              if (network != null) _buildDetailRow('Network:', network),
              if (plan != null) _buildDetailRow('Plan:', plan),
              if (customer != null) _buildDetailRow('Customer:', customer),
              if (accountNumber != null) _buildDetailRow('Account:', accountNumber),
              if (bank != null) _buildDetailRow('Bank:', bank),
              if (provider != null) _buildDetailRow('Provider:', provider),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF101828),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinEntry() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter Transaction PIN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter your 4-digit PIN to authorize this transaction',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // PIN Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 48,
                height: 48,
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) => _handleKeyDown(event, index),
                  child: TextField(
                    focusNode: _focusNodes[index],
                    obscureText: !_showPin,
                    textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                    
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => _handlePinInput(index, value),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Show/Hide PIN Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _showPin = !_showPin;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showPin ? Icons.visibility_off : Icons.visibility,
                  size: 12,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Text(
                  _showPin ? 'Hide PIN' : 'Show PIN',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Error Message
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 12,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Security Note
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Transaction',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your PIN is encrypted and never stored for security.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF1D4ED8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    final pinValue = _pin.join('');
    final isEnabled = !_isLoading && pinValue.length == 4;

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary500,
            AppColors.primary600,
            AppColors.primary700,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isEnabled ? _handleSubmit : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _loadingController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _loadingController.value * 2 * 3.14159,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Processing...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Opacity(
                    opacity: isEnabled ? 1.0 : 0.5,
                    child: Text(
                      'Confirm & Pay ${_formatAmount(widget.transactionData['amount']?.toString() ?? '0')}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
