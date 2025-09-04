import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late TabController _tabController;
  String _selectedBank = '';
  String _recipientName = '';
  bool _isValidatingAccount = false;
  
  final List<Map<String, String>> _popularBanks = [
    {'name': 'Access Bank', 'code': '044', 'logo': '🏦'},
    {'name': 'GTBank', 'code': '058', 'logo': '🏛️'},
    {'name': 'First Bank', 'code': '011', 'logo': '🏢'},
    {'name': 'Zenith Bank', 'code': '057', 'logo': '🏦'},
    {'name': 'UBA', 'code': '033', 'logo': '🏛️'},
    {'name': 'Kuda Bank', 'code': '090267', 'logo': '💳'},
    {'name': 'Opay', 'code': '999992', 'logo': '📱'},
    {'name': 'PalmPay', 'code': '999991', 'logo': '🌴'},
  ];

  final List<Map<String, String>> _recentRecipients = [
    {
      'name': 'Funmi Adebayo',
      'bank': 'GTBank',
      'account': '0123456789',
      'initials': 'FA',
      'lastUsed': '2 days ago'
    },
    {
      'name': 'David Okafor',
      'bank': 'Access Bank', 
      'account': '0987654321',
      'initials': 'DO',
      'lastUsed': '1 week ago'
    },
    {
      'name': 'Sarah Johnson',
      'bank': 'Zenith Bank',
      'account': '1122334455',
      'initials': 'SJ',
      'lastUsed': '2 weeks ago'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _accountNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final appState = context.watch<AppStateProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.transfer),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.navigateToHome();
            //appState.setActiveTab('home');
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.translate('bankTransfer')),
            Tab(text: localizations.translate('walletTransfer')),
            Tab(text: localizations.translate('recent')),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBankTransferTab(localizations, appState),
            _buildWalletTransferTab(localizations, appState),
            _buildRecentTab(localizations, appState),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTransferTab(AppLocalizations localizations, AppStateProvider appState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBankSelection(localizations),
                    const SizedBox(height: 24),
                    _buildAccountNumberInput(localizations),
                    const SizedBox(height: 24),
                    if (_recipientName.isNotEmpty) ...[
                      _buildRecipientInfo(localizations),
                      const SizedBox(height: 24),
                    ],
                    _buildAmountInput(localizations),
                    const SizedBox(height: 24),
                    _buildDescriptionInput(localizations),
                  ],
                ),
              ),
            ),
            _buildContinueButton(localizations, appState),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletTransferTab(AppLocalizations localizations, AppStateProvider appState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildWalletTransferOptions(localizations),
          const Spacer(),
          _buildContinueButton(localizations, appState),
        ],
      ),
    );
  }

  Widget _buildRecentTab(AppLocalizations localizations, AppStateProvider appState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('recentRecipients'),
            style: AppTextStyles.h6,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _recentRecipients.length,
              itemBuilder: (context, index) {
                final recipient = _recentRecipients[index];
                return _buildRecentRecipientCard(recipient, localizations, appState);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.selectBank,
          style: AppTextStyles.h6,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _popularBanks.length,
            itemBuilder: (context, index) {
              final bank = _popularBanks[index];
              final isSelected = _selectedBank == bank['name'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBank = bank['name']!;
                    _recipientName = ''; // Reset recipient when changing bank
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary500.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary500 : AppColors.neutral200,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bank['logo']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bank['name']!,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary500 : AppColors.neutral700,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountNumberInput(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.accountNumber,
          style: AppTextStyles.h6,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          decoration: InputDecoration(
            hintText: '0123456789',
            prefixIcon: const Icon(Icons.account_balance),
            suffixIcon: _isValidatingAccount
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            counterText: '',
          ),
          onChanged: (value) {
            if (value.length == 10 && _selectedBank.isNotEmpty) {
              _validateAccount();
            } else {
              setState(() {
                _recipientName = '';
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.translate('accountNumberRequired');
            }
            if (value.length != 10) {
              return localizations.translate('invalidAccountNumber');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRecipientInfo(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary500.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary500,
            child: Text(
              _recipientName.split(' ').map((word) => word.isNotEmpty ? word[0] : '').join('').toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recipientName,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_selectedBank • ${_accountNumberController.text}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.primary500,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.amount,
          style: AppTextStyles.h6,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '₦ ',
            prefixIcon: const Icon(Icons.money),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.translate('amountRequired');
            }
            final amount = double.tryParse(value.replaceAll(',', ''));
            if (amount == null || amount <= 0) {
              return localizations.translate('invalidAmount');
            }
            if (amount < 100) {
              return localizations.translate('minimumAmount100');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${localizations.description} (${localizations.translate('optional')})',
          style: AppTextStyles.h6,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: localizations.translate('enterDescription'),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildWalletTransferOptions(AppLocalizations localizations) {
    return Column(
      children: [
        _buildTransferOption(
          icon: Icons.qr_code_scanner,
          title: localizations.translate('scanQRCode'),
          subtitle: localizations.translate('scanToTransfer'),
          onTap: () {
            // Handle QR code scan
          },
        ),
        const SizedBox(height: 16),
        _buildTransferOption(
          icon: Icons.phone,
          title: localizations.translate('phoneTransfer'),
          subtitle: localizations.translate('transferUsingPhone'),
          onTap: () {
            // Handle phone transfer
          },
        ),
        const SizedBox(height: 16),
        _buildTransferOption(
          icon: Icons.contacts,
          title: localizations.translate('contacts'),
          subtitle: localizations.translate('transferToContacts'),
          onTap: () {
            // Handle contacts transfer
          },
        ),
      ],
    );
  }

  Widget _buildTransferOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary500.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary500,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentRecipientCard(Map<String, String> recipient, AppLocalizations localizations, AppStateProvider appState) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary500,
          child: Text(
            recipient['initials']!,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          recipient['name']!,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${recipient['bank']} • ${recipient['account']}'),
            Text(
              '${localizations.translate('lastUsed')}: ${recipient['lastUsed']}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            // Pre-fill form with recipient details
            setState(() {
              _selectedBank = recipient['bank']!;
              _accountNumberController.text = recipient['account']!;
              _recipientName = recipient['name']!;
            });
            _tabController.animateTo(0); // Switch to bank transfer tab
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildContinueButton(AppLocalizations localizations, AppStateProvider appState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_tabController.index == 0) {
            // Bank transfer
            if (_formKey.currentState!.validate() && 
                _selectedBank.isNotEmpty && 
                _recipientName.isNotEmpty) {
              
              // final transactionDetails = TransactionDetails(
              //   type: 'Bank Transfer',
              //   amount: _amountController.text.replaceAll(',', ''),
              //   recipient: _recipientName,
              //   accountNumber: _accountNumberController.text,
              //   bank: _selectedBank,
              //   description: _descriptionController.text.isNotEmpty 
              //       ? _descriptionController.text 
              //       : 'Transfer to $_recipientName',
              //   canSaveBeneficiary: true,
              // );
              
              appState.navigateToBillPayments();
            } else if (_selectedBank.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.translate('selectBankFirst')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (_recipientName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.translate('validateAccountFirst')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            // Wallet transfer - handle other transfer types
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.translate('selectTransferMethod')),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Text(localizations.translate('continue')),
      ),
    );
  }

  void _validateAccount() async {
    if (_accountNumberController.text.length != 10 || _selectedBank.isEmpty) {
      return;
    }

    setState(() {
      _isValidatingAccount = true;
    });

    // Simulate account validation
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isValidatingAccount = false;
        // Mock recipient name based on account number
        _recipientName = 'John Doe'; // This would come from API
      });
    }
  }
}