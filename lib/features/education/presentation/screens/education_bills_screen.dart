import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';
import '../../../bills/data/bills_dtos.dart';
import '../../../bills/presentation/providers/bills_providers.dart';
import '../../../bills/presentation/widgets/bill_purchase_flow.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _EduProvider {
  final String id;
  final int billerId;
  final String name;
  final String description;
  final String icon;

  const _EduProvider({
    required this.id,
    required this.billerId,
    required this.name,
    required this.description,
    required this.icon,
  });

  static const _icons = ['🎓', '📚', '📝', '🔧'];

  factory _EduProvider.fromBiller(BillerDto b, int index) => _EduProvider(
        id: '${b.billerId}',
        billerId: b.billerId,
        name: b.displayName,
        description: b.name ?? b.narration ?? '',
        icon: _icons[index % _icons.length],
      );
}

class _EduExamType {
  final String id;
  final String name;
  final String price;
  final String description;
  final double amount;
  final bool isAmountFixed;

  const _EduExamType({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.amount = 0,
    this.isAmountFixed = true,
  });

  factory _EduExamType.fromItem(BillerItemDto i, String providerName) => _EduExamType(
        id: i.billerItemId,
        name: i.name ?? 'Payment',
        price: formatBillAmount(i.amount),
        description: providerName,
        amount: i.amount,
        isAmountFixed: i.isAmountFixed,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class EducationBillsScreen extends ConsumerStatefulWidget {
  const EducationBillsScreen({super.key});

  @override
  ConsumerState<EducationBillsScreen> createState() => _EducationBillsScreenState();
}

class _EducationBillsScreenState extends ConsumerState<EducationBillsScreen> {
  _EduProvider? _selectedProvider;
  _EduExamType? _selectedExam;
  final _candidateController = TextEditingController();
  final _candidateFocus = FocusNode();

  List<_EduProvider> get _providers {
    final billers =
        ref.read(billersByKindProvider(BillCategoryKind.education)).valueOrNull?.billers ??
            const <BillerDto>[];
    return [
      for (var i = 0; i < billers.length; i++) _EduProvider.fromBiller(billers[i], i),
    ];
  }

  List<_EduExamType> get _examTypes {
    final provider = _selectedProvider;
    if (provider == null) return const [];
    final items = ref.read(billerItemsProvider(provider.billerId)).valueOrNull ??
        const <BillerItemDto>[];
    return items.map((i) => _EduExamType.fromItem(i, provider.name)).toList();
  }

  bool get _isFormValid =>
      _selectedProvider != null &&
      _selectedExam != null &&
      _selectedExam!.amount > 0 &&
      _candidateController.text.length >= 6;

  void _handleNext() {
    final provider = _selectedProvider;
    final exam = _selectedExam;
    if (!_isFormValid || provider == null || exam == null) return;
    final candidate = _candidateController.text;
    runBillPurchase(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Education'},
        {'label': 'Provider', 'value': provider.name},
        {'label': 'Exam Type', 'value': exam.name},
        {'label': 'Candidate No.', 'value': candidate},
        {'label': 'Amount', 'value': '₦${exam.price}'},
      ],
      submit: (pin, sourceAccount) =>
          ref.read(billsApiServiceProvider).payBill(BillPaymentRequest(
                sourceAccount: sourceAccount,
                billerId: provider.billerId,
                billerItemId: exam.id,
                customerId: candidate,
                amount: exam.isAmountFixed ? null : exam.amount,
                transactionPin: pin,
              )),
      successProps: (result) => SuccessScreenProps(
        transactionType: '${provider.name} — ${exam.name}',
        amount: exam.price,
        recipient: candidate,
        transactionId: result.transactionReference,
      ),
    );
  }

  void _openProviderSheet() {
    if (ref.read(billersByKindProvider(BillCategoryKind.education)).isLoading) return;
    final providers = _providers;
    if (providers.isEmpty) {
      refreshBillers(ref, BillCategoryKind.education);
      showBillError(context, 'No exam bodies available right now. Retrying…');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProviderSheet(
        providers: providers,
        selected: _selectedProvider,
        onSelect: (p) {
          setState(() {
            _selectedProvider = p;
            _selectedExam = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openExamSheet() {
    if (_selectedProvider == null) return;
    if (ref.read(billerItemsProvider(_selectedProvider!.billerId)).isLoading) return;
    final examTypes = _examTypes;
    if (examTypes.isEmpty) {
      ref.invalidate(billerItemsProvider(_selectedProvider!.billerId));
      showBillError(context, 'No payment options available right now. Retrying…');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExamSheet(
        examTypes: examTypes,
        selected: _selectedExam,
        onSelect: (e) {
          setState(() => _selectedExam = e);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _candidateController.dispose();
    _candidateFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billersAsync = ref.watch(billersByKindProvider(BillCategoryKind.education));
    final itemsLoading = _selectedProvider != null &&
        ref.watch(billerItemsProvider(_selectedProvider!.billerId)).isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          BillGreenHeader(
            title: 'Education',
            subtitle: 'WAEC, JAMB, NECO & more',
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

                  // Provider selector
                  _DropdownField(
                    label: 'Exam Body',
                    value: _selectedProvider?.name,
                    hint: billersAsync.isLoading ? 'Loading…' : 'Select exam body',
                    onTap: _openProviderSheet,
                  ),
                  const SizedBox(height: 16),

                  // Exam type selector
                  _DropdownField(
                    label: 'Exam Type',
                    value: _selectedExam?.name,
                    hint: _selectedProvider == null
                        ? 'Select exam body first'
                        : itemsLoading
                            ? 'Loading…'
                            : 'Select exam type',
                    subLabel: _selectedExam != null ? '₦${_selectedExam!.price} · ${_selectedExam!.description}' : null,
                    enabled: _selectedProvider != null,
                    onTap: _openExamSheet,
                  ),
                  const SizedBox(height: 16),

                  // Candidate number
                  BillFloatingField(
                    controller: _candidateController,
                    focusNode: _candidateFocus,
                    label: 'Candidate / Registration Number',
                    hint: 'e.g. 4123456789',
                    keyboardType: TextInputType.text,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Amount display card
                  if (_selectedExam != null)
                    _AmountDisplay(
                      label: _selectedExam!.name,
                      amount: _selectedExam!.price,
                      description: _selectedExam!.description,
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _EduCTA(enabled: _isFormValid, exam: _selectedExam, onTap: _handleNext),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final String? subLabel;
  final bool enabled;
  final VoidCallback onTap;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.subLabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: subLabel != null ? 72 : 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? AppColors.goldPrimary.withOpacity(0.4)
                : enabled
                    ? Theme.of(context).dividerColor
                    : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: hasValue ? AppColors.goldPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue ? Theme.of(context).colorScheme.onSurface : Theme.of(context).dividerColor,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(subLabel!, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: enabled ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4) : Theme.of(context).dividerColor),
          ],
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  final String label;
  final String amount;
  final String description;

  const _AmountDisplay({required this.label, required this.amount, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF166C46).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF166C46).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, color: Color(0xFF166C46), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                Text(description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
          Text(
            '₦$amount',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF166C46)),
          ),
        ],
      ),
    );
  }
}

class _ProviderSheet extends StatelessWidget {
  final List<_EduProvider> providers;
  final _EduProvider? selected;
  final void Function(_EduProvider) onSelect;

  const _ProviderSheet({required this.providers, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(999))),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Exam Body', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
          ),
          const SizedBox(height: 16),
          ...providers.map((p) => GestureDetector(
            onTap: () => onSelect(p),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected?.id == p.id ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected?.id == p.id ? Color(0xFF166C46).withOpacity(0.4) : Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Text(p.icon, style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                        Text(p.description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  if (selected?.id == p.id)
                    const Icon(Icons.check_circle, color: Color(0xFF166C46), size: 20),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _ExamSheet extends StatelessWidget {
  final List<_EduExamType> examTypes;
  final _EduExamType? selected;
  final void Function(_EduExamType) onSelect;

  const _ExamSheet({required this.examTypes, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(999))),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Exam Type', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
          ),
          const SizedBox(height: 16),
          ...examTypes.map((e) => GestureDetector(
            onTap: () => onSelect(e),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected?.id == e.id ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected?.id == e.id ? Color(0xFF166C46).withOpacity(0.4) : Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                        Text(e.description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₦${e.price}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                      if (selected?.id == e.id)
                        const Icon(Icons.check_circle, color: Color(0xFF166C46), size: 16),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _EduCTA extends StatelessWidget {
  final bool enabled;
  final _EduExamType? exam;
  final VoidCallback? onTap;

  const _EduCTA({required this.enabled, this.exam, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = exam != null ? 'Pay ₦${exam!.price} — ${exam!.name}' : 'Continue';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).scaffoldBackgroundColor)),
      ),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? AppColors.goldGradient
                : null,
            color: enabled ? null : Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
          ),
        ),
      ),
    );
  }
}
