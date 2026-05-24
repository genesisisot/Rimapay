import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class GrantsScreen extends StatefulWidget {
  const GrantsScreen({super.key});

  @override
  State<GrantsScreen> createState() => _GrantsScreenState();
}

class _GrantsScreenState extends State<GrantsScreen> {
  int _selectedCategory = 0;
  int _selectedOrg = 0;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  static const _categories = ['Government Grants', 'NGO / Donations', 'Disaster Relief'];

  static const _orgs = [
    _Org(name: 'FG Social Investment', type: 'Federal Government', icon: '🏛️'),
    _Org(name: 'NIRSAL Microfinance Bank', type: 'Federal Government', icon: '🌾'),
    _Org(name: 'Rima State Grant Fund', type: 'State Government', icon: '🏡'),
    _Org(name: 'Red Cross Nigeria', type: 'NGO', icon: '🔴'),
    _Org(name: 'UNICEF Nigeria', type: 'International NGO', icon: '🌍'),
    _Org(name: 'Aliko Dangote Foundation', type: 'Private Foundation', icon: '💼'),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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
                  _sectionLabel('Category'),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_categories.length, (i) {
                        final active = i == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF1A6B35) : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: active ? const Color(0xFF1A6B35) : const Color(0xFFE4E7EC),
                              ),
                            ),
                            child: Text(_categories[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active ? Colors.white : const Color(0xFF344054),
                                )),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Select Organisation'),
                  const SizedBox(height: 10),
                  ...List.generate(_orgs.length, (i) {
                    final org = _orgs[i];
                    final active = i == _selectedOrg;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedOrg = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFE8F5ED) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? const Color(0xFF1A6B35) : const Color(0xFFE4E7EC),
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(org.icon, style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(org.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface)),
                                  Text(org.type,
                                      style: TextStyle(
                                          fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
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

                  const SizedBox(height: 16),
                  _sectionLabel('Amount (₦)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration('Enter donation amount'),
                  ),

                  const SizedBox(height: 12),
                  _sectionLabel('Note (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: _inputDecoration('Add a message or reference'),
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _amountController.text.isNotEmpty
                          ? () => context.push('/pin-verification', extra: {
                                'type': 'Donation',
                                'amount': _amountController.text,
                                'recipient': _orgs[_selectedOrg].name,
                              })
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6B35),
                        disabledBackgroundColor: const Color(0xFFE4E7EC),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Donate / Apply',
                          style: TextStyle(
                              color: Theme.of(context).cardColor, fontSize: 16, fontWeight: FontWeight.w700)),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Theme.of(context).dividerColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Theme.of(context).dividerColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A6B35), width: 2)),
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
              Text('Grants & Donations',
                  style: TextStyle(color: Theme.of(context).cardColor, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Support a cause today',
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

class _Org {
  final String name;
  final String type;
  final String icon;
  const _Org({required this.name, required this.type, required this.icon});
}
