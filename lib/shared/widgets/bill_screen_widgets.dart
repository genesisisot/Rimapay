import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'noise_painter.dart';

export 'package:flutter/services.dart' show TextInputFormatter;

/// Shared green gradient header for all bill payment screens.
class BillGreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String>? tabs;
  final int selectedTab;
  final ValueChanged<int>? onTabChanged;
  final bool showAccountCard;

  const BillGreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.tabs,
    this.selectedTab = 0,
    this.onTabChanged,
    this.showAccountCard = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF001a0c),
            Color(0xFF003d1a),
            Color(0xFF005e27),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: NoisePainter(opacity: 0.04, seed: 11),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + title row — padded
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 14,
                  left: 20,
                  right: 20,
                  bottom: 16,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tabs — full width, flush at bottom of header
              if (tabs != null && tabs!.isNotEmpty) ...[
                Row(
                  children: List.generate(tabs!.length, (i) {
                    final isSelected = i == selectedTab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTabChanged?.call(i),
                        child: Container(
                          padding: const EdgeInsets.only(top: 10, bottom: 0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Center(
                              child: Text(
                                tabs![i],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.45),
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],

              // Account card — padded
              if (showAccountCard) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: const _BillAccountCard(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Account balance card used inside the green header (compact, for other bill screens).
class _BillAccountCard extends StatelessWidget {
  const _BillAccountCard();

  @override
  Widget build(BuildContext context) {
    return const BillAccountCard();
  }
}

/// Public account balance card for use in content areas.
/// Dark navy card with CA avatar, account name, and available balance.
class BillAccountCard extends StatelessWidget {
  const BillAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003d1a), Color(0xFF006B2E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Stack(
        children: [
          // Noise texture
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: NoisePainter(opacity: 0.06, seed: 7),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account row
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4B5563),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'CA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '0123456789',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '₦50,000.00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pagination dots for the account card carousel.
class BillPaginationDots extends StatelessWidget {
  final int count;
  final int active;

  const BillPaginationDots({
    super.key,
    this.count = 2,
    this.active = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00B252)
                : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

/// Daily transaction limit card — shown below account card in content area.
class BillDailyLimitCard extends StatelessWidget {
  final double usagePercent;

  const BillDailyLimitCard({super.key, this.usagePercent = 0.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Limit Usage',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                '${(usagePercent * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFff6b35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: usagePercent,
              minHeight: 4,
              backgroundColor: const Color(0xFFD1D5DB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFff6b35)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Limit',
                        style: TextStyle(
                          color: Color(0xFFff6b35),
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '₦50,000.00',
                        style: TextStyle(
                          color: Color(0xFFff6b35),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '₦50,000.00',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped CTA button for bill payment screens.
class BillOrangeCTA extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const BillOrangeCTA({
    super.key,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      color: Colors.white,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFF00B252), Color(0xFF00A651)],
                  )
                : null,
            color: enabled ? null : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple rounded input field — clean, no floating label.
class BillSimpleInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String placeholder;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final Widget? suffix;
  final bool readOnly;

  const BillSimpleInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.placeholder,
    required this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.suffix,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                onChanged: onChanged,
                readOnly: readOnly,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF101828),
                ),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Effra',
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (suffix != null) suffix!,
          ],
        ),
      ),
    );
  }
}

/// Large amount input card with ₦ prefix and min/max hint.
class BillAmountCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final String? minMax;

  const BillAmountCard({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.minMax,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '₦',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF344054),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: onChanged,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF101828),
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        color: Color(0xFFD0D5DD),
                        fontWeight: FontWeight.w300,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (minMax != null) ...[
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    minMax!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Floating label input field with Stack+AnimatedPositioned for proper vertical centering.
class BillFloatingField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final Widget? suffix;
  final bool readOnly;

  const BillFloatingField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.suffix,
    this.readOnly = false,
  });

  @override
  State<BillFloatingField> createState() => _BillFloatingFieldState();
}

class _BillFloatingFieldState extends State<BillFloatingField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  void _onTextChange() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;
    final isActive = _isFocused || hasValue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused
              ? const Color(0xFF00B252)
              : hasValue
                  ? const Color(0xFF00B252).withOpacity(0.4)
                  : const Color(0xFFE4E7EC),
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Floating label
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            left: 14,
            right: widget.suffix != null ? 48 : 14,
            top: isActive ? 9 : 19,
            child: IgnorePointer(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: isActive ? 11 : 15,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF00B252)
                      : const Color(0xFF98A2B3),
                  fontFamily: 'Effra',
                ),
                child: Text(widget.label),
              ),
            ),
          ),
          // TextField — always in tree so taps always register
          Positioned(
            left: 14,
            right: widget.suffix != null ? 48 : 14,
            top: isActive ? 28 : 0,
            bottom: isActive ? 6 : 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                onChanged: widget.onChanged,
                readOnly: widget.readOnly,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101828),
                  fontFamily: 'Effra',
                ),
                decoration: InputDecoration(
                  hintText: isActive ? widget.hint : null,
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFD0D5DD),
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Effra',
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          // Suffix widget
          if (widget.suffix != null)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(child: widget.suffix!),
            ),
        ],
      ),
    );
  }
}

// ── PIN Confirm Bottom Sheet ──────────────────────────────────────────────────

/// Shows a PIN entry + transaction summary bottom sheet.
/// [summary] is a list of label/value pairs shown above the PIN pad.
/// [onConfirmed] is called with the entered PIN when confirmed.
void showPinConfirmSheet({
  required BuildContext context,
  required List<Map<String, String>> summary,
  required void Function(String pin) onConfirmed,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PinConfirmSheet(
      summary: summary,
      onConfirmed: onConfirmed,
    ),
  );
}

class _PinConfirmSheet extends StatefulWidget {
  final List<Map<String, String>> summary;
  final void Function(String pin) onConfirmed;

  const _PinConfirmSheet({
    required this.summary,
    required this.onConfirmed,
  });

  @override
  State<_PinConfirmSheet> createState() => _PinConfirmSheetState();
}

class _PinConfirmSheetState extends State<_PinConfirmSheet> {
  String _pin = '';
  static const int _pinLength = 4;

  void _onKey(String digit) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += digit);
      if (_pin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 150), () {
          widget.onConfirmed(_pin);
        });
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE4E7EC),
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          const Text(
            'Confirm Transaction',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101828),
            ),
          ),

          const SizedBox(height: 20),

          // Transaction summary
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Column(
              children: widget.summary.map((item) {
                final isLast = item == widget.summary.last;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        item['value']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (i) {
              final filled = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? const Color(0xFF00B252)
                      : const Color(0xFFE4E7EC),
                ),
              );
            }),
          ),

          const SizedBox(height: 6),
          const Text(
            'Enter your 4-digit PIN',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),

          const SizedBox(height: 20),

          // Biometrics option
          GestureDetector(
            onTap: () {
              // Biometrics placeholder
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: Color(0xFF00B252),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pay with Biometrics',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00B252),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Number pad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _numRow(['1', '2', '3']),
                const SizedBox(height: 12),
                _numRow(['4', '5', '6']),
                const SizedBox(height: 12),
                _numRow(['7', '8', '9']),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Expanded(child: _numKey('0')),
                    Expanded(
                      child: GestureDetector(
                        onTap: _onDelete,
                        child: const SizedBox(
                          height: 52,
                          child: Center(
                            child: Icon(
                              Icons.backspace_outlined,
                              color: Color(0xFF374151),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numRow(List<String> keys) => Row(
        children: keys.map((k) => Expanded(child: _numKey(k))).toList(),
      );

  Widget _numKey(String digit) => GestureDetector(
        onTap: () => _onKey(digit),
        child: Container(
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
            ),
          ),
        ),
      );
}
