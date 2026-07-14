import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rimapay/core/providers/auth_provider.dart';
import 'package:rimapay/core/providers/transaction_provider.dart';
import 'package:rimapay/core/services/storage_service.dart';
import 'package:rimapay/features/profile/presentation/providers/profile_provider.dart';
import 'package:rimapay/features/success/presentation/screens/success_screen.dart';
import 'package:rimapay/shared/widgets/bill_screen_widgets.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  String _transferType = 'rimapay';

  // RimaPay form
  final _accountController = TextEditingController();
  final _accountFocus = FocusNode();

  // Shared
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();

  // Bank form
  final _bankAccountController = TextEditingController();
  final _bankAccountFocus = FocusNode();
  String _selectedBank = '';
  String _recipientName = '';
  String _bankError = '';
  bool _validating = false;

  String _rimaRecipientName = '';
  bool _validatingRima = false;

  // Seed list — doubles as fallback when the getbanks endpoint is unreachable
  // and as the source of per-bank success-rate badges (the API has no rate).
  List<Map<String, String>> _banks = [
    {'name': 'Access Bank',   'rate': '98', 'code': '044'},
    {'name': 'GTBank',        'rate': '97', 'code': '058'},
    {'name': 'Zenith Bank',   'rate': '97', 'code': '057'},
    {'name': 'First Bank',    'rate': '95', 'code': '011'},
    {'name': 'UBA',           'rate': '96', 'code': '033'},
    {'name': 'Kuda Bank',     'rate': '99', 'code': '50211'},
    {'name': 'Opay',          'rate': '98', 'code': '100004'},
    {'name': 'PalmPay',       'rate': '97', 'code': '100003'},
    {'name': 'Moniepoint',    'rate': '98', 'code': '50515'},
    {'name': 'Wema Bank',     'rate': '94', 'code': '035'},
    {'name': 'Stanbic IBTC',  'rate': '96', 'code': '039'},
    {'name': 'FCMB',          'rate': '93', 'code': '214'},
    {'name': 'Fidelity Bank', 'rate': '94', 'code': '070'},
    {'name': 'Ecobank',       'rate': '92', 'code': '050'},
  ];

  List<Map<String, String>> _rimaRecent = [];
  List<Map<String, String>> _bankRecent = [];

  @override
  void initState() {
    super.initState();
    _accountController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
    _bankAccountController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTypeSheet());
    _loadBeneficiaries();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    try {
      final api = ref.read(profileApiServiceProvider);
      final banks = await api.getBanks();
      if (!mounted || banks.isEmpty) return;
      // Preserve the hand-tuned success-rate badges by matching on code.
      final rateByCode = {
        for (final b in _banks) b['code']!: b['rate'] ?? '',
      };
      setState(() {
        _banks = banks
            .where((b) =>
                (b.bankName?.isNotEmpty ?? false) &&
                (b.institutionCode?.isNotEmpty ?? false))
            .map((b) => {
                  'name': b.bankName!,
                  'code': b.institutionCode!,
                  'rate': rateByCode[b.institutionCode] ?? '',
                })
            .toList();
      });
    } catch (_) {
      // Keep the seed list on any failure.
    }
  }

  Future<void> _loadBeneficiaries() async {
    final list = await StorageService.getBeneficiaries();
    if (!mounted) return;
    setState(() {
      _rimaRecent = list
          .where((b) => b['type'] == 'rimapay')
          .map((e) => Map<String, String>.from(e))
          .toList();
      _bankRecent = list
          .where((b) => b['type'] == 'bank')
          .map((e) => Map<String, String>.from(e))
          .toList();
    });
  }

  @override
  void dispose() {
    _accountController.dispose();
    _accountFocus.dispose();
    _amountController.dispose();
    _amountFocus.dispose();
    _noteController.dispose();
    _noteFocus.dispose();
    _bankAccountController.dispose();
    _bankAccountFocus.dispose();
    super.dispose();
  }

  void _showTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransferTypeSheet(
        current: _transferType,
        onSelect: (type) {
          setState(() => _transferType = type);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _validateRimaAccount() async {
    final acct = _accountController.text;
    if (acct.length != 10) {
      if (_rimaRecipientName.isNotEmpty) {
        setState(() => _rimaRecipientName = '');
      }
      return;
    }
    setState(() => _validatingRima = true);
    try {
      final api = ref.read(profileApiServiceProvider);
      final details = await api.getAccountDetails(acct);
      if (mounted) {
        setState(() {
          _validatingRima = false;
          _rimaRecipientName = details?.accountTitle ?? '';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _validatingRima = false;
          _rimaRecipientName = '';
        });
      }
    }
  }

  String _bankCodeFor(String bankName) {
    return _banks.firstWhere(
          (b) => b['name'] == bankName,
          orElse: () => const {'code': ''},
        )['code'] ??
        '';
  }

  Future<void> _validateBankAccount() async {
    final acct = _bankAccountController.text;
    if (acct.length != 10 || _selectedBank.isEmpty) {
      if (_recipientName.isNotEmpty || _bankError.isNotEmpty) {
        setState(() {
          _recipientName = '';
          _bankError = '';
        });
      }
      return;
    }
    final bankCode = _bankCodeFor(_selectedBank);
    if (bankCode.isEmpty) return;

    setState(() {
      _validating = true;
      _recipientName = '';
      _bankError = '';
    });
    try {
      final api = ref.read(profileApiServiceProvider);
      final res = await api.nameEnquiryInter(acct, bankCode);
      if (!mounted) return;
      setState(() {
        _validating = false;
        if (res != null && res.isResolved) {
          _recipientName = res.accountName;
          _bankError = '';
        } else {
          _recipientName = '';
          _bankError = res?.responseDesc?.isNotEmpty == true
              ? res!.responseDesc!
              : 'Could not verify this account. Check the number and bank.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validating = false;
        _recipientName = '';
        _bankError = 'Could not verify this account. Please try again.';
      });
    }
  }

  /// Bill-payment-style confirmation: a bottom sheet with the transaction
  /// summary + PIN pad, then runs the real transfer.
  void _startTransfer() {
    final auth = context.read<AuthProvider>();
    final senderAccount = auth.user?.accountNumber ?? '';
    final isRimaLocal = _transferType == 'rimapay';
    final recipient = isRimaLocal
        ? (_rimaRecipientName.isNotEmpty ? _rimaRecipientName : _accountController.text)
        : (_recipientName.isNotEmpty ? _recipientName : _bankAccountController.text);
    final bankName = isRimaLocal ? 'RimaPay' : _selectedBank;
    final bankCode = isRimaLocal ? '000' : _bankCodeFor(_selectedBank);
    final recipientAccount =
        isRimaLocal ? _accountController.text : _bankAccountController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final note = _noteController.text.trim();

    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Recipient', 'value': recipient},
        {
          'label': isRimaLocal ? 'RimaPay Account' : 'Account No.',
          'value': recipientAccount,
        },
        if (!isRimaLocal) {'label': 'Bank', 'value': bankName},
        {'label': 'Amount', 'value': '₦${amount.toStringAsFixed(2)}'},
        if (note.isNotEmpty) {'label': 'Note', 'value': note},
      ],
      onConfirmed: (pin) async {
        Navigator.pop(context); // close the confirm sheet
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF166C46)),
          ),
        );

        final notifier = ref.read(transactionProviders.notifier);
        final refNo = await notifier.processTransfer(
          senderAccountNumber: senderAccount,
          recipientAccountNumber: recipientAccount,
          recipientBankCode: bankCode,
          recipientBankName: bankName,
          amount: amount,
          narration: note.isEmpty ? null : note,
          pin: pin,
          isRimaPay: isRimaLocal,
        );

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

        if (refNo.isNotEmpty) {
          await _saveBeneficiary(
            isRima: isRimaLocal,
            name: recipient,
            bank: bankName,
            account: recipientAccount,
          );
          await context.read<AuthProvider>().fetchAccounts(silent: true);
          if (!mounted) return;
          context.go('/success',
              extra: SuccessScreenProps(
                transactionType: 'Transfer',
                amount: '₦${amount.toStringAsFixed(2)}',
                recipient: recipient,
                transactionId: refNo,
              ));
        } else {
          final error = ref.read(transactionProviders).error ??
              'Transaction failed. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: const Color(0xFFD33B31),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
        }
      },
    );
  }

  Future<void> _saveBeneficiary({
    required bool isRima,
    required String name,
    required String bank,
    required String account,
  }) async {
    if (name.isEmpty) return;
    final initials = name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    final colors = ['purple', 'blue', 'orange', 'green', 'red'];
    final color = colors[name.length % colors.length];

    final existing = await StorageService.getBeneficiaries();
    existing.removeWhere((b) =>
        isRima ? b['sub'] == account : b['account'] == account);
    existing.insert(
        0,
        isRima
            ? {'type': 'rimapay', 'name': name, 'sub': account, 'initials': initials, 'color': color}
            : {'type': 'bank', 'name': name, 'bank': bank, 'account': account, 'initials': initials, 'color': color});
    if (existing.length > 20) existing.removeRange(20, existing.length);
    await StorageService.saveBeneficiaries(existing);
  }

  void _showBankSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BankSelectorSheet(
        banks: _banks,
        onSelect: (bank) {
          setState(() {
            _selectedBank = bank;
            _recipientName = '';
            _bankError = '';
          });
          if (_bankAccountController.text.length == 10) _validateBankAccount();
        },
      ),
    );
  }

  Color _avatarColor(String colorKey) {
    switch (colorKey) {
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'orange':
        return const Color(0xFFF97316);
      case 'green':
        return const Color(0xFF166C46);
      default:
        return const Color(0xFF166C46);
    }
  }

  Widget _buildAmountChips() {
    const amounts = ['1000', '5000', '10000', '20000', '50000'];
    const labels = ['₦1,000', '₦5,000', '₦10,000', '₦20,000', '₦50,000'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(amounts.length, (i) {
        final isSelected = _amountController.text == amounts[i];
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _amountController.text = amounts[i]);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF166C46) : const Color(0xFFF0FAF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF166C46)
                    : const Color(0xFF166C46).withOpacity(0.25),
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF166C46),
                fontFamily: 'Effra',
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Green header ──
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Send Money',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Effra',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Toggle pill
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggleTab('To RimaPay', 'rimapay'),
                      _toggleTab('To Other Banks', 'bank'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _transferType == 'rimapay'
                  ? _buildRimaPayForm()
                  : _buildBankForm(),
            ),
          ),

          // ── CTA ──
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Builder(builder: (context) {
              final isRima = _transferType == 'rimapay';
              final amount = double.tryParse(_amountController.text) ?? 0;
              final balance = context.watch<AuthProvider>().user?.balance ?? 0;
              final insufficient = amount > 0 && amount > balance;
              final baseFilled = isRima
                  ? _accountController.text.isNotEmpty && _amountController.text.isNotEmpty
                  : _bankAccountController.text.length == 10 &&
                      _selectedBank.isNotEmpty &&
                      _recipientName.isNotEmpty &&
                      _amountController.text.isNotEmpty;
              final canContinue = baseFilled && !insufficient;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (insufficient) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD33B31).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD33B31).withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFD33B31), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Insufficient balance. Your wallet balance is ₦${balance.toStringAsFixed(2)}.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD33B31),
                                fontFamily: 'Effra',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: canContinue ? _startTransfer : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: canContinue ? AppColors.goldGradient : null,
                        color: canContinue ? null : Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canContinue
                            ? [
                                BoxShadow(
                                  color: AppColors.goldPrimary.withOpacity(0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          insufficient ? 'Insufficient Balance' : 'Continue',
                          style: TextStyle(
                            color: canContinue ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Effra',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, String value) {
    final active = _transferType == value;
    return GestureDetector(
      onTap: () => setState(() => _transferType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Effra',
            color: active ? const Color(0xFF0B4F2F) : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildRimaPayForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance card
        const BillAccountCard(),
        const SizedBox(height: 6),
        const BillPaginationDots(count: 2, active: 0),
        const SizedBox(height: 20),

        // Recent beneficiaries
        if (_rimaRecent.isNotEmpty) ...[
          Text(
            'Recent',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
              fontFamily: 'Effra',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _rimaRecent.length,
              itemBuilder: (_, i) {
                final r = _rimaRecent[i];
                final c = _avatarColor(r['color']!);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _accountController.text = r['sub']!;
                      _rimaRecipientName = r['name']!;
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: c.withOpacity(0.25), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              r['initials']!,
                              style: TextStyle(
                                color: c,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                fontFamily: 'Effra',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r['name']!.split(' ').first,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                            fontFamily: 'Effra',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Account/phone input
        BillFloatingField(
          controller: _accountController,
          focusNode: _accountFocus,
          label: 'RimaPay Account / Phone',
          hint: 'Account number or phone',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _validateRimaAccount(),
          suffix: _validatingRima
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF166C46)),
                )
              : null,
        ),
        const SizedBox(height: 14),

        // Resolved name
        if (_rimaRecipientName.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF166C46).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF166C46).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF166C46),
                  child: Text(
                    _rimaRecipientName[0],
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Effra',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _rimaRecipientName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Effra',
                      ),
                    ),
                    Text(
                      'RimaPay · ${_accountController.text}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'Effra',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.check_circle, color: Color(0xFF166C46), size: 20),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Amount
        BillAmountCard(
          controller: _amountController,
          focusNode: _amountFocus,
          minMax: 'Min ₦100 · Max ₦1,000,000',
        ),
        const SizedBox(height: 10),
        _buildAmountChips(),
        const SizedBox(height: 14),

        // Note
        BillFloatingField(
          controller: _noteController,
          focusNode: _noteFocus,
          label: 'Note (optional)',
          hint: 'What is this for?',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBankForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance card
        const BillAccountCard(),
        const SizedBox(height: 6),
        const BillPaginationDots(count: 2, active: 0),
        const SizedBox(height: 20),

        // Recent beneficiaries
        if (_bankRecent.isNotEmpty) ...[
          Text(
            'Recent',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
              fontFamily: 'Effra',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _bankRecent.length,
              itemBuilder: (_, i) {
                final r = _bankRecent[i];
                final c = _avatarColor(r['color']!);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _bankAccountController.text = r['account']!;
                      _selectedBank = r['bank']!;
                      _recipientName = r['name']!;
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: c.withOpacity(0.25), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              r['initials']!,
                              style: TextStyle(
                                color: c,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                fontFamily: 'Effra',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r['name']!.split(' ').first,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                            fontFamily: 'Effra',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Account number input
        BillFloatingField(
          controller: _bankAccountController,
          focusNode: _bankAccountFocus,
          label: 'Account Number',
          hint: 'Enter 10-digit account number',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (_) => _validateBankAccount(),
          suffix: _validating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF166C46)),
                )
              : null,
        ),
        const SizedBox(height: 14),

        // Bank selector button
        GestureDetector(
          onTap: _showBankSelector,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 58,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedBank.isNotEmpty
                    ? AppColors.goldPrimary.withOpacity(0.4)
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (_selectedBank.isEmpty) ...[
                    Icon(Icons.account_balance_outlined, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 10),
                    Text(
                      'Select Bank',
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        fontFamily: 'Effra',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    _BankLogo(bankName: _selectedBank, size: 32),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Bank',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF166C46),
                            fontFamily: 'Effra',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _selectedBank,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'Effra',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 22),
                ],
              ),
            ),
          ),
        ),

        // Recipient info (after account validation)
        if (_recipientName.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF166C46).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF166C46).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF166C46),
                  child: Text(
                    _recipientName[0],
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Effra',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _recipientName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Effra',
                      ),
                    ),
                    Text(
                      '$_selectedBank · ${_bankAccountController.text}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'Effra',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.check_circle, color: Color(0xFF166C46), size: 20),
              ],
            ),
          ),
        ],

        // Name-enquiry error
        if (_bankError.isNotEmpty && _recipientName.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD33B31).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD33B31).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFD33B31), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _bankError,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD33B31),
                      fontFamily: 'Effra',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Amount
        BillAmountCard(
          controller: _amountController,
          focusNode: _amountFocus,
          minMax: 'Min ₦100 · Max ₦5,000,000',
        ),
        const SizedBox(height: 10),
        _buildAmountChips(),
        const SizedBox(height: 14),

        // Note
        BillFloatingField(
          controller: _noteController,
          focusNode: _noteFocus,
          label: 'Note (optional)',
          hint: 'What is this for?',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Transfer Type Bottom Sheet ────────────────────────────────────────────────

class _TransferTypeSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelect;

  const _TransferTypeSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Text(
            'Send Money',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'Effra',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Where would you like to send money?',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontFamily: 'Effra'),
          ),
          const SizedBox(height: 28),
          _SheetOption(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: const Color(0xFFF2F7F3),
            iconColor: const Color(0xFF166C46),
            title: 'To RimaPay',
            subtitle: 'Send to any RimaPay account instantly',
            onTap: () => onSelect('rimapay'),
          ),
          const SizedBox(height: 12),
          _SheetOption(
            icon: Icons.account_balance_outlined,
            iconBg: const Color(0xFFeff6ff),
            iconColor: const Color(0xFF3B82F6),
            title: 'To Other Banks',
            subtitle: 'Send to any Nigerian bank account',
            onTap: () => onSelect('bank'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Effra',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontFamily: 'Effra'),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Bank Logo Widget ──────────────────────────────────────────────────────────

class _BankLogo extends StatelessWidget {
  final String bankName;
  final double size;
  const _BankLogo({required this.bankName, this.size = 40});

  static Color _color(String name) {
    switch (name) {
      case 'Access Bank':   return const Color(0xFFBD0000);
      case 'GTBank':        return const Color(0xFFEB2026);
      case 'Zenith Bank':   return const Color(0xFFE31837);
      case 'First Bank':    return const Color(0xFF003087);
      case 'UBA':           return const Color(0xFFBF0000);
      case 'Kuda Bank':     return const Color(0xFF6B0BD6);
      case 'Opay':          return const Color(0xFF00B140);
      case 'PalmPay':       return const Color(0xFF1A6FFF);
      case 'Moniepoint':    return const Color(0xFF004B87);
      case 'Wema Bank':     return const Color(0xFF742078);
      case 'Stanbic IBTC':  return const Color(0xFF003591);
      case 'FCMB':          return const Color(0xFF7B0099);
      case 'Fidelity Bank': return const Color(0xFF006A4D);
      case 'Ecobank':       return const Color(0xFF003876);
      default:              return const Color(0xFF166C46);
    }
  }

  static String _abbr(String name) {
    switch (name) {
      case 'Access Bank':   return 'ACC';
      case 'GTBank':        return 'GTB';
      case 'Zenith Bank':   return 'ZNB';
      case 'First Bank':    return 'FBN';
      case 'UBA':           return 'UBA';
      case 'Kuda Bank':     return 'KUDA';
      case 'Opay':          return 'OPAY';
      case 'PalmPay':       return 'PALM';
      case 'Moniepoint':    return 'MPNT';
      case 'Wema Bank':     return 'WEMA';
      case 'Stanbic IBTC':  return 'STIB';
      case 'FCMB':          return 'FCMB';
      case 'Fidelity Bank': return 'FDLY';
      case 'Ecobank':       return 'ECO';
      default:
        return name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(bankName);
    final abbr = _abbr(bankName);
    final radius = size * 0.25;
    final fontSize = size * 0.27;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Text(
          abbr,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'Effra',
          ),
        ),
      ),
    );
  }
}

// ── Bank Selector Bottom Sheet ────────────────────────────────────────────────

class _SuccessRateBadge extends StatelessWidget {
  final int rate;
  const _SuccessRateBadge({required this.rate});

  @override
  Widget build(BuildContext context) {
    final Color color = rate >= 97
        ? AppColors.goldPrimary
        : rate >= 94
            ? const Color(0xFFD4AF37)
            : const Color(0xFFD33B31);
    final Color bg = rate >= 97
        ? const Color(0xFFF2F7F3)
        : rate >= 94
            ? const Color(0xFFFDF8E7)
            : const Color(0xFFFEF2F2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$rate%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'Effra',
        ),
      ),
    );
  }
}

class _BankSelectorSheet extends StatefulWidget {
  final List<Map<String, String>> banks;
  final void Function(String name) onSelect;

  const _BankSelectorSheet({required this.banks, required this.onSelect});

  @override
  State<_BankSelectorSheet> createState() => _BankSelectorSheetState();
}

class _BankSelectorSheetState extends State<_BankSelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filtered {
    if (_query.isEmpty) return widget.banks;
    return widget.banks
        .where((b) => b['name']!.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          // Title
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Text(
                  'Select Bank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Effra',
                  ),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: false,
                      onChanged: (v) => setState(() => _query = v),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'Effra',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search banks…',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          fontFamily: 'Effra',
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bank list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final bank = _filtered[i];
                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onSelect(bank['name']!);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    child: Row(
                      children: [
                        _BankLogo(bankName: bank['name']!, size: 40),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            bank['name']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Effra',
                            ),
                          ),
                        ),
                        // Success rate badge
                        if (bank['rate'] != null && bank['rate']!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _SuccessRateBadge(rate: int.parse(bank['rate']!)),
                        ],
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, size: 18, color: Theme.of(context).dividerColor),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
