import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class RemitaScreen extends StatefulWidget {
  const RemitaScreen({super.key});

  @override
  State<RemitaScreen> createState() => _RemitaScreenState();
}

class _RemitaScreenState extends State<RemitaScreen> {
  final _rrnController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isVerifying = false;
  bool _verified = false;
  String? _paymentTitle;
  String? _agency;
  int _selectedCategory = 0;

  static const _categories = [
    _Category(name: 'Federal Govt', icon: '🏛️'),
    _Category(name: 'State Govt', icon: '🏡'),
    _Category(name: 'Universities', icon: '🎓'),
    _Category(name: 'Utilities', icon: '⚡'),
  ];

  void _verifyRRN() async {
    if (_rrnController.text.length < 10) return;
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isVerifying = false;
      _verified = true;
      _paymentTitle = 'Income Tax Payment';
      _agency = 'Federal Inland Revenue Service (FIRS)';
      _amountController.text = '15000';
    });
  }

  @override
  void dispose() {
    _rrnController.dispose();
    _amountController.dispose();
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
                  // Category chips
                  _sectionLabel('Payment Category'),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_categories.length, (i) {
                        final active = i == _selectedCategory;
                        final cat = _categories[i];
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategory = i;
                            _verified = false;
                            _rrnController.clear();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF1A6B35)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF1A6B35)
                                    : const Color(0xFFE4E7EC),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(cat.icon,
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(cat.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: active
                                          ? Colors.white
                                          : const Color(0xFF344054),
                                    )),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Remita Retrieval Reference (RRN)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rrnController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          onChanged: (_) => setState(() => _verified = false),
                          decoration: _inputDecoration('Enter RRN number'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _rrnController.text.length >= 10 && !_isVerifying
                                  ? _verifyRRN
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A6B35),
                            disabledBackgroundColor: const Color(0xFFE4E7EC),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Theme.of(context).cardColor, strokeWidth: 2))
                              : const Text('Verify',
                                  style: TextStyle(
                                      color: Theme.of(context).cardColor,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),

                  if (_verified) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFF1A6B35).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF1A6B35), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_paymentTitle ?? '',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface)),
                                Text(_agency ?? '',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('Amount (₦)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration('Amount'),
                    ),

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _amountController.text.isNotEmpty
                            ? () => context.push('/pin-verification', extra: {
                                  'type': 'Remita',
                                  'amount': _amountController.text,
                                  'recipient': _agency ?? 'Government',
                                })
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A6B35),
                          disabledBackgroundColor: const Color(0xFFE4E7EC),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Pay Now',
                            style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Theme.of(context).dividerColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Theme.of(context).dividerColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF1A6B35), width: 2)),
      );

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
              child: const Icon(Icons.arrow_back_ios_new, color: Theme.of(context).cardColor, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remita',
                  style: TextStyle(color: Theme.of(context).cardColor, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Government & institutional payments',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)));
}

class _Category {
  final String name;
  final String icon;
  const _Category({required this.name, required this.icon});
}
