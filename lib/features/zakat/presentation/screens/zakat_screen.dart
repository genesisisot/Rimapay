import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _goldController = TextEditingController();
  final _cashController = TextEditingController();
  final _stockController = TextEditingController();
  int _selectedInstitution = 0;

  // Nisab threshold (approx. value of 85g gold in NGN)
  static const double _nisabNGN = 850000.0;
  static const double _zakatRate = 0.025; // 2.5%

  static const _institutions = [
    _Institution(name: 'Rima MFB Zakat Fund', type: 'Certified', icon: '🏦'),
    _Institution(name: 'NSCIA Zakat Committee', type: 'Government', icon: '🕌'),
    _Institution(name: 'Muslim Welfare Foundation', type: 'NGO', icon: '🤲'),
    _Institution(name: 'Islamic Solidarity Fund', type: 'NGO', icon: '☪️'),
  ];

  double get _totalWealth {
    final gold = double.tryParse(_goldController.text.replaceAll(',', '')) ?? 0;
    final cash = double.tryParse(_cashController.text.replaceAll(',', '')) ?? 0;
    final stock = double.tryParse(_stockController.text.replaceAll(',', '')) ?? 0;
    return gold + cash + stock;
  }

  double get _zakatDue =>
      _totalWealth >= _nisabNGN ? _totalWealth * _zakatRate : 0;

  bool get _aboveNisab => _totalWealth >= _nisabNGN;

  String _fmt(double v) =>
      '₦${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  void dispose() {
    _goldController.dispose();
    _cashController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nisab info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('☪️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 12, height: 1.5),
                              children: [
                                const TextSpan(
                                    text: 'Nisab threshold: ',
                                    style: TextStyle(
                                        color: Color(0xFF9A3412),
                                        fontWeight: FontWeight.w700)),
                                TextSpan(
                                    text: _fmt(_nisabNGN),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                const TextSpan(
                                    text:
                                        ' (approx. value of 85g of gold). Zakat rate: 2.5%.',
                                    style: TextStyle(color: Color(0xFF9A3412))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Zakat Calculator'),
                  const SizedBox(height: 12),
                  _wealthInput('Gold & Silver (₦)', _goldController),
                  const SizedBox(height: 10),
                  _wealthInput('Cash & Bank Savings (₦)', _cashController),
                  const SizedBox(height: 10),
                  _wealthInput('Business Stock / Investments (₦)', _stockController),

                  const SizedBox(height: 16),
                  // Result card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _aboveNisab
                          ? const Color(0xFFE8F5ED)
                          : const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _aboveNisab
                            ? const Color(0xFF1A6B35).withOpacity(0.3)
                            : const Color(0xFFE4E7EC),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Wealth',
                                style: TextStyle(
                                    fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                            Text(_fmt(_totalWealth),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Zakat Due (2.5%)',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface)),
                            Text(_fmt(_zakatDue),
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: _aboveNisab
                                        ? const Color(0xFF1A6B35)
                                        : const Color(0xFF98A2B3))),
                          ],
                        ),
                        if (!_aboveNisab && _totalWealth > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Your wealth is below the Nisab threshold — Zakat is not yet due.',
                            style: TextStyle(
                                fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_aboveNisab && _zakatDue > 0) ...[
                    const SizedBox(height: 20),
                    _sectionLabel('Pay Zakat To'),
                    const SizedBox(height: 10),
                    ...List.generate(_institutions.length, (i) {
                      final inst = _institutions[i];
                      final active = i == _selectedInstitution;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedInstitution = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFE8F5ED) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFF1A6B35)
                                  : const Color(0xFFE4E7EC),
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(inst.icon, style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(inst.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Theme.of(context).colorScheme.onSurface)),
                                    Text(inst.type,
                                        style: TextStyle(
                                            fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                  ],
                                ),
                              ),
                              if (active)
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF1A6B35), size: 20),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.push('/pin-verification', extra: {
                          'type': 'Zakat',
                          'amount': _zakatDue.toStringAsFixed(0),
                          'recipient': _institutions[_selectedInstitution].name,
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A6B35),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Pay Zakat (${_fmt(_zakatDue)})',
                          style: TextStyle(
                              color: Theme.of(context).cardColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wealthInput(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '0',
            prefixText: '₦ ',
            prefixStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.w600),
            hintStyle: TextStyle(color: Theme.of(context).dividerColor),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A6B35), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 14,
          left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/bills'),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).cardColor, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Zakat / Religious',
                  style: TextStyle(color: Theme.of(context).cardColor, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Calculate and pay your Zakat',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)));
}

class _Institution {
  final String name;
  final String type;
  final String icon;
  const _Institution({required this.name, required this.type, required this.icon});
}
