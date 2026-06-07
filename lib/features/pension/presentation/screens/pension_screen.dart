import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

class _PFA {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final Color color;

  const _PFA({required this.id, required this.name, required this.shortName, required this.description, required this.color});
}

class PensionScreen extends StatefulWidget {
  const PensionScreen({super.key});

  @override
  State<PensionScreen> createState() => _PensionScreenState();
}

class _PensionScreenState extends State<PensionScreen> {
  _PFA? _selectedPFA;
  String _contributionType = 'Voluntary';
  final _rsaController = TextEditingController();
  final _amountController = TextEditingController();
  final _rsaFocus = FocusNode();
  final _amountFocus = FocusNode();

  final List<_PFA> _pfas = const [
    _PFA(id: 'stanbic', name: 'Stanbic IBTC Pension Managers', shortName: 'Stanbic IBTC', description: 'Largest PFA in Nigeria by AUM', color: Color(0xFF003087)),
    _PFA(id: 'arm', name: 'ARM Pension Managers', shortName: 'ARM Pension', description: 'Trusted pension manager since 2004', color: Color(0xFF00529B)),
    _PFA(id: 'leadway', name: 'Leadway Pensure', shortName: 'Leadway', description: 'Leadway Group pension arm', color: Color(0xFFD4042A)),
    _PFA(id: 'axa', name: 'AXA Mansard Pensions', shortName: 'AXA Mansard', description: 'AXA Group subsidiary in Nigeria', color: Color(0xFF00008F)),
    _PFA(id: 'fidelity', name: 'Fidelity Pension Managers', shortName: 'Fidelity Pension', description: 'Part of Fidelity Bank Group', color: Color(0xFF003366)),
    _PFA(id: 'crusader', name: 'Crusader Sterling Pensions', shortName: 'Crusader Sterling', description: 'Quality pension management', color: Color(0xFF8B0000)),
    _PFA(id: 'premium', name: 'Premium Pension', shortName: 'Premium Pension', description: 'CBN licensed pension fund administrator', color: Color(0xFF006400)),
    _PFA(id: 'nlpc', name: 'NLPC Pension Fund Administrators', shortName: 'NLPC', description: 'Licensed by PenCom', color: Color(0xFF4B0082)),
  ];

  bool get _isFormValid =>
      _selectedPFA != null &&
      _rsaController.text.length >= 16 &&
      _amountController.text.isNotEmpty &&
      (double.tryParse(_amountController.text) ?? 0) >= 1000;

  void _openPFASheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(999))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(alignment: Alignment.centerLeft, child: Text('Select Pension Fund Administrator',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface))),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  itemCount: _pfas.length,
                  itemBuilder: (_, i) {
                    final pfa = _pfas[i];
                    final isSelected = _selectedPFA?.id == pfa.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedPFA = pfa);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.goldPrimary.withOpacity(0.4) : Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: pfa.color, borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text(pfa.shortName[0],
                                  style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.w800, fontSize: 16))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(pfa.shortName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                Text(pfa.description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                              ]),
                            ),
                            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF166C46), size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNext() {
    if (!_isFormValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Voluntary Pension'},
        {'label': 'PFA', 'value': _selectedPFA!.shortName},
        {'label': 'RSA PIN', 'value': _rsaController.text},
        {'label': 'Type', 'value': _contributionType},
        {'label': 'Amount', 'value': '₦${_amountController.text}'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        context.pushReplacement('/success', extra: SuccessScreenProps(
          transactionType: '$_contributionType Pension Contribution',
          amount: _amountController.text,
          recipient: '${_selectedPFA!.shortName} – RSA ${_rsaController.text.substring(0, 4)}****',
        ));
      },
    );
  }

  @override
  void dispose() {
    _rsaController.dispose();
    _amountController.dispose();
    _rsaFocus.dispose();
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
            title: 'Voluntary Pension',
            subtitle: 'PenCom regulated contributions',
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

                  // Info banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF3B82F6)),
                        SizedBox(width: 8),
                        Expanded(child: Text('Regulated by PenCom · Contributions are tax deductible',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PFA selector
                  _SelectorField(
                    label: 'Pension Fund Administrator',
                    value: _selectedPFA?.shortName,
                    hint: 'Select your PFA',
                    onTap: _openPFASheet,
                  ),
                  const SizedBox(height: 16),

                  // RSA PIN
                  BillFloatingField(
                    controller: _rsaController,
                    focusNode: _rsaFocus,
                    label: 'RSA PIN',
                    hint: 'Your Retirement Savings Account PIN',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(20)],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Contribution type
                  Text('Contribution Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Voluntary', 'AVC'].map((type) {
                      final isSelected = _contributionType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _contributionType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(right: type == 'Voluntary' ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppColors.goldPrimary : Theme.of(context).dividerColor, width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              children: [
                                Text(type, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                    color: isSelected ? AppColors.goldPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
                                Text(type == 'Voluntary' ? 'Standard contribution' : 'Additional Voluntary',
                                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  BillAmountCard(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    onChanged: (_) => setState(() {}),
                    minMax: 'Min: ₦1,000 · No maximum limit',
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _PensionCTA(enabled: _isFormValid, amount: _amountController.text, onTap: _handleNext),
        ],
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;

  const _SelectorField({required this.label, required this.value, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? AppColors.goldPrimary.withOpacity(0.4) : Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                      color: hasValue ? AppColors.goldPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                  const SizedBox(height: 2),
                  Text(value ?? hint, style: TextStyle(fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue ? Theme.of(context).colorScheme.onSurface : Theme.of(context).dividerColor)),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _PensionCTA extends StatelessWidget {
  final bool enabled;
  final String amount;
  final VoidCallback? onTap;

  const _PensionCTA({required this.enabled, required this.amount, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = amount.isNotEmpty && (double.tryParse(amount) ?? 0) > 0 ? 'Contribute ₦$amount' : 'Continue';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: Theme.of(context).scaffoldBackgroundColor))),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.goldGradient : null,
            color: enabled ? null : Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: enabled ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)))),
        ),
      ),
    );
  }
}
