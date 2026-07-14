import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class InternetServicesScreen extends StatefulWidget {
  const InternetServicesScreen({super.key});

  @override
  State<InternetServicesScreen> createState() => _InternetServicesScreenState();
}

class _InternetServicesScreenState extends State<InternetServicesScreen> {
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  int _selectedProvider = 0;
  int _selectedPlan = 0;

  static const _providers = [
    _ISP(name: 'Spectranet', icon: '📡', color: Color(0xFF0EA5E9)),
    _ISP(name: 'Smile 4G', icon: '😊', color: Color(0xFF10B981)),
    _ISP(name: 'Swift Networks', icon: '⚡', color: Color(0xFF8B5CF6)),
  ];

  static const _plans = [
    _Plan(name: '10 GB', price: '₦3,000', validity: '30 days'),
    _Plan(name: '20 GB', price: '₦5,000', validity: '30 days'),
    _Plan(name: '50 GB', price: '₦10,000', validity: '30 days'),
    _Plan(name: '100 GB', price: '₦18,000', validity: '30 days'),
  ];

  @override
  void dispose() {
    _accountController.dispose();
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
                  _sectionLabel('Select Provider'),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_providers.length, (i) {
                      final p = _providers[i];
                      final active = i == _selectedProvider;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedProvider = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: i < _providers.length - 1 ? 10 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: active ? p.color.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active ? p.color : Theme.of(context).dividerColor,
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(p.icon, style: TextStyle(fontSize: 24)),
                                const SizedBox(height: 6),
                                Text(p.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: active ? p.color : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Account / Device ID'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _accountController,
                    hint: 'Enter account or device ID',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Select Plan'),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _plans.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                    ),
                    itemBuilder: (_, i) {
                      final plan = _plans[i];
                      final active = i == _selectedPlan;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedPlan = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: active ? Theme.of(context).colorScheme.surface.withOpacity(0.5) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active ? Color(0xFF1A6B35) : Theme.of(context).dividerColor,
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(plan.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF1A6B35),
                                  )),
                              Text(plan.price,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  )),
                              Text(plan.validity,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _accountController.text.isNotEmpty
                          ? () => context.push('/pin-verification', extra: {
                                'type': 'Internet',
                                'amount': _plans[_selectedPlan].price.replaceAll('₦', '').replaceAll(',', ''),
                                'recipient': _providers[_selectedProvider].name,
                              })
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6B35),
                        disabledBackgroundColor: Theme.of(context).dividerColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Proceed',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 20,
        bottom: 20,
      ),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Internet Services',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Spectranet, Smile & more',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)));
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }
}

class _ISP {
  final String name;
  final String icon;
  final Color color;
  const _ISP({required this.name, required this.icon, required this.color});
}

class _Plan {
  final String name;
  final String price;
  final String validity;
  const _Plan({required this.name, required this.price, required this.validity});
}
