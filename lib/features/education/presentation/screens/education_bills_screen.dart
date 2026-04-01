import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _EduProvider {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<_EduExamType> examTypes;

  const _EduProvider({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.examTypes,
  });
}

class _EduExamType {
  final String id;
  final String name;
  final String price;
  final String description;

  const _EduExamType({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class EducationBillsScreen extends StatefulWidget {
  const EducationBillsScreen({super.key});

  @override
  State<EducationBillsScreen> createState() => _EducationBillsScreenState();
}

class _EducationBillsScreenState extends State<EducationBillsScreen> {
  _EduProvider? _selectedProvider;
  _EduExamType? _selectedExam;
  final _candidateController = TextEditingController();
  final _candidateFocus = FocusNode();

  final List<_EduProvider> _providers = const [
    _EduProvider(
      id: 'waec',
      name: 'WAEC',
      description: 'West African Examinations Council',
      icon: '🎓',
      examTypes: [
        _EduExamType(id: 'wassce', name: 'WASSCE', price: '24500', description: 'West African Senior School Certificate'),
        _EduExamType(id: 'gce', name: 'GCE (Private)', price: '21700', description: 'General Certificate of Education'),
        _EduExamType(id: 'result', name: 'Result Checker', price: '1000', description: 'Check your WAEC results online'),
      ],
    ),
    _EduProvider(
      id: 'jamb',
      name: 'JAMB',
      description: 'Joint Admissions & Matriculation Board',
      icon: '📚',
      examTypes: [
        _EduExamType(id: 'utme', name: 'UTME Registration', price: '7700', description: 'Unified Tertiary Matriculation Exam'),
        _EduExamType(id: 'de', name: 'Direct Entry', price: '5000', description: 'For degree holders seeking admission'),
        _EduExamType(id: 'mock', name: 'Mock Examination', price: '2000', description: 'JAMB mock examination fee'),
        _EduExamType(id: 'change', name: 'Change of Course', price: '2500', description: 'Change institution or course'),
      ],
    ),
    _EduProvider(
      id: 'neco',
      name: 'NECO',
      description: 'National Examinations Council',
      icon: '📝',
      examTypes: [
        _EduExamType(id: 'ssce', name: 'SSCE (Internal)', price: '17900', description: 'Senior Secondary Certificate Exam'),
        _EduExamType(id: 'gce_neco', name: 'GCE (External)', price: '15000', description: 'General Certificate of Education'),
        _EduExamType(id: 'result_neco', name: 'Result Checker', price: '700', description: 'Check NECO results online'),
      ],
    ),
    _EduProvider(
      id: 'nabteb',
      name: 'NABTEB',
      description: 'National Business & Technical Exams Board',
      icon: '🔧',
      examTypes: [
        _EduExamType(id: 'nbc', name: 'NBC Examination', price: '14500', description: 'National Business Certificate'),
        _EduExamType(id: 'ntc', name: 'NTC Examination', price: '14500', description: 'National Technical Certificate'),
      ],
    ),
  ];

  bool get _isFormValid =>
      _selectedProvider != null &&
      _selectedExam != null &&
      _candidateController.text.length >= 6;

  void _handleNext() {
    if (!_isFormValid) return;
    showPinConfirmSheet(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Education'},
        {'label': 'Provider', 'value': _selectedProvider!.name},
        {'label': 'Exam Type', 'value': _selectedExam!.name},
        {'label': 'Candidate No.', 'value': _candidateController.text},
        {'label': 'Amount', 'value': '₦${_selectedExam!.price}'},
      ],
      onConfirmed: (_) {
        Navigator.pop(context);
        context.pushReplacement('/success', extra: SuccessScreenProps(
          transactionType: '${_selectedProvider!.name} — ${_selectedExam!.name}',
          amount: _selectedExam!.price,
          recipient: _candidateController.text,
        ));
      },
    );
  }

  void _openProviderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProviderSheet(
        providers: _providers,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExamSheet(
        examTypes: _selectedProvider!.examTypes,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                    hint: 'Select exam body',
                    onTap: _openProviderSheet,
                  ),
                  const SizedBox(height: 16),

                  // Exam type selector
                  _DropdownField(
                    label: 'Exam Type',
                    value: _selectedExam?.name,
                    hint: _selectedProvider == null ? 'Select exam body first' : 'Select exam type',
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? const Color(0xFF00B252).withOpacity(0.4)
                : enabled
                    ? const Color(0xFFE4E7EC)
                    : const Color(0xFFF3F4F6),
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
                      color: hasValue ? const Color(0xFF00B252) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue ? const Color(0xFF101828) : const Color(0xFFD0D5DD),
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(subLabel!, style: const TextStyle(fontSize: 11, color: Color(0xFF667085))),
                  ],
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: enabled ? const Color(0xFF9CA3AF) : const Color(0xFFD0D5DD)),
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
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00B252).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00B252).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, color: Color(0xFF00B252), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF101828))),
                Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
              ],
            ),
          ),
          Text(
            '₦$amount',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF00B252)),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: const Color(0xFFE4E7EC), borderRadius: BorderRadius.circular(999))),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Exam Body', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF101828))),
          ),
          const SizedBox(height: 16),
          ...providers.map((p) => GestureDetector(
            onTap: () => onSelect(p),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected?.id == p.id ? const Color(0xFFECFDF5) : const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected?.id == p.id ? const Color(0xFF00B252).withOpacity(0.4) : const Color(0xFFE4E7EC),
                ),
              ),
              child: Row(
                children: [
                  Text(p.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
                        Text(p.description, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
                      ],
                    ),
                  ),
                  if (selected?.id == p.id)
                    const Icon(Icons.check_circle, color: Color(0xFF00B252), size: 20),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: const Color(0xFFE4E7EC), borderRadius: BorderRadius.circular(999))),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Exam Type', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF101828))),
          ),
          const SizedBox(height: 16),
          ...examTypes.map((e) => GestureDetector(
            onTap: () => onSelect(e),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected?.id == e.id ? const Color(0xFFECFDF5) : const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected?.id == e.id ? const Color(0xFF00B252).withOpacity(0.4) : const Color(0xFFE4E7EC),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
                        Text(e.description, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₦${e.price}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF101828))),
                      if (selected?.id == e.id)
                        const Icon(Icons.check_circle, color: Color(0xFF00B252), size: 16),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(colors: [Color(0xFF00B252), Color(0xFF00A651)], begin: Alignment.centerLeft, end: Alignment.centerRight)
                : null,
            color: enabled ? null : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : const Color(0xFF9CA3AF))),
          ),
        ),
      ),
    );
  }
}
