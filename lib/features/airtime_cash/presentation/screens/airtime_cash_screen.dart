import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

class _Network {
  final String id;
  final String name;
  final Color color;
  final Color bgColor;
  final String emoji;

  const _Network({required this.id, required this.name, required this.color, required this.bgColor, required this.emoji});
}

class AirtimeCashScreen extends StatefulWidget {
  const AirtimeCashScreen({super.key});

  @override
  State<AirtimeCashScreen> createState() => _AirtimeCashScreenState();
}

class _AirtimeCashScreenState extends State<AirtimeCashScreen> {
  _Network? _selectedNetwork;
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _amountFocus = FocusNode();

  final List<_Network> _networks = const [
    _Network(id: 'mtn', name: 'MTN', color: Color(0xFFFFCC02), bgColor: Color(0xFFFFF8E1), emoji: '📶'),
    _Network(id: 'airtel', name: 'Airtel', color: Color(0xFFFF0000), bgColor: Color(0xFFFFEBEE), emoji: '📡'),
    _Network(id: 'glo', name: 'Glo', color: Color(0xFF166C46), bgColor: Color(0xFFF2F7F3), emoji: '🌐'),
    _Network(id: '9mobile', name: '9mobile', color: Color(0xFF00A86B), bgColor: Color(0xFFE8F6F3), emoji: '📱'),
  ];

  static const double _conversionRate = 0.80;

  double get _convertedAmount {
    final amt = double.tryParse(_amountController.text) ?? 0;
    return amt * _conversionRate;
  }

  bool get _isFormValid =>
      _selectedNetwork != null &&
      _phoneController.text.length == 11 &&
      (_amountController.text.isNotEmpty && (double.tryParse(_amountController.text) ?? 0) >= 500);

  void _handleNext() {
    if (!_isFormValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Airtime to Cash'},
        {'label': 'Network', 'value': _selectedNetwork!.name},
        {'label': 'Phone', 'value': _phoneController.text},
        {'label': 'Airtime Amount', 'value': '₦${_amountController.text}'},
        {'label': 'You Receive', 'value': '₦${_convertedAmount.toStringAsFixed(0)}'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        context.pushReplacement('/success', extra: SuccessScreenProps(
          transactionType: 'Airtime to Cash',
          amount: _convertedAmount.toStringAsFixed(0),
          recipient: '${_selectedNetwork!.name} – ${_phoneController.text}',
        ));
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _phoneFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          BillGreenHeader(
            title: 'Airtime to Cash',
            subtitle: 'Convert airtime to wallet balance',
            showAccountCard: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BillAccountCard(),
                  const SizedBox(height: 20),

                  // Rate info banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '80% conversion rate · ₦500 airtime = ₦400 cash',
                            style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Network selector
                  const Text('Select Network', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 10),
                  Row(
                    children: _networks.asMap().entries.map((e) {
                      final n = e.value;
                      final isSelected = _selectedNetwork?.id == n.id;
                      final isLast = e.key == _networks.length - 1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedNetwork = n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(right: isLast ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? n.bgColor : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? n.color : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              children: [
                                Text(n.emoji, style: TextStyle(fontSize: 20)),
                                const SizedBox(height: 4),
                                Text(n.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                    color: isSelected ? n.color : const Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Phone number
                  BillFloatingField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    label: 'Phone Number',
                    hint: '0801 234 5678',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  BillAmountCard(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    onChanged: (_) => setState(() {}),
                    minMax: 'Min: ₦500 · Conversion rate: 80%',
                  ),

                  const SizedBox(height: 16),

                  // Conversion preview
                  if (_amountController.text.isNotEmpty && (double.tryParse(_amountController.text) ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF166C46).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz_rounded, color: Color(0xFF166C46), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('₦${_amountController.text} airtime',
                                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                const Text('converts to', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                          Text('₦${_convertedAmount.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF166C46))),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _AirtimeCashCTA(enabled: _isFormValid, amount: _amountController.text, converted: _convertedAmount, onTap: _handleNext),
        ],
      ),
    );
  }
}

class _AirtimeCashCTA extends StatelessWidget {
  final bool enabled;
  final String amount;
  final double converted;
  final VoidCallback? onTap;

  const _AirtimeCashCTA({required this.enabled, required this.amount, required this.converted, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = amount.isNotEmpty && (double.tryParse(amount) ?? 0) > 0
        ? 'Convert ₦$amount → ₦${converted.toStringAsFixed(0)}'
        : 'Continue';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.goldGradient : null,
            color: enabled ? null : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: enabled ? Colors.white : const Color(0xFF9CA3AF)))),
        ),
      ),
    );
  }
}
