import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

class _GovService {
  final String id;
  final String name;
  final String agency;
  final String description;
  final String refLabel;
  final String refHint;
  final int? fixedAmount;
  final Color color;
  final IconData icon;

  const _GovService({
    required this.id, required this.name, required this.agency,
    required this.description, required this.refLabel, required this.refHint,
    this.fixedAmount, required this.color, required this.icon,
  });
}

class GovernmentScreen extends StatefulWidget {
  const GovernmentScreen({super.key});

  @override
  State<GovernmentScreen> createState() => _GovernmentScreenState();
}

class _GovernmentScreenState extends State<GovernmentScreen> {
  _GovService? _selectedService;
  final _refController = TextEditingController();
  final _amountController = TextEditingController();
  final _refFocus = FocusNode();
  final _amountFocus = FocusNode();

  final List<_GovService> _services = const [
    _GovService(
      id: 'firs_tax', name: 'Company Income Tax', agency: 'FIRS',
      description: 'Federal Inland Revenue Service', refLabel: 'TIN / Tax Reference',
      refHint: 'Enter your TIN number', color: Color(0xFF1D4ED8), icon: Icons.account_balance_outlined,
    ),
    _GovService(
      id: 'lirs_tax', name: 'Personal Income Tax', agency: 'LIRS',
      description: 'Lagos Internal Revenue Service', refLabel: 'LIRS Tax ID',
      refHint: 'Enter your LIRS ID', color: Color(0xFF059669), icon: Icons.person_outline_rounded,
    ),
    _GovService(
      id: 'vehicle_reg', name: 'Vehicle Registration', agency: 'FRSC',
      description: 'Federal Road Safety Corps', refLabel: 'Plate Number / Chassis No.',
      refHint: 'e.g. ABC-123-EF or VIN', fixedAmount: 15000,
      color: Color(0xFF7C3AED), icon: Icons.directions_car_outlined,
    ),
    _GovService(
      id: 'drivers_license', name: "Driver's License Renewal", agency: 'FRSC',
      description: 'Federal Road Safety Corps', refLabel: "Driver's License Number",
      refHint: 'e.g. AAA00000000001', fixedAmount: 10000,
      color: Color(0xFFD97706), icon: Icons.badge_outlined,
    ),
    _GovService(
      id: 'nin_slip', name: 'NIN Slip Reprint', agency: 'NIMC',
      description: 'National Identity Management Commission', refLabel: 'NIN Number',
      refHint: 'Your 11-digit NIN', fixedAmount: 500,
      color: Color(0xFF0891B2), icon: Icons.fingerprint_rounded,
    ),
    _GovService(
      id: 'cac_search', name: 'CAC Name Search', agency: 'CAC',
      description: 'Corporate Affairs Commission', refLabel: 'Company / Business Name',
      refHint: 'Name to search', fixedAmount: 500,
      color: Color(0xFFBE185D), icon: Icons.business_outlined,
    ),
    _GovService(
      id: 'nhis', name: 'NHIS Contribution', agency: 'NHIS',
      description: 'National Health Insurance Scheme', refLabel: 'NHIS Number',
      refHint: 'Your NHIS ID', color: Color(0xFF16A34A), icon: Icons.health_and_safety_outlined,
    ),
    _GovService(
      id: 'land_use', name: 'Land Use Charge', agency: 'LAGREV',
      description: 'Lagos State Internal Revenue', refLabel: 'Property / Bill Reference',
      refHint: 'LUC bill reference number', color: Color(0xFF9333EA), icon: Icons.home_work_outlined,
    ),
  ];

  bool get _isFormValid {
    final refOk = _refController.text.trim().length >= 4;
    if (_selectedService?.fixedAmount != null) return _selectedService != null && refOk;
    return _selectedService != null && refOk &&
        _amountController.text.isNotEmpty &&
        (double.tryParse(_amountController.text) ?? 0) >= 100;
  }

  String get _displayAmount {
    if (_selectedService?.fixedAmount != null) return _selectedService!.fixedAmount!.toString();
    return _amountController.text;
  }

  void _openServiceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFFE4E7EC), borderRadius: BorderRadius.circular(999))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(alignment: Alignment.centerLeft,
                    child: Text('Select Service', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF101828)))),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  itemCount: _services.length,
                  itemBuilder: (_, i) {
                    final svc = _services[i];
                    final isSelected = _selectedService?.id == svc.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedService = svc;
                          _refController.clear();
                          _amountController.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFFAFBFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF00B252).withOpacity(0.4) : const Color(0xFFE4E7EC)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(color: svc.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                              child: Icon(svc.icon, size: 20, color: svc.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(svc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
                                Text('${svc.agency} · ${svc.description}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF667085)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                            if (svc.fixedAmount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: svc.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text('₦${svc.fixedAmount}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: svc.color)),
                              )
                            else
                              const Icon(Icons.keyboard_arrow_right_rounded, color: Color(0xFF9CA3AF), size: 18),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle, color: Color(0xFF00B252), size: 20),
                            ],
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

  void _handleNext() {
    if (!_isFormValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': _selectedService!.name},
        {'label': 'Agency', 'value': '${_selectedService!.agency} – ${_selectedService!.description}'},
        {'label': _selectedService!.refLabel, 'value': _refController.text},
        {'label': 'Amount', 'value': '₦$_displayAmount'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        context.pushReplacement('/success', extra: SuccessScreenProps(
          transactionType: _selectedService!.name,
          amount: _displayAmount,
          recipient: '${_selectedService!.agency} – ${_refController.text}',
        ));
      },
    );
  }

  @override
  void dispose() {
    _refController.dispose();
    _amountController.dispose();
    _refFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          BillGreenHeader(
            title: 'Government Services',
            subtitle: 'Taxes, levies & official payments',
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

                  // Info banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_outlined, size: 16, color: Color(0xFF3B82F6)),
                        SizedBox(width: 8),
                        Expanded(child: Text('Payments are forwarded directly to the relevant government agency',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service selector
                  _SelectorTile(
                    label: 'Government Service',
                    value: _selectedService == null ? null : '${_selectedService!.name} (${_selectedService!.agency})',
                    hint: 'Select a service to pay',
                    icon: _selectedService?.icon ?? Icons.account_balance_outlined,
                    iconColor: _selectedService?.color ?? const Color(0xFF9CA3AF),
                    onTap: _openServiceSheet,
                  ),
                  const SizedBox(height: 16),

                  // Reference field
                  if (_selectedService != null) ...[
                    BillFloatingField(
                      controller: _refController,
                      focusNode: _refFocus,
                      label: _selectedService!.refLabel,
                      hint: _selectedService!.refHint,
                      keyboardType: _selectedService!.id == 'nin_slip'
                          ? TextInputType.number
                          : TextInputType.text,
                      inputFormatters: _selectedService!.id == 'nin_slip'
                          ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]
                          : [],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Amount — fixed or user-entered
                    if (_selectedService!.fixedAmount != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00B252).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_outlined, color: Color(0xFF00B252), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Payment Amount', style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
                                Text('₦${_selectedService!.fixedAmount}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF00B252))),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF00B252).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: const Text('Fixed Fee', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF00B252))),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      BillAmountCard(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        onChanged: (_) => setState(() {}),
                        minMax: 'Min: ₦100',
                      ),
                    ],
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _GovCTA(enabled: _isFormValid, amount: _displayAmount, onTap: _handleNext),
        ],
      ),
    );
  }
}

class _SelectorTile extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SelectorTile({required this.label, required this.value, required this.hint,
    required this.icon, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? const Color(0xFF00B252).withOpacity(0.4) : const Color(0xFFE4E7EC)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: hasValue ? iconColor : const Color(0xFF9CA3AF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                      color: hasValue ? const Color(0xFF00B252) : const Color(0xFF9CA3AF))),
                  const SizedBox(height: 2),
                  Text(value ?? hint, style: TextStyle(fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue ? const Color(0xFF101828) : const Color(0xFFD0D5DD)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _GovCTA extends StatelessWidget {
  final bool enabled;
  final String amount;
  final VoidCallback? onTap;

  const _GovCTA({required this.enabled, required this.amount, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = amount.isNotEmpty && (double.tryParse(amount) ?? 0) > 0
        ? 'Pay ₦$amount'
        : 'Continue';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: enabled ? const LinearGradient(colors: [Color(0xFF00B252), Color(0xFF00A651)], begin: Alignment.centerLeft, end: Alignment.centerRight) : null,
            color: enabled ? null : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: enabled ? Colors.white : const Color(0xFF9CA3AF)))),
        ),
      ),
    );
  }
}
