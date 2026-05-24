import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

class _Airport {
  final String code;
  final String city;
  final String name;

  const _Airport({required this.code, required this.city, required this.name});
}

class _Airline {
  final String id;
  final String name;
  final String shortName;
  final Color color;

  const _Airline({required this.id, required this.name, required this.shortName, required this.color});
}

class _Flight {
  final String id;
  final _Airline airline;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final int price;
  final String class_;
  final int stops;

  const _Flight({
    required this.id, required this.airline, required this.departureTime,
    required this.arrivalTime, required this.duration, required this.price,
    required this.class_, required this.stops,
  });
}

class FlightsScreen extends StatefulWidget {
  const FlightsScreen({super.key});

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> {
  String _tripType = 'One Way';
  _Airport? _origin;
  _Airport? _destination;
  DateTime? _departureDate;
  DateTime? _returnDate;
  int _passengers = 1;
  String _class = 'Economy';
  _Flight? _selectedFlight;
  bool _searched = false;

  final List<_Airport> _airports = const [
    _Airport(code: 'LOS', city: 'Lagos', name: 'Murtala Muhammed International Airport'),
    _Airport(code: 'ABV', city: 'Abuja', name: 'Nnamdi Azikiwe International Airport'),
    _Airport(code: 'KAN', city: 'Kano', name: 'Mallam Aminu Kano International Airport'),
    _Airport(code: 'PHC', city: 'Port Harcourt', name: 'Port Harcourt International Airport'),
    _Airport(code: 'ENU', city: 'Enugu', name: 'Akanu Ibiam International Airport'),
    _Airport(code: 'CBQ', city: 'Calabar', name: 'Margaret Ekpo International Airport'),
    _Airport(code: 'ILR', city: 'Ilorin', name: 'Ilorin International Airport'),
  ];

  static const List<_Airline> _airlines = [
    _Airline(id: 'airpeace', name: 'Air Peace', shortName: 'Air Peace', color: Color(0xFF003087)),
    _Airline(id: 'ibomair', name: 'Ibom Air', shortName: 'Ibom Air', color: Color(0xFF00529B)),
    _Airline(id: 'dana', name: 'Dana Air', shortName: 'Dana Air', color: Color(0xFFD4042A)),
  ];

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatPrice(int price) =>
      price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  List<_Flight> get _mockFlights {
    if (_origin == null || _destination == null) return [];
    final base = (_origin!.code == 'LOS' || _destination!.code == 'LOS') ? 28000 : 22000;
    final mult = _class == 'Business' ? 2.5 : 1.0;
    return [
      _Flight(id: 'f1', airline: _airlines[0], departureTime: '06:30', arrivalTime: '08:00',
          duration: '1h 30m', price: (base * mult).round(), class_: _class, stops: 0),
      _Flight(id: 'f2', airline: _airlines[1], departureTime: '10:15', arrivalTime: '11:55',
          duration: '1h 40m', price: ((base - 3000) * mult).round(), class_: _class, stops: 0),
      _Flight(id: 'f3', airline: _airlines[2], departureTime: '15:45', arrivalTime: '17:30',
          duration: '1h 45m', price: ((base - 5000) * mult).round(), class_: _class, stops: 0),
    ];
  }

  bool get _canSearch =>
      _origin != null && _destination != null && _departureDate != null &&
      (_tripType == 'One Way' || _returnDate != null);

  bool get _isFormValid => _selectedFlight != null;

  int get _totalPrice => (_selectedFlight?.price ?? 0) * _passengers;

  void _openAirportSheet({required bool isOrigin}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(isOrigin ? 'Select Origin' : 'Select Destination',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  itemCount: _airports.length,
                  itemBuilder: (_, i) {
                    final ap = _airports[i];
                    final current = isOrigin ? _origin : _destination;
                    final isSelected = current?.code == ap.code;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isOrigin) _origin = ap;
                          else _destination = ap;
                          _searched = false;
                          _selectedFlight = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF2F7F3) : const Color(0xFFFAFBFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.goldPrimary.withOpacity(0.4) : const Color(0xFFE4E7EC)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.goldPrimary : const Color(0xFF374151),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(child: Text(ap.code,
                                  style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.w800, fontSize: 12))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(ap.city, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                Text(ap.name, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
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

  Future<void> _pickDate({required bool isReturn}) async {
    final now = DateTime.now();
    final first = isReturn ? (_departureDate ?? now).add(const Duration(days: 1)) : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: DateTime(2027),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF166C46), onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isReturn) _returnDate = picked;
        else { _departureDate = picked; _searched = false; _selectedFlight = null; }
      });
    }
  }

  void _handleNext() {
    if (!_isFormValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Route', 'value': '${_origin!.code} → ${_destination!.code}'},
        {'label': 'Airline', 'value': _selectedFlight!.airline.name},
        {'label': 'Departure', 'value': '${_formatDate(_departureDate!)} · ${_selectedFlight!.departureTime}'},
        {'label': 'Class', 'value': _class},
        {'label': 'Passengers', 'value': '$_passengers passenger${_passengers > 1 ? 's' : ''}'},
        {'label': 'Amount', 'value': '₦${_formatPrice(_totalPrice)}'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        context.pushReplacement('/success', extra: SuccessScreenProps(
          transactionType: 'Flight Booking',
          amount: _totalPrice.toString(),
          recipient: '${_selectedFlight!.airline.name} – ${_origin!.code} → ${_destination!.code}',
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
          BillGreenHeader(
            title: 'Book Flights',
            subtitle: 'Domestic flights at best prices',
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

                  // Trip type chips
                  Row(
                    children: ['One Way', 'Round Trip'].map((type) {
                      final isSelected = _tripType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() { _tripType = type; _searched = false; _selectedFlight = null; }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(right: type == 'One Way' ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF2F7F3) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppColors.goldPrimary : const Color(0xFFE4E7EC), width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              children: [
                                Icon(type == 'One Way' ? Icons.flight_takeoff : Icons.sync_alt_rounded,
                                    size: 18, color: isSelected ? AppColors.goldPrimary : const Color(0xFF9CA3AF)),
                                const SizedBox(height: 4),
                                Text(type, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                    color: isSelected ? AppColors.goldPrimary : const Color(0xFF374151))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Route selection
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        _AirportTile(
                          label: 'From',
                          airport: _origin,
                          hint: 'Select origin city',
                          icon: Icons.flight_takeoff,
                          onTap: () => _openAirportSheet(isOrigin: true),
                        ),
                        Container(height: 1, color: Theme.of(context).scaffoldBackgroundColor, margin: EdgeInsets.symmetric(horizontal: 16)),
                        _AirportTile(
                          label: 'To',
                          airport: _destination,
                          hint: 'Select destination city',
                          icon: Icons.flight_land,
                          onTap: () => _openAirportSheet(isOrigin: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          label: 'Departure',
                          date: _departureDate != null ? _formatDate(_departureDate!) : null,
                          hint: 'Select date',
                          onTap: () => _pickDate(isReturn: false),
                        ),
                      ),
                      if (_tripType == 'Round Trip') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateTile(
                            label: 'Return',
                            date: _returnDate != null ? _formatDate(_returnDate!) : null,
                            hint: 'Select date',
                            onTap: () => _pickDate(isReturn: true),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Passengers + class
                  Row(
                    children: [
                      // Passengers
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Passengers', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () { if (_passengers > 1) setState(() => _passengers--); },
                                    child: Container(width: 28, height: 28,
                                        decoration: BoxDecoration(color: _passengers > 1 ? const Color(0xFFF2F7F3) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                                        child: Icon(Icons.remove, size: 14, color: _passengers > 1 ? AppColors.goldPrimary : const Color(0xFFD0D5DD))),
                                  ),
                                  Expanded(child: Center(child: Text('$_passengers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
                                  GestureDetector(
                                    onTap: () { if (_passengers < 9) setState(() => _passengers++); },
                                    child: Container(width: 28, height: 28,
                                        decoration: BoxDecoration(color: const Color(0xFFF2F7F3), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.add, size: 14, color: Color(0xFF166C46))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Class
                      Expanded(
                        child: Column(
                          children: ['Economy', 'Business'].map((c) {
                            final isSelected = _class == c;
                            return GestureDetector(
                              onTap: () => setState(() { _class = c; _searched = false; _selectedFlight = null; }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: EdgeInsets.only(bottom: c == 'Economy' ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFF2F7F3) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSelected ? AppColors.goldPrimary : const Color(0xFFE4E7EC), width: isSelected ? 2 : 1),
                                ),
                                child: Row(
                                  children: [
                                    Icon(c == 'Economy' ? Icons.airline_seat_recline_normal : Icons.airline_seat_flat,
                                        size: 14, color: isSelected ? AppColors.goldPrimary : const Color(0xFF9CA3AF)),
                                    const SizedBox(width: 6),
                                    Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                        color: isSelected ? AppColors.goldPrimary : const Color(0xFF374151))),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search button
                  GestureDetector(
                    onTap: _canSearch ? () => setState(() { _searched = true; _selectedFlight = null; }) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity, height: 48,
                      decoration: BoxDecoration(
                        gradient: _canSearch ? AppColors.goldGradient : null,
                        color: _canSearch ? null : const Color(0xFFE4E7EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: _canSearch ? Colors.white : const Color(0xFF9CA3AF)),
                          const SizedBox(width: 8),
                          Text('Search Flights', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                              color: _canSearch ? Colors.white : const Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                  ),

                  // Results
                  if (_searched) ...[
                    const SizedBox(height: 20),
                    Text('${_mockFlights.length} flights found · ${_origin!.code} → ${_destination!.code}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    const SizedBox(height: 10),
                    ..._mockFlights.map((flight) {
                      final isSelected = _selectedFlight?.id == flight.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFlight = flight),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF2F7F3) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.goldPrimary.withOpacity(0.5) : const Color(0xFFE4E7EC),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(color: flight.airline.color, borderRadius: BorderRadius.circular(8)),
                                    child: Center(child: Text(flight.airline.shortName[0],
                                        style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.w800, fontSize: 14))),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(flight.airline.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                      Text(flight.stops == 0 ? 'Non-stop · ${flight.duration}' : '${flight.stops} stop · ${flight.duration}',
                                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                    ]),
                                  ),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('₦${_formatPrice(flight.price)}',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF166C46))),
                                    const Text('/person', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _TimeChip(time: flight.departureTime, code: _origin!.code),
                                  Row(children: [
                                    Container(width: 30, height: 1, color: Theme.of(context).dividerColor),
                                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.flight, size: 16, color: Color(0xFF9CA3AF))),
                                    Container(width: 30, height: 1, color: Theme.of(context).dividerColor),
                                  ]),
                                  _TimeChip(time: flight.arrivalTime, code: _destination!.code),
                                ],
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF166C46).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Icon(Icons.check_circle, color: Color(0xFF166C46), size: 14),
                                    const SizedBox(width: 6),
                                    Text('Selected · $_passengers × ₦${_formatPrice(flight.price)} = ₦${_formatPrice(_totalPrice)}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166C46))),
                                  ]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _FlightCTA(enabled: _isFormValid, total: _totalPrice, searched: _searched, onTap: _handleNext),
        ],
      ),
    );
  }
}

class _AirportTile extends StatelessWidget {
  final String label;
  final _Airport? airport;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  const _AirportTile({required this.label, required this.airport, required this.hint, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = airport != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: hasValue ? AppColors.goldPrimary : const Color(0xFF9CA3AF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: hasValue ? AppColors.goldPrimary : const Color(0xFF9CA3AF))),
                const SizedBox(height: 2),
                Text(hasValue ? '${airport!.city} (${airport!.code})' : hint,
                    style: TextStyle(fontSize: 15, fontWeight: hasValue ? FontWeight.w700 : FontWeight.normal,
                        color: hasValue ? const Color(0xFF101828) : const Color(0xFFD0D5DD))),
              ]),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String? date;
  final String hint;
  final VoidCallback onTap;

  const _DateTile({required this.label, required this.date, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? AppColors.goldPrimary.withOpacity(0.4) : const Color(0xFFE4E7EC)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
              color: hasValue ? AppColors.goldPrimary : const Color(0xFF9CA3AF))),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.calendar_today_outlined, size: 13, color: hasValue ? AppColors.goldPrimary : const Color(0xFFD0D5DD)),
            const SizedBox(width: 6),
            Expanded(child: Text(date ?? hint, style: TextStyle(fontSize: 12,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                color: hasValue ? const Color(0xFF101828) : const Color(0xFFD0D5DD)),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ]),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final String code;

  const _TimeChip({required this.time, required this.code});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        Text(code, style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ],
    );
  }
}

class _FlightCTA extends StatelessWidget {
  final bool enabled;
  final int total;
  final bool searched;
  final VoidCallback? onTap;

  const _FlightCTA({required this.enabled, required this.total, required this.searched, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = enabled
        ? 'Book Flight — ₦${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
        : searched ? 'Select a Flight' : 'Search Flights';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
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
