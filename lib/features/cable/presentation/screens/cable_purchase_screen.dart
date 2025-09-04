import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class CablePurchaseScreen extends StatefulWidget {
  const CablePurchaseScreen({super.key});

  @override
  State<CablePurchaseScreen> createState() => _CablePurchaseScreenState();
}

class _CablePurchaseScreenState extends State<CablePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _smartCardController = TextEditingController();
  
  String _selectedProvider = '';
  String _selectedPackage = '';
  
  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'DSTV',
      'logo': '📺',
      'color': Color(0xFFFF6B00),
      'description': 'Premium satellite TV'
    },
    {
      'name': 'GOTV',
      'logo': '📻',
      'color': Color(0xFF00A651),
      'description': 'Digital terrestrial TV'
    },
    {
      'name': 'StarTimes',
      'logo': '⭐',
      'color': Color(0xFFE60012),
      'description': 'Affordable digital TV'
    },
    {
      'name': 'Showmax',
      'logo': '🎬',
      'color': Color(0xFF8B5CF6),
      'description': 'Online streaming'
    },
  ];

  final Map<String, List<Map<String, dynamic>>> _packages = {
    'DSTV': [
      {'name': 'DSTV Padi', 'amount': '₦2,150', 'code': 'DSTV_PADI', 'duration': '1 Month'},
      {'name': 'DSTV Yanga', 'amount': '₦2,950', 'code': 'DSTV_YANGA', 'duration': '1 Month'},
      {'name': 'DSTV Confam', 'amount': '₦5,300', 'code': 'DSTV_CONFAM', 'duration': '1 Month'},
      {'name': 'DSTV Compact', 'amount': '₦9,000', 'code': 'DSTV_COMPACT', 'duration': '1 Month'},
      {'name': 'DSTV Compact Plus', 'amount': '₦14,250', 'code': 'DSTV_COMPACT_PLUS', 'duration': '1 Month'},
      {'name': 'DSTV Premium', 'amount': '₦21,000', 'code': 'DSTV_PREMIUM', 'duration': '1 Month'},
    ],
    'GOTV': [
      {'name': 'GOTV Smallie', 'amount': '₦900', 'code': 'GOTV_SMALLIE', 'duration': '1 Month'},
      {'name': 'GOTV Jinja', 'amount': '₦1,900', 'code': 'GOTV_JINJA', 'duration': '1 Month'},
      {'name': 'GOTV Jolli', 'amount': '₦2,800', 'code': 'GOTV_JOLLI', 'duration': '1 Month'},
      {'name': 'GOTV Max', 'amount': '₦4,150', 'code': 'GOTV_MAX', 'duration': '1 Month'},
      {'name': 'GOTV Supa', 'amount': '₦5,500', 'code': 'GOTV_SUPA', 'duration': '1 Month'},
    ],
    'StarTimes': [
      {'name': 'Nova', 'amount': '₦900', 'code': 'STARTIMES_NOVA', 'duration': '1 Month'},
      {'name': 'Basic', 'amount': '₦1,700', 'code': 'STARTIMES_BASIC', 'duration': '1 Month'},
      {'name': 'Smart', 'amount': '₦2,500', 'code': 'STARTIMES_SMART', 'duration': '1 Month'},
      {'name': 'Classic', 'amount': '₦2,750', 'code': 'STARTIMES_CLASSIC', 'duration': '1 Month'},
      {'name': 'Super', 'amount': '₦4,200', 'code': 'STARTIMES_SUPER', 'duration': '1 Month'},
    ],
    'Showmax': [
      {'name': 'Showmax Mobile', 'amount': '₦1,200', 'code': 'SHOWMAX_MOBILE', 'duration': '1 Month'},
      {'name': 'Showmax Standard', 'amount': '₦2,900', 'code': 'SHOWMAX_STANDARD', 'duration': '1 Month'},
      {'name': 'Showmax Pro', 'amount': '₦3,200', 'code': 'SHOWMAX_PRO', 'duration': '1 Month'},
    ],
  };

  @override
  void dispose() {
    _smartCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final appState = context.watch<AppStateProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.cableTV),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
         
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProviderSelection(localizations),
                const SizedBox(height: 24),
                _buildSmartCardInput(localizations),
                const SizedBox(height: 24),
                if (_selectedProvider.isNotEmpty) ...[
                  Expanded(
                    child: _buildPackagesSelection(localizations),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildContinueButton(localizations, appState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderSelection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('selectProvider'),
          style: AppTextStyles.h6,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _providers.length,
          itemBuilder: (context, index) {
            final provider = _providers[index];
            final isSelected = _selectedProvider == provider['name'];
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedProvider = provider['name'];
                  _selectedPackage = ''; // Reset package selection
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary500.withOpacity(0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primary500 : AppColors.neutral200,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: provider['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          provider['logo'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider['name'],
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primary500 : AppColors.neutral700,
                            ),
                          ),
                          Text(
                            provider['description'],
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.neutral500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSmartCardInput(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('smartCardNumber'),
          style: AppTextStyles.h6,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _smartCardController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0123456789',
            prefixIcon: const Icon(Icons.credit_card),
            suffixIcon: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showSmartCardInfo();
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.translate('smartCardRequired');
            }
            if (value.length < 10) {
              return localizations.translate('invalidSmartCardNumber');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPackagesSelection(AppLocalizations localizations) {
    final packages = _packages[_selectedProvider] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('selectPackage'),
          style: AppTextStyles.h6,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              final isSelected = _selectedPackage == package['code'];
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPackage = package['code'];
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary500.withOpacity(0.1) : Colors.white,
                        border: Border.all(
                          color: isSelected ? AppColors.primary500 : AppColors.neutral200,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary500 : AppColors.neutral100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.tv,
                              color: isSelected ? Colors.white : AppColors.neutral600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  package['name'],
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.primary500 : AppColors.neutral900,
                                  ),
                                ),
                                Text(
                                  '${localizations.translate('duration')}: ${package['duration']}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            package['amount'],
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.primary500 : AppColors.neutral900,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary500,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(AppLocalizations localizations, AppStateProvider appState) {
    final selectedPackageData = _getSelectedPackageData();
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate() && 
              _selectedProvider.isNotEmpty && 
              _selectedPackage.isNotEmpty) {
            
            // final transactionDetails = TransactionDetails(
            //   type: 'Cable TV Subscription',
            //   amount: selectedPackageData?['amount']?.replaceAll('₦', '').replaceAll(',', '') ?? '0',
            //   recipient: '${_selectedProvider} - ${selectedPackageData?['name']}',
            //   customer: _smartCardController.text,
            //   provider: _selectedProvider,
            //   plan: selectedPackageData?['name'] ?? '',
            //   description: 'Cable TV subscription for ${_smartCardController.text}',
            // );
            
            // appState.handleBillPaymentNext(transactionDetails);
          } else if (_selectedProvider.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.translate('selectProviderFirst')),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (_selectedPackage.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.translate('selectPackageFirst')),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Text(localizations.translate('continue')),
      ),
    );
  }

  Map<String, dynamic>? _getSelectedPackageData() {
    final packages = _packages[_selectedProvider] ?? [];
    try {
      return packages.firstWhere((package) => package['code'] == _selectedPackage);
    } catch (e) {
      return null;
    }
  }

  void _showSmartCardInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('smartCardInfo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.translate('smartCardInfoDescription')),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.translate('smartCardLocation'),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.translate('close')),
            ),
          ],
        );
      },
    );
  }
}