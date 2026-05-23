import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class FixedDepositScreen extends StatefulWidget {
  const FixedDepositScreen({super.key});

  @override
  State<FixedDepositScreen> createState() => _FixedDepositScreenState();
}

class _FixedDepositScreenState extends State<FixedDepositScreen> {
  final _amountController = TextEditingController();
  int _selectedTenor = 1; // index into _tenors
  bool _autoRollover = false;

  static const _tenors = [
    _Tenor(days: 30, label: '30 Days', rate: 8.5),
    _Tenor(days: 60, label: '60 Days', rate: 9.0),
    _Tenor(days: 90, label: '90 Days', rate: 10.0),
    _Tenor(days: 180, label: '6 Months', rate: 11.5),
    _Tenor(days: 365, label: '1 Year', rate: 13.0),
  ];

  double get _interestRate => _tenors[_selectedTenor].rate;

  double get _estimatedReturn {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final days = _tenors[_selectedTenor].days;
    return amount * (_interestRate / 100) * (days / 365);
  }

  String _formatAmount(double v) {
    if (v <= 0) return '₦0.00';
    return '₦${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1A6B35).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF1A6B35), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your funds are insured by NDIC. Earn up to 13% per annum.',
                            style: TextStyle(
                              color: const Color(0xFF1A6B35).withOpacity(0.85),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Deposit Amount'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixText: '₦ ',
                      prefixStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF344054)),
                      hintText: '0',
                      hintStyle: const TextStyle(color: Color(0xFFD0D5DD), fontSize: 18),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE4E7EC))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE4E7EC))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF1A6B35), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Minimum: ₦10,000',
                      style: TextStyle(fontSize: 11, color: Color(0xFF667085))),

                  const SizedBox(height: 20),
                  _sectionLabel('Select Tenor'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_tenors.length, (i) {
                      final t = _tenors[i];
                      final active = i == _selectedTenor;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTenor = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF1A6B35) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active ? const Color(0xFF1A6B35) : const Color(0xFFE4E7EC),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(t.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: active ? Colors.white : const Color(0xFF344054),
                                  )),
                              Text('${t.rate}% p.a.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: active
                                        ? Colors.white.withOpacity(0.8)
                                        : const Color(0xFF667085),
                                  )),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),
                  // Returns summary
                  if (_amountController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E7EC)),
                      ),
                      child: Column(
                        children: [
                          _summaryRow('Principal', _formatAmount(double.tryParse(_amountController.text) ?? 0)),
                          const Divider(height: 18),
                          _summaryRow('Interest Rate', '$_interestRate% p.a.'),
                          _summaryRow('Tenor', _tenors[_selectedTenor].label),
                          const Divider(height: 18),
                          _summaryRow('Estimated Return', _formatAmount(_estimatedReturn),
                              highlight: true),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                  // Auto-rollover toggle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Auto-Rollover',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF101828))),
                              SizedBox(height: 2),
                              Text('Automatically renew at maturity',
                                  style:
                                      TextStyle(fontSize: 12, color: Color(0xFF667085))),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoRollover,
                          onChanged: (v) => setState(() => _autoRollover = v),
                          activeColor: const Color(0xFF1A6B35),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (double.tryParse(_amountController.text) ?? 0) >= 10000
                          ? () => context.push('/pin-verification', extra: {
                                'type': 'Fixed Deposit',
                                'amount': _amountController.text,
                                'recipient': 'Rima MFB Fixed Deposit',
                              })
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6B35),
                        disabledBackgroundColor: const Color(0xFFE4E7EC),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Place Fixed Deposit',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: highlight ? const Color(0xFF101828) : const Color(0xFF667085),
                fontWeight: highlight ? FontWeight.w700 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: highlight ? const Color(0xFF1A6B35) : const Color(0xFF101828))),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fixed Deposit',
                  style: TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Earn up to 13% per annum',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF344054)));
}

class _Tenor {
  final int days;
  final String label;
  final double rate;
  const _Tenor({required this.days, required this.label, required this.rate});
}
