import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';
import '../../../bills/data/bills_dtos.dart';
import '../../../bills/presentation/providers/bills_providers.dart';
import '../../../bills/presentation/widgets/bill_purchase_flow.dart';

import '../../../../core/localization/l10n.dart';
class _GovService {
  final String id;
  final int billerId;
  final String name;
  final String agency;
  final String description;
  final String refLabel;
  final String refHint;

  /// Always null in the picker; the real fixed fee comes from the biller's item.
  final int? fixedAmount = null;
  final Color color;
  final IconData icon;

  const _GovService({
    required this.id, required this.billerId, required this.name, required this.agency,
    required this.description, required this.refLabel, required this.refHint,
    required this.color, required this.icon,
  });

  static const _colors = [
    Color(0xFF1D4ED8), Color(0xFF0E5C37), Color(0xFF7C3AED), Color(0xFFD97706),
    Color(0xFF0891B2), Color(0xFFBE185D), Color(0xFF16A34A), Color(0xFF9333EA),
  ];
  static const _icons = [
    Icons.account_balance_outlined, Icons.person_outline_rounded,
    Icons.directions_car_outlined, Icons.badge_outlined, Icons.fingerprint_rounded,
    Icons.business_outlined, Icons.health_and_safety_outlined, Icons.home_work_outlined,
  ];

  factory _GovService.fromBiller(BillerDto b, int index) {
    final label = (b.customerField1?.trim().isNotEmpty ?? false)
        ? b.customerField1!.trim()
        : 'Reference Number';
    return _GovService(
      id: '${b.billerId}',
      billerId: b.billerId,
      name: b.name ?? b.displayName,
      agency: b.displayName,
      description: b.narration ?? b.categoryName ?? '',
      refLabel: label,
      refHint: 'Enter ${label.toLowerCase()}',
      color: _colors[index % _colors.length],
      icon: _icons[index % _icons.length],
    );
  }
}

class GovernmentScreen extends ConsumerStatefulWidget {
  const GovernmentScreen({super.key});

  @override
  ConsumerState<GovernmentScreen> createState() => _GovernmentScreenState();
}

class _GovernmentScreenState extends ConsumerState<GovernmentScreen> {
  _GovService? _selectedService;
  final _refController = TextEditingController();
  final _amountController = TextEditingController();
  final _refFocus = FocusNode();
  final _amountFocus = FocusNode();

  List<_GovService> get _services {
    final billers =
        ref.read(billersByKindProvider(BillCategoryKind.government)).valueOrNull?.billers ??
            const <BillerDto>[];
    return [
      for (var i = 0; i < billers.length; i++) _GovService.fromBiller(billers[i], i),
    ];
  }

  /// The biller's payment item (government billers expose a single item).
  BillerItemDto? get _selectedItem {
    final svc = _selectedService;
    if (svc == null) return null;
    final items = ref.read(billerItemsProvider(svc.billerId)).valueOrNull ?? const [];
    return items.isEmpty ? null : items.first;
  }

  int? get _fixedAmount {
    final item = _selectedItem;
    return (item != null && item.isAmountFixed && item.amount > 0) ? item.amount.round() : null;
  }

  bool get _isFormValid {
    final refOk = _refController.text.trim().length >= 4;
    if (_selectedService == null || _selectedItem == null || !refOk) return false;
    if (_fixedAmount != null) return true;
    return (double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0) >= 100;
  }

  String get _displayAmount {
    if (_fixedAmount != null) return _fixedAmount!.toString();
    return _amountController.text;
  }

  void _openServiceSheet() {
    if (ref.read(billersByKindProvider(BillCategoryKind.government)).isLoading) return;
    final services = _services;
    if (services.isEmpty) {
      refreshBillers(ref, BillCategoryKind.government);
      showBillError(context, 'No government services available right now. Retrying…');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        maxChildSize: 0.92,
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
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(alignment: Alignment.centerLeft,
                    child: Text(context.l10n.selectService, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface))),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  itemCount: services.length,
                  itemBuilder: (_, i) {
                    final svc = services[i];
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
                          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.goldPrimary.withOpacity(0.4) : Theme.of(context).dividerColor),
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
                                Text(svc.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                Text(context.l10n.agencyDescription(svc.agency, svc.description),
                                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                            if (svc.fixedAmount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: svc.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(context.l10n.fixedamount(svc.fixedAmount ?? 0), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: svc.color)),
                              )
                            else
                              Icon(Icons.keyboard_arrow_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 18),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle, color: Color(0xFF166C46), size: 20),
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
    final svc = _selectedService;
    final item = _selectedItem;
    if (!_isFormValid || svc == null || item == null) return;
    final reference = _refController.text.trim();
    final fixed = _fixedAmount;
    final amountText = _displayAmount;
    runBillPurchase(
      context: context,
      summary: [
        {'label': 'Service', 'value': svc.name},
        {'label': 'Agency', 'value': svc.description.isEmpty ? svc.agency : '${svc.agency} – ${svc.description}'},
        {'label': svc.refLabel, 'value': reference},
        {'label': 'Amount', 'value': '₦$amountText'},
      ],
      submit: (pin, sourceAccount) =>
          ref.read(billsApiServiceProvider).payBill(BillPaymentRequest(
                sourceAccount: sourceAccount,
                billerId: svc.billerId,
                billerItemId: item.billerItemId,
                customerId: reference,
                amount: fixed != null
                    ? null
                    : double.tryParse(amountText.replaceAll(',', '')),
                transactionPin: pin,
              )),
      successProps: (result) => SuccessScreenProps(
        transactionType: svc.name,
        amount: amountText,
        recipient: '${svc.agency} – $reference',
        transactionId: result.transactionReference,
      ),
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
    final billersAsync = ref.watch(billersByKindProvider(BillCategoryKind.government));
    final itemsLoading = _selectedService != null &&
        ref.watch(billerItemsProvider(_selectedService!.billerId)).isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          BillGreenHeader(
            title: context.l10n.governmentServices,
            subtitle: context.l10n.taxesLeviesOfficialPayments,
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
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_outlined, size: 16, color: Color(0xFF3B82F6)),
                        SizedBox(width: 8),
                        Expanded(child: Text(context.l10n.paymentsAreForwardedDirectlyToThe,
                            style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service selector
                  _SelectorTile(
                    label: context.l10n.governmentService,
                    value: _selectedService == null ? null : '${_selectedService!.name} (${_selectedService!.agency})',
                    hint: billersAsync.isLoading ? 'Loading services…' : 'Select a service to pay',
                    icon: _selectedService?.icon ?? Icons.account_balance_outlined,
                    iconColor: _selectedService?.color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                    if (itemsLoading) ...[
                      Text(context.l10n.loadingPaymentDetails,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    ] else if (_fixedAmount != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF166C46).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_outlined, color: Color(0xFF166C46), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(context.l10n.paymentAmount, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                Text(context.l10n.fixedamount2(_fixedAmount ?? 0),
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF166C46))),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF166C46).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(context.l10n.fixedFee, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166C46))),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? AppColors.goldPrimary.withOpacity(0.4) : Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: hasValue ? iconColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                      color: hasValue ? AppColors.goldPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                  const SizedBox(height: 2),
                  Text(value ?? hint, style: TextStyle(fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue ? Theme.of(context).colorScheme.onSurface : Theme.of(context).dividerColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
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
      decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: Theme.of(context).scaffoldBackgroundColor))),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.goldGradient : null,
            color: enabled ? null : Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: enabled ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)))),
        ),
      ),
    );
  }
}
