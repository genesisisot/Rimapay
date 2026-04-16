import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResidentialAddressScreen extends StatefulWidget {
  const ResidentialAddressScreen({super.key});

  @override
  State<ResidentialAddressScreen> createState() =>
      _ResidentialAddressScreenState();
}

class _ResidentialAddressScreenState extends State<ResidentialAddressScreen> {
  final _addressController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _areaController = TextEditingController();
  final _stateController = TextEditingController();
  String _selectedState = '';

  final List<String> _states = [
    'Abia',
    'Adamawa',
    'Akwa Ibom',
    'Anambra',
    'Bauchi',
    'Bayelsa',
    'Benue',
    'Borno',
    'Cross River',
    'Delta',
    'Ebonyi',
    'Edo',
    'Ekiti',
    'Enugu',
    'Gombe',
    'Imo',
    'Jigawa',
    'Kaduna',
    'Kano',
    'Katsina',
    'Kebbi',
    'Kogi',
    'Kwara',
    'Lagos',
    'Nasarawa',
    'Niger',
    'Ogun',
    'Ondo',
    'Osun',
    'Oyo',
    'Plateau',
    'Rivers',
    'Sokoto',
    'Taraba',
    'Yobe',
    'Zamfara',
    'FCT'
  ];

  InputDecoration _inputDec({String hint = '', Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: Color(0xFFD1D5DB), fontSize: 14, fontFamily: 'Effra'),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  void _showSuccessAndPop() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _CompletionSuccessScreen(
          title: 'Residential Address',
          message: 'Your address has been saved successfully.',
          onComplete: () {
            context.pop(true); // Pop with result to indicate completion
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _houseNoController.dispose();
    _areaController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Color(0xFF6B7280), size: 18),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Residential Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '9/12',
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
                    const Text('Where do you live?',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.5)),
                    const SizedBox(height: 20),
                    _sectionLabel('Address'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputDec(
                        hint: 'e.g. 15, Adeola Odeku Street',
                        suffix: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.my_location,
                              color: Color(0xFF16A34A), size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('House No.'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _houseNoController,
                                style: const TextStyle(fontSize: 14),
                                decoration: _inputDec(hint: 'No.'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Area / Landmark'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _areaController,
                                style: const TextStyle(fontSize: 14),
                                decoration:
                                    _inputDec(hint: 'e.g. Victoria Island'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sectionLabel('State'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showStatePicker(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _stateController,
                          style: const TextStyle(fontSize: 14),
                          decoration: _inputDec(
                            hint: 'Select state',
                            suffix: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.keyboard_arrow_down,
                                  color: Color(0xFF6B7280)),
                            ),
                          ),
                        ),
                      ),
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

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151)));
  }

  void _showStatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select State',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _states.length,
                itemBuilder: (context, index) {
                  final state = _states[index];
                  return ListTile(
                    title: Text(state,
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xFF111827))),
                    onTap: () {
                      setState(() {
                        _selectedState = state;
                        _stateController.text = state;
                      });
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

  Widget _buildCTA() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _showSuccessAndPop,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF166C46), Color(0xFF0B4F2F)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Continue →',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 60),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
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
