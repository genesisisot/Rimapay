import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

class _Operator {
  final String id;
  final String name;
  final String description;
  final Color color;
  final int pricePerSeat;

  const _Operator({required this.id, required this.name, required this.description, required this.color, required this.pricePerSeat});
}

class _City {
  final String id;
  final String name;
  final String state;

  const _City({required this.id, required this.name, required this.state});
}

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  _City? _origin;
  _City? _destination;
  _Operator? _selectedOperator;
  DateTime _travelDate = DateTime.now().add(const Duration(days: 1));
  int _passengers = 1;

  final List<_City> _cities = const [
    _City(id: 'lag', name: 'Lagos', state: 'Lagos State'),
    _City(id: 'abj', name: 'Abuja', state: 'FCT Abuja'),
    _City(id: 'ph', name: 'Port Harcourt', state: 'Rivers State'),
    _City(id: 'kan', name: 'Kano', state: 'Kano State'),
    _City(id: 'enu', name: 'Enugu', state: 'Enugu State'),
    _City(id: 'iba', name: 'Ibadan', state: 'Oyo State'),
    _City(id: 'ben', name: 'Benin City', state: 'Edo State'),
    _City(id: 'aba', name: 'Aba', state: 'Abia State'),
    _City(id: 'cal', name: 'Calabar', state: 'Cross River State'),
    _City(id: 'osh', name: 'Oshogbo', state: 'Osun State'),
    _City(id: 'wri', name: 'Warri', state: 'Delta State'),
    _City(id: 'ilo', name: 'Ilorin', state: 'Kwara State'),
  ];

  final List<_Operator> _operators = const [
    _Operator(id: 'guo', name: 'GUO Transport', description: 'Premium interstate travel', color: Color(0xFF003087), pricePerSeat: 7500),
    _Operator(id: 'abc', name: 'ABC Transport', description: 'Safe & reliable journeys', color: Color(0xFFD4042A), pricePerSeat: 6000),
    _Operator(id: 'chisco', name: 'Chisco Transport', description: 'Comfort & class on wheels', color: Color(0xFF006400), pricePerSeat: 8000),
    _Operator(id: 'gigm', name: 'GIGM (God is Good)', description: 'Modern fleet nationwide', color: Color(0xFF8B0000), pricePerSeat: 7000),
    _Operator(id: 'ctu', name: 'Cross Country', description: 'Affordable intercity trips', color: Color(0xFF4B0082), pricePerSeat: 5500),
  ];

  int get _totalPrice => (_selectedOperator?.pricePerSeat ?? 0) * _passengers;

  bool get _isFormValid =>
      _origin != null &&
      _destination != null &&
      _origin?.id != _destination?.id &&
      _selectedOperator != null;

  void _openCitySheet(bool isOrigin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFFE4E7EC), borderRadius: BorderRadius.circular(999))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(alignment: Alignment.centerLeft,
                    child: Text(isOrigin ? 'Select Departure City' : 'Select Arrival City',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF101828)))),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  itemCount: _cities.length,
                  itemBuilder: (_, i) {
                    final city = _cities[i];
                    final isSelected = isOrigin ? _origin?.id == city.id : _destination?.id == city.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => isOrigin ? _origin = city : _destination = city);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF2F7F3) : const Color(0xFFFAFBFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.goldPrimary.withOpacity(0.4) : const Color(0xFFE4E7EC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFF667085), size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(city.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
                              Text(city.state, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
                            ])),
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

  void _openOperatorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: const Color(0xFFE4E7EC), borderRadius: BorderRadius.circular(999))),
            const Align(alignment: Alignment.centerLeft, child: Text('Choose Transport Operator',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF101828)))),
            const SizedBox(height: 16),
            ..._operators.map((op) => GestureDetector(
              onTap: () { setState(() => _selectedOperator = op); Navigator.pop(context); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selectedOperator?.id == op.id ? const Color(0xFFF2F7F3) : const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedOperator?.id == op.id ? const Color(0xFF166C46).withOpacity(0.4) : const Color(0xFFE4E7EC)),
                ),
                child: Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: op.color, borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(op.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(op.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
                      Text(op.description, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
                    ])),
                    Text('₦${op.pricePerSeat}/seat', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF166C46))),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF166C46))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _travelDate = picked);
  }

  void _handleNext() {
    if (!_isFormValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Bus Ticket'},
        {'label': 'Route', 'value': '${_origin!.name} → ${_destination!.name}'},
        {'label': 'Operator', 'value': _selectedOperator!.name},
        {'label': 'Date', 'value': '${_travelDate.day}/${_travelDate.month}/${_travelDate.year}'},
        {'label': 'Passengers', 'value': '$_passengers seat${_passengers > 1 ? 's' : ''}'},
        {'label': 'Amount', 'value': '₦$_totalPrice'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        context.pushReplacement('/success', extra: SuccessScreenProps(
          transactionType: 'Bus Ticket',
          amount: _totalPrice.toString(),
          recipient: '${_selectedOperator!.name} · ${_origin!.name} → ${_destination!.name}',
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          BillGreenHeader(title: 'Bus Tickets', subtitle: 'Book inter-city travel', showAccountCard: false),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BillAccountCard(),
                  const SizedBox(height: 20),

                  // Route section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE4E7EC))),
                    child: Column(
                      children: [
                        _RouteSelector(label: 'From', icon: Icons.trip_origin_rounded, iconColor: const Color(0xFF166C46),
                            value: _origin != null ? '${_origin!.name}, ${_origin!.state}' : null,
                            hint: 'Select departure city', onTap: () => _openCitySheet(true)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            const Expanded(child: Divider(color: Color(0xFFE4E7EC))),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: const Color(0xFFF2F7F3), shape: BoxShape.circle),
                              child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF166C46), size: 16),
                            ),
                            const Expanded(child: Divider(color: Color(0xFFE4E7EC))),
                          ]),
                        ),
                        _RouteSelector(label: 'To', icon: Icons.location_on_rounded, iconColor: const Color(0xFFD33B31),
                            value: _destination != null ? '${_destination!.name}, ${_destination!.state}' : null,
                            hint: 'Select arrival city', onTap: () => _openCitySheet(false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4E7EC))),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Color(0xFF166C46), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Text('Travel Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF166C46))),
                            Text('${_travelDate.day}/${_travelDate.month}/${_travelDate.year}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF101828))),
                          ])),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Operator
                  _SelectorTile(label: 'Transport Operator', value: _selectedOperator?.name,
                      hint: 'Choose your preferred operator', onTap: _openOperatorSheet),
                  const SizedBox(height: 16),

                  // Passengers
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4E7EC))),
                    child: Row(
                      children: [
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Number of Passengers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF101828))),
                          Text('Max 4 per booking', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                        ])),
                        Row(children: [
                          GestureDetector(
                            onTap: () { if (_passengers > 1) setState(() => _passengers--); },
                            child: Container(width: 32, height: 32,
                                decoration: BoxDecoration(color: _passengers > 1 ? const Color(0xFFF2F7F3) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.remove, size: 16, color: _passengers > 1 ? AppColors.goldPrimary : const Color(0xFFD0D5DD))),
                          ),
                          SizedBox(width: 20, child: Center(child: Text('$_passengers', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
                          GestureDetector(
                            onTap: () { if (_passengers < 4) setState(() => _passengers++); },
                            child: Container(width: 32, height: 32,
                                decoration: BoxDecoration(color: const Color(0xFFF2F7F3), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.add, size: 16, color: Color(0xFF166C46))),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  // Price summary
                  if (_selectedOperator != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF2F7F3), borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF166C46).withOpacity(0.2))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_passengers seat${_passengers > 1 ? 's' : ''} × ₦${_selectedOperator!.pricePerSeat}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF667085))),
                          Text('₦$_totalPrice', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF166C46))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _TransportCTA(enabled: _isFormValid, amount: _totalPrice, onTap: _handleNext),
        ],
      ),
    );
  }
}

class _RouteSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? value;
  final String hint;
  final VoidCallback onTap;

  const _RouteSelector({required this.label, required this.icon, required this.iconColor, required this.value, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
            Text(value ?? hint, style: TextStyle(fontSize: 15, fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                color: value != null ? const Color(0xFF101828) : const Color(0xFFD0D5DD))),
          ])),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF), size: 18),
        ],
      ),
    );
  }
}

class _SelectorTile extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;

  const _SelectorTile({required this.label, required this.value, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasValue ? AppColors.goldPrimary.withOpacity(0.4) : const Color(0xFFE4E7EC))),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: hasValue ? AppColors.goldPrimary : const Color(0xFF9CA3AF))),
              const SizedBox(height: 2),
              Text(value ?? hint, style: TextStyle(fontSize: 15, fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue ? const Color(0xFF101828) : const Color(0xFFD0D5DD))),
            ])),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _TransportCTA extends StatelessWidget {
  final bool enabled;
  final int amount;
  final VoidCallback? onTap;

  const _TransportCTA({required this.enabled, required this.amount, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = enabled ? 'Book Ticket — ₦$amount' : 'Continue';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity, height: 54,
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
