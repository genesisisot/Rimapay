import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SourceOfIncomeScreen extends StatefulWidget {
  const SourceOfIncomeScreen({super.key});

  @override
  State<SourceOfIncomeScreen> createState() => _SourceOfIncomeScreenState();
}

class _SourceOfIncomeScreenState extends State<SourceOfIncomeScreen> {
  String? _occupation;
  String? _annualIncome;

  final List<String> _occupations = [
    'Farmer',
    'Business man/woman',
    'Civil servant',
    'Teacher',
    'Healthcare worker',
    'Engineer',
    'Others'
  ];

  final List<String> _incomes = [
    'Below ₦100,000',
    '₦100,000 - ₦500,000',
    '₦500,000 - ₦1,000,000',
    'Above ₦1,000,000'
  ];

  Widget _sectionLabel(String label) {
    return Text(label,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)));
  }

  Widget _dropdownField({
    required String? value,
    required String hint,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 14,
                  color: value != null
                      ? const Color(0xFF111827)
                      : const Color(0xFFD1D5DB),
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), size: 20),
          ],
        ),
      ),
    );
  }

  void _showSuccessAndPop() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _CompletionSuccessScreen(
          title: 'Source of Income',
          message: 'Your income details have been saved successfully.',
          onComplete: () {
            context.pop(true);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showOptionsSheet(
      String title, List<String> options, void Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    title: Text(option,
                        style: TextStyle(
                            fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                    onTap: () {
                      onSelect(option);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back_ios_new,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), size: 18),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Source of Income',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '11/12',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Provide details of your source of income',
                        style:
                            TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
                    const SizedBox(height: 24),
                    _sectionLabel('Occupation'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showOptionsSheet('Occupation', _occupations,
                          (v) => setState(() => _occupation = v)),
                      child: _dropdownField(
                          value: _occupation, hint: 'Select your occupation'),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Annual Income'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showOptionsSheet('Annual Income', _incomes,
                          (v) => setState(() => _annualIncome = v)),
                      child: _dropdownField(
                          value: _annualIncome,
                          hint: 'Select your annual income'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildCTA() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          if (_occupation == null || _annualIncome == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select occupation and income'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _showSuccessAndPop();
        },
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF166C46), Color(0xFF0B4F2F)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Continue →',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).cardColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionSuccessScreen extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onComplete;

  const _CompletionSuccessScreen({
    required this.title,
    required this.message,
    this.onComplete,
  });

  @override
  State<_CompletionSuccessScreen> createState() =>
      _CompletionSuccessScreenState();
}

class _CompletionSuccessScreenState extends State<_CompletionSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF166C46),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle,
                    color: Theme.of(context).cardColor, size: 60),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).cardColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            const Spacer(),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
