import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class ReceiptScreen extends StatefulWidget {
  final ReceiptData receiptData;

  const ReceiptScreen({
    super.key,
    required this.receiptData,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final appState = context.watch<AppStateProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(localizations.receipt),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.navigateToHome();
         //   appState.setActiveTab('home');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadReceipt,
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildReceiptCard(localizations),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(localizations, appState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReceiptHeader(localizations),
          const SizedBox(height: 32),
          _buildTransactionDetails(localizations),
          const SizedBox(height: 24),
          _buildReceiptFooter(localizations),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader(AppLocalizations localizations) {
    return Column(
      children: [
        // RimaPay Logo
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'R',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'RimaPay',
          style: AppTextStyles.h5.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Transaction Receipt",
          style: AppTextStyles.body2.copyWith(
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                widget.receiptData.status.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails(AppLocalizations localizations) {
    return Column(
      children: [
        _buildDetailRow(
          localizations.translate('type'),
          widget.receiptData.type,
        ),
        const Divider(height: 24),
        _buildDetailRow(
          localizations.amount,
          '₦${widget.receiptData.amount}',
          isAmount: true,
        ),
        const Divider(height: 24),
        _buildDetailRow(
          localizations.recipient,
          widget.receiptData.recipient,
        ),
        if (widget.receiptData.network != null) ...[
          const Divider(height: 24),
          _buildDetailRow(
            localizations.translate('network'),
            widget.receiptData.network!,
          ),
        ],
        if (widget.receiptData.accountNumber != null) ...[
          const Divider(height: 24),
          _buildDetailRow(
            localizations.accountNumber,
            widget.receiptData.accountNumber!,
          ),
        ],
        if (widget.receiptData.bank != null) ...[
          const Divider(height: 24),
          _buildDetailRow(
            localizations.translate('bank'),
            widget.receiptData.bank!,
          ),
        ],
        const Divider(height: 24),
        _buildDetailRow(
          localizations.reference,
          widget.receiptData.reference,
        ),
        const Divider(height: 24),
        _buildDetailRow(
          localizations.translate('date'),
          widget.receiptData.date,
        ),
        const Divider(height: 24),
        _buildDetailRow(
          localizations.translate('time'),
          widget.receiptData.time,
        ),
        if (widget.receiptData.fee != null) ...[
          const Divider(height: 24),
          _buildDetailRow(
            localizations.fee,
            '₦${widget.receiptData.fee}',
          ),
        ],
        if (widget.receiptData.description != null) ...[
          const Divider(height: 24),
          _buildDetailRow(
            localizations.description,
            widget.receiptData.description!,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.body2.copyWith(
              fontWeight: isAmount ? FontWeight.w700 : FontWeight.w600,
              color: isAmount ? AppColors.primary500 : AppColors.neutral900,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptFooter(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: AppColors.neutral600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.translate('secureTransaction'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: AppColors.neutral600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.translate('cbnLicensed'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations, AppStateProvider appState) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareReceipt,
                icon: const Icon(Icons.share),
                label: Text(localizations.translate('shareReceipt')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _downloadReceipt,
                icon: const Icon(Icons.download),
                label: Text(localizations.translate('downloadReceipt')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              appState.navigateToHome();
             // appState.setActiveTab('home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              localizations.translate('backToHome'),
              style: AppTextStyles.buttonMedium,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.receiptData.status.toLowerCase()) {
      case 'success':
        return AppColors.success;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.neutral600;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.receiptData.status.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  void _shareReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.translate('receiptShared')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.translate('receiptDownloaded')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class ReceiptData {
  final String type;
  final String amount;
  final String recipient;
  final String reference;
  final String date;
  final String time;
  final String status;
  final String? network;
  final String? accountNumber;
  final String? bank;
  final String? fee;
  final String? description;

  const ReceiptData({
    required this.type,
    required this.amount,
    required this.recipient,
    required this.reference,
    required this.date,
    required this.time,
    required this.status,
    this.network,
    this.accountNumber,
    this.bank,
    this.fee,
    this.description,
  });

  // Factory constructor for creating ReceiptData from JSON
  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      type: json['type'] as String,
      amount: json['amount'] as String,
      recipient: json['recipient'] as String,
      reference: json['reference'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      status: json['status'] as String,
      network: json['network'] as String?,
      accountNumber: json['accountNumber'] as String?,
      bank: json['bank'] as String?,
      fee: json['fee'] as String?,
      description: json['description'] as String?,
    );
  }

  // Method for converting ReceiptData to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'recipient': recipient,
      'reference': reference,
      'date': date,
      'time': time,
      'status': status,
      if (network != null) 'network': network,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (bank != null) 'bank': bank,
      if (fee != null) 'fee': fee,
      if (description != null) 'description': description,
    };
  }

  // CopyWith method for creating modified copies
  ReceiptData copyWith({
    String? type,
    String? amount,
    String? recipient,
    String? reference,
    String? date,
    String? time,
    String? status,
    String? network,
    String? accountNumber,
    String? bank,
    String? fee,
    String? description,
  }) {
    return ReceiptData(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      recipient: recipient ?? this.recipient,
      reference: reference ?? this.reference,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      network: network ?? this.network,
      accountNumber: accountNumber ?? this.accountNumber,
      bank: bank ?? this.bank,
      fee: fee ?? this.fee,
      description: description ?? this.description,
    );
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ReceiptData &&
        other.type == type &&
        other.amount == amount &&
        other.recipient == recipient &&
        other.reference == reference &&
        other.date == date &&
        other.time == time &&
        other.status == status &&
        other.network == network &&
        other.accountNumber == accountNumber &&
        other.bank == bank &&
        other.fee == fee &&
        other.description == description;
  }

  // Hash code
  @override
  int get hashCode {
    return type.hashCode ^
        amount.hashCode ^
        recipient.hashCode ^
        reference.hashCode ^
        date.hashCode ^
        time.hashCode ^
        status.hashCode ^
        network.hashCode ^
        accountNumber.hashCode ^
        bank.hashCode ^
        fee.hashCode ^
        description.hashCode;
  }

  // toString method for debugging
  @override
  String toString() {
    return 'ReceiptData(type: $type, amount: $amount, recipient: $recipient, reference: $reference, date: $date, time: $time, status: $status, network: $network, accountNumber: $accountNumber, bank: $bank, fee: $fee, description: $description)';
  }

  // Factory constructors for different transaction types
  
  // Bank Transfer Receipt
  factory ReceiptData.bankTransfer({
    required String amount,
    required String recipient,
    required String reference,
    required String date,
    required String time,
    required String status,
    required String accountNumber,
    required String bank,
    String? fee,
    String? description,
  }) {
    return ReceiptData(
      type: 'Bank Transfer',
      amount: amount,
      recipient: recipient,
      reference: reference,
      date: date,
      time: time,
      status: status,
      accountNumber: accountNumber,
      bank: bank,
      fee: fee,
      description: description,
    );
  }

  // Airtime Purchase Receipt
  factory ReceiptData.airtimePurchase({
    required String amount,
    required String recipient,
    required String reference,
    required String date,
    required String time,
    required String status,
    required String network,
    String? fee,
    String? description,
  }) {
    return ReceiptData(
      type: 'Airtime',
      amount: amount,
      recipient: recipient,
      reference: reference,
      date: date,
      time: time,
      status: status,
      network: network,
      fee: fee,
      description: description,
    );
  }

  // Data Purchase Receipt
  factory ReceiptData.dataPurchase({
    required String amount,
    required String recipient,
    required String reference,
    required String date,
    required String time,
    required String status,
    required String network,
    String? fee,
    String? description,
  }) {
    return ReceiptData(
      type: 'Data',
      amount: amount,
      recipient: recipient,
      reference: reference,
      date: date,
      time: time,
      status: status,
      network: network,
      fee: fee,
      description: description,
    );
  }

  // Electricity Bill Payment Receipt
  factory ReceiptData.electricityPayment({
    required String amount,
    required String recipient,
    required String reference,
    required String date,
    required String time,
    required String status,
    String? fee,
    String? description,
  }) {
    return ReceiptData(
      type: 'Electricity',
      amount: amount,
      recipient: recipient,
      reference: reference,
      date: date,
      time: time,
      status: status,
      fee: fee,
      description: description,
    );
  }

  // Cable TV Subscription Receipt
  factory ReceiptData.cableTVSubscription({
    required String amount,
    required String recipient,
    required String reference,
    required String date,
    required String time,
    required String status,
    String? fee,
    String? description,
  }) {
    return ReceiptData(
      type: 'Cable TV',
      amount: amount,
      recipient: recipient,
      reference: reference,
      date: date,
      time: time,
      status: status,
      fee: fee,
      description: description,
    );
  }

  // Wallet Transfer Receipt
  factory ReceiptData.walletTransfer({
    required String amount,
    required String recipient,
    required String reference,
    required String date,
    required String time,
    required String status,
    String? fee,
    String? description,
  }) {
    return ReceiptData(
      type: 'Wallet Transfer',
      amount: amount,
      recipient: recipient,
      reference: reference,
      date: date,
      time: time,
      status: status,
      fee: fee,
      description: description,
    );
  }

  // Wallet Funding Receipt
  factory ReceiptData.walletFunding({
    required String amount,
    required String reference,
    required String date,
    required String time,
    required String status,
    String? fee,
    String? description,
  }) {
    return ReceiptData(
      type: 'Wallet Funding',
      amount: amount,
      recipient: 'RimaPay Wallet',
      reference: reference,
      date: date,
      time: time,
      status: status,
      fee: fee,
      description: description,
    );
  }

  // Helper method to check if transaction was successful
  bool get isSuccessful => status.toLowerCase() == 'success';

  // Helper method to check if transaction is pending
  bool get isPending => status.toLowerCase() == 'pending';

  // Helper method to check if transaction failed
  bool get isFailed => status.toLowerCase() == 'failed';

  // Helper method to get formatted amount with currency
  String get formattedAmount => '₦$amount';

  // Helper method to get formatted fee with currency
  String? get formattedFee => fee != null ? '₦$fee' : null;
}