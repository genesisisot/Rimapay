import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/success/presentation/screens/success_screen.dart';

class PinVerificationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> transactionData;

  const PinVerificationScreen({
    super.key,
    required this.transactionData,
  });

  @override
  ConsumerState<PinVerificationScreen> createState() =>
      _PinVerificationScreenState();
}

class _PinVerificationScreenState extends ConsumerState<PinVerificationScreen>
    with TickerProviderStateMixin {
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

    final extra = widget.transactionData;
    final isTransfer = extra['type'] == 'transfer';

    if (isTransfer) {
      final notifier = ref.read(transactionProviders.notifier);
      final refNo = await notifier.processTransfer(
        senderAccountNumber:
            extra['senderAccountNumber'] as String? ?? '',
        recipientAccountNumber:
            extra['accountNumber'] as String? ?? '',
        recipientBankCode: extra['bankCode'] as String? ?? '',
        recipientBankName: extra['bank'] as String? ?? '',
        amount:
            double.tryParse(extra['amount']?.toString() ?? '0') ?? 0,
        narration: extra['note'] as String?,
        pin: pinValue,
        isRimaPay: extra['isRimaPay'] == true,
      );

      _loadingController.stop();

      if (refNo.isNotEmpty && mounted) {
        _saveBeneficiary(extra);
        await Provider.of<AuthProvider>(context, listen: false).fetchAccounts();
        setState(() => _isLoading = false);
        context.go('/success', extra: SuccessScreenProps(
          transactionType: 'Transfer',
          amount: '₦${double.tryParse(extra['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
          recipient: extra['recipientName']?.toString() ?? extra['recipient']?.toString() ?? '',
          transactionId: refNo,
        ));
      } else if (mounted) {
        final error =
            ref.read(transactionProviders).error ?? 'Transaction failed. Please try again.';
        setState(() {
          _error = error;
          _isLoading = false;
          _pin = ['', '', '', ''];
          _focusIndex = 0;
          _loadingController.stop();
        });
        _focusNodes[0].requestFocus();
      }
    } else {
      // Non-transfer (airtime, bills, etc.) — keep mock for now
      await Future.delayed(const Duration(milliseconds: 300));
      _loadingController.stop();
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/success', extra: widget.transactionData);
      }
    }
  }

  void _saveBeneficiary(Map<String, dynamic> extra) async {
    final isRima = extra['isRimaPay'] == true;
    final name = extra['recipientName']?.toString() ?? extra['recipient']?.toString() ?? '';
    if (name.isEmpty) return;
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final colors = ['purple', 'blue', 'orange', 'green', 'red'];
    final color = colors[name.length % colors.length];

    final existing = await StorageService.getBeneficiaries();
    existing.removeWhere((b) =>
        isRima
            ? b['sub'] == extra['accountNumber']
            : b['account'] == extra['accountNumber']);

    existing.insert(0, isRima
        ? {'type': 'rimapay', 'name': name, 'sub': (extra['accountNumber'] ?? '').toString(), 'initials': initials, 'color': color}
        : {'type': 'bank', 'name': name, 'bank': (extra['bank'] ?? '').toString(), 'account': (extra['accountNumber'] ?? '').toString(), 'initials': initials, 'color': color});

    if (existing.length > 20) existing.removeRange(20, existing.length);
    await StorageService.saveBeneficiaries(existing);
  }

  String _formatAmount(String amount) {
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
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
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
            behavior: HitTestBehavior.opaque,
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
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
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
        color: Theme.of(context).cardColor,
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _getTransactionIcon(type),
                    style: TextStyle(fontSize: 20),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipient,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                        height: 1.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                _formatAmount(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E5C37),
                ),
              ),
            ],
          ),
          if (network != null || plan != null || customer != null || accountNumber != null || bank != null || provider != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 1,
              color: Theme.of(context).scaffoldBackgroundColor,
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
        spacing: 5,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
        color: Theme.of(context).cardColor,
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF0E5C37),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter Transaction PIN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your 4-digit PIN to authorize this transaction',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                    
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF166C46),
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
                const SizedBox(width: 8),
                Text(
                  _showPin ? 'Hide PIN' : 'Show PIN',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
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
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info,
                    size: 8,
                    color: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Transaction',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your PIN is encrypted and never stored for security.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
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
                        color: Theme.of(context).cardColor,
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
