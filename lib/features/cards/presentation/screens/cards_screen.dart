import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  int _selectedCard = 0; // 0 = Verve, 1 = Mastercard

  static const _cardTypes = [
    _CardType(
      name: 'Verve Card',
      network: 'Verve',
      fee: '₦1,000',
      deliveryDays: '5-7',
      color1: Color(0xFF1A6B35),
      color2: Color(0xFF0B4F2F),
    ),
    _CardType(
      name: 'Mastercard',
      network: 'Mastercard',
      fee: '₦2,000',
      deliveryDays: '7-10',
      color1: Color(0xFFEB001B),
      color2: Color(0xFFF79E1B),
    ),
  ];

  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
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
                  _sectionLabel('Choose Card Type'),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(_cardTypes.length, (i) {
                      final ct = _cardTypes[i];
                      final active = i == _selectedCard;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCard = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: i == 0 ? 10 : 0),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: active
                                  ? ct.color1.withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    active ? ct.color1 : const Color(0xFFE4E7EC),
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mini card preview
                                Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [ct.color1, ct.color2],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('RIMA MFB',
                                            style: TextStyle(
                                                color:
                                                    Colors.white.withOpacity(0.9),
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1)),
                                        Text('•••• •••• •••• ••••',
                                            style: TextStyle(
                                                color:
                                                    Colors.white.withOpacity(0.7),
                                                fontSize: 10,
                                                letterSpacing: 2)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(ct.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: Theme.of(context).colorScheme.onSurface)),
                                Text('Fee: ${ct.fee}',
                                    style: TextStyle(
                                        fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                Text('Delivery: ${ct.deliveryDays} days',
                                    style: TextStyle(
                                        fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('Delivery Address'),
                  const SizedBox(height: 10),
                  _buildInput(controller: _addressController, hint: 'Street address'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _buildInput(
                              controller: _cityController, hint: 'City')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildInput(
                              controller: _stateController, hint: 'State')),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            color: Color(0xFFFF6B35), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Card fee of ${_cardTypes[_selectedCard].fee} will be deducted from your account. Delivery in ${_cardTypes[_selectedCard].deliveryDays} working days.',
                            style: TextStyle(
                                color: Color(0xFF9A3412), fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _addressController.text.isNotEmpty
                          ? () => _showConfirmSheet(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6B35),
                        disabledBackgroundColor: const Color(0xFFE4E7EC),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Request Card',
                          style: TextStyle(
                              color: Theme.of(context).cardColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
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

  void _showConfirmSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999)),
            ),
            const Icon(Icons.credit_card, size: 48, color: Color(0xFF1A6B35)),
            const SizedBox(height: 12),
            Text(
              'Request ${_cardTypes[_selectedCard].name}?',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'A fee of ${_cardTypes[_selectedCard].fee} will be deducted from your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Card request submitted successfully!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF1A6B35),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm Request',
                    style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
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
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              width: 38,
              height: 38,
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
              Text('My Card',
                  style: TextStyle(
                      color: Theme.of(context).cardColor, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Request a physical debit card',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
      {required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
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
            borderSide: const BorderSide(color: Color(0xFF1A6B35), width: 2)),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)));
}

class _CardType {
  final String name;
  final String network;
  final String fee;
  final String deliveryDays;
  final Color color1;
  final Color color2;
  const _CardType({
    required this.name,
    required this.network,
    required this.fee,
    required this.deliveryDays,
    required this.color1,
    required this.color2,
  });
}
