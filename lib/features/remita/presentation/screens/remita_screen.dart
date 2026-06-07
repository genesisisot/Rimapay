import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';

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
    _Category(name: 'All', icon: Icons.apps),
    _Category(name: 'Federal Govt', icon: Icons.account_balance),
    _Category(name: 'State Govt', icon: Icons.location_city),
    _Category(name: 'Universities', icon: Icons.school),
    _Category(name: 'Utilities', icon: Icons.bolt),
  ];

  static const _popularServices = [
    _PopularService('Tax Payment', 'FIRS', Icons.receipt_long, Color(0xFF1A6B35)),
    _PopularService('JAMB', 'Registration', Icons.school, Color(0xFF1565C0)),
    _PopularService('Immigration', 'NIS Passport', Icons.flight, Color(0xFF7B1FA2)),
    _PopularService('Police Clearance', 'NPF', Icons.verified_user, Color(0xFF0277BD)),
    _PopularService('CAC', 'Company Reg', Icons.business, Color(0xFFE65100)),
    _PopularService('FRSC', 'Driver License', Icons.directions_car, Color(0xFF2E7D32)),
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
      _amountController.text = '15,000';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const BillGreenHeader(
            title: 'Remita',
            subtitle: 'Government & institutional payments',
          ),
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
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF1A6B35)
                                    : Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(cat.icon,
                                    size: 16,
                                    color: active
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                const SizedBox(width: 6),
                                Text(cat.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      fontFamily: 'Effra',
                                      color: active
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    )),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Popular services grid
                  _sectionLabel('Popular Services'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                    children: _popularServices.map((s) {
                      return GestureDetector(
                        onTap: () {
                          _rrnController.clear();
                          setState(() => _verified = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Enter your RRN for ${s.name}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF1A6B35),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor, width: 0.8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? s.color.withOpacity(0.15)
                                      : s.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(s.icon, color: s.color, size: 18),
                              ),
                              const SizedBox(height: 6),
                              Text(s.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Effra',
                                    color: Theme.of(context).colorScheme.onSurface,
                                  )),
                              Text(s.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'Effra',
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // RRN input section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enter RRN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Effra',
                              color: Theme.of(context).colorScheme.onSurface,
                            )),
                        const SizedBox(height: 4),
                        Text('Retrieve your payment details using the Remita Retrieval Reference',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Effra',
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              height: 1.4,
                            )),
                        const SizedBox(height: 14),
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
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Effra',
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. 310082918201',
                                  hintStyle: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(Icons.tag,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                      size: 18),
                                  filled: true,
                                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF1A6B35), width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _rrnController.text.length >= 10 && !_isVerifying
                                    ? _verifyRRN
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A6B35),
                                  disabledBackgroundColor: Theme.of(context).dividerColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Text('Verify',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Effra')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Verified payment info
                  if (_verified) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF1A6B35).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A6B35).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle,
                                color: Color(0xFF1A6B35), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A6B35),
                                      fontFamily: 'Effra',
                                    )),
                                Text(_paymentTitle ?? '',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        fontFamily: 'Effra',
                                        color: Theme.of(context).colorScheme.onSurface)),
                                Text(_agency ?? '',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Effra',
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Amount
                    BillAmountCard(
                      controller: _amountController,
                      minMax: 'Amount as stated on your RRN',
                    ),

                    const SizedBox(height: 24),
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
                          disabledBackgroundColor: Theme.of(context).dividerColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Pay Now',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Effra')),
                      ),
                    ),
                  ],

                  // Info section
                  if (!_verified) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1F2E)
                            : const Color(0xFFF0FAF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2D3348)
                              : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: const Color(0xFF1A6B35), size: 18),
                              const SizedBox(width: 8),
                              Text('About Remita Payments',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Effra',
                                    color: Theme.of(context).colorScheme.onSurface,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _infoRow(context, '1', 'Generate an RRN from remita.net or the collecting agency'),
                          const SizedBox(height: 8),
                          _infoRow(context, '2', 'Enter the RRN above and tap Verify'),
                          const SizedBox(height: 8),
                          _infoRow(context, '3', 'Confirm the payment details and pay securely'),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF1A6B35).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(num,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A6B35),
                )),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Effra',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              )),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        fontFamily: 'Effra',
        color: Theme.of(context).colorScheme.onSurface,
      ));
}

class _Category {
  final String name;
  final IconData icon;
  const _Category({required this.name, required this.icon});
}

class _PopularService {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _PopularService(this.name, this.subtitle, this.icon, this.color);
}
