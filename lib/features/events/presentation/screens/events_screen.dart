import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

class _Event {
  final String id;
  final String name;
  final String venue;
  final String date;
  final String category;
  final int price;
  final String emoji;
  final Color color;
  final Color bgColor;

  const _Event({
    required this.id, required this.name, required this.venue,
    required this.date, required this.category, required this.price,
    required this.emoji, required this.color, required this.bgColor,
  });
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedCategory = 'All';
  _Event? _selectedEvent;
  int _quantity = 1;

  final List<String> _categories = ['All', 'Music', 'Sports', 'Comedy', 'Conference', 'Festival'];

  final List<_Event> _events = const [
    _Event(id: 'e1', name: 'Afrobeats Festival Lagos', venue: 'Eko Convention Centre, Lagos', date: 'Sat, 15 Feb 2026',
        category: 'Music', price: 15000, emoji: '🎵', color: Color(0xFFEC4899), bgColor: Color(0xFFfdf2f8)),
    _Event(id: 'e2', name: 'Super Eagles vs Cameroon', venue: 'Moshood Abiola Stadium, Abuja', date: 'Wed, 19 Feb 2026',
        category: 'Sports', price: 5000, emoji: '⚽', color: Color(0xFF166C46), bgColor: Color(0xFFF2F7F3)),
    _Event(id: 'e3', name: 'Night of A Thousand Laughs', venue: 'Civic Centre, Lagos', date: 'Fri, 28 Feb 2026',
        category: 'Comedy', price: 10000, emoji: '😂', color: Color(0xFFF59E0B), bgColor: Color(0xFFFFFBEB)),
    _Event(id: 'e4', name: 'TechFest Nigeria 2026', venue: 'Landmark Event Centre, Lagos', date: 'Thu, 6 Mar 2026',
        category: 'Conference', price: 25000, emoji: '💻', color: Color(0xFF8B5CF6), bgColor: Color(0xFFf5f3ff)),
    _Event(id: 'e5', name: 'Calabar Carnival 2026', venue: 'Cultural Centre, Calabar', date: 'Sat, 27 Dec 2026',
        category: 'Festival', price: 3000, emoji: '🎉', color: Color(0xFFF97316), bgColor: Color(0xFFfff7ed)),
    _Event(id: 'e6', name: 'Rema Live in Abuja', venue: 'International Conference Centre', date: 'Fri, 21 Mar 2026',
        category: 'Music', price: 20000, emoji: '🎤', color: Color(0xFFEC4899), bgColor: Color(0xFFfdf2f8)),
  ];

  List<_Event> get _filteredEvents => _selectedCategory == 'All'
      ? _events
      : _events.where((e) => e.category == _selectedCategory).toList();

  int get _totalPrice => (_selectedEvent?.price ?? 0) * _quantity;

  bool get _isFormValid => _selectedEvent != null;

  void _handleNext() {
    if (!_isFormValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Event', 'value': _selectedEvent!.name},
        {'label': 'Venue', 'value': _selectedEvent!.venue},
        {'label': 'Date', 'value': _selectedEvent!.date},
        {'label': 'Tickets', 'value': '$_quantity ticket${_quantity > 1 ? 's' : ''}'},
        {'label': 'Amount', 'value': '₦$_totalPrice'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        context.pushReplacement('/success', extra: SuccessScreenProps(
          transactionType: 'Event Ticket',
          amount: _totalPrice.toString(),
          recipient: _selectedEvent!.name,
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
            title: 'Event Tickets',
            subtitle: 'Concerts, shows & experiences',
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

                  // Category chips
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(right: i == _categories.length - 1 ? 0 : 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.goldPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: isSelected ? AppColors.goldPrimary : const Color(0xFFE4E7EC)),
                            ),
                            child: Text(cat, style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF374151),
                            )),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Events list
                  const Text('Available Events', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 10),

                  ..._filteredEvents.map((event) {
                    final isSelected = _selectedEvent?.id == event.id;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedEvent = event;
                        _quantity = 1;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? event.bgColor : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? event.color.withOpacity(0.5) : const Color(0xFFE4E7EC),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(color: event.bgColor, borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(event.emoji, style: TextStyle(fontSize: 26))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                  const SizedBox(height: 2),
                                  Text(event.venue, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF9CA3AF)),
                                      const SizedBox(width: 4),
                                      Text(event.date, style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₦${event.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: event.color)),
                                const Text('/ticket', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Color(0xFF166C46), size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Quantity selector
                  if (_selectedEvent != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Number of Tickets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                                Text('Max 10 tickets per order', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () { if (_quantity > 1) setState(() => _quantity--); },
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: _quantity > 1 ? const Color(0xFFF2F7F3) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.remove, size: 16, color: _quantity > 1 ? AppColors.goldPrimary : const Color(0xFFD0D5DD)),
                                ),
                              ),
                              SizedBox(width: 16, child: Center(child: Text('$_quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
                              GestureDetector(
                                onTap: () { if (_quantity < 10) setState(() => _quantity++); },
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(color: const Color(0xFFF2F7F3), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.add, size: 16, color: Color(0xFF166C46)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF166C46).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_quantity ticket${_quantity > 1 ? 's' : ''} × ₦${_selectedEvent!.price}',
                              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          Text('₦$_totalPrice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF166C46))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _EventCTA(enabled: _isFormValid, total: _totalPrice, quantity: _quantity, onTap: _handleNext),
        ],
      ),
    );
  }
}

class _EventCTA extends StatelessWidget {
  final bool enabled;
  final int total;
  final int quantity;
  final VoidCallback? onTap;

  const _EventCTA({required this.enabled, required this.total, required this.quantity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = enabled ? 'Buy $quantity Ticket${quantity > 1 ? 's' : ''} — ₦$total' : 'Continue';
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
