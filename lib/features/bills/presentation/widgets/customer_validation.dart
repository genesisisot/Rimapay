import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/Utils/haptics.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/bills_dtos.dart';

enum ValidationPhase { idle, checking, verified, invalid, unavailable }

/// Debounced meter / smartcard check against `POST bills/validate`.
///
/// Owned by a screen's State. Call [check] whenever the number, biller or item
/// changes and [reset] when the input is incomplete. Replies for a request the
/// user has since edited are dropped, so a slow answer for an old number can
/// never mark the new one as verified.
class CustomerValidator extends ChangeNotifier {
  CustomerValidator(
    this._validate, {
    this.debounce = const Duration(milliseconds: 600),
  });

  final Future<CustomerValidationResult> Function(ValidateCustomerRequest)
      _validate;
  final Duration debounce;

  ValidationPhase _phase = ValidationPhase.idle;
  ValidateCustomerDto? _customer;
  String? _message;
  ValidateCustomerRequest? _request;
  String? _key;
  int _seq = 0;
  Timer? _timer;
  bool _disposed = false;

  ValidationPhase get phase => _phase;
  ValidateCustomerDto? get customer => _customer;
  String? get message => _message;
  bool get isVerified => _phase == ValidationPhase.verified;

  /// Verified customer name, if any.
  String? get customerName => isVerified ? _customer?.fullName : null;

  static String _keyOf(ValidateCustomerRequest r) =>
      '${r.customerId}|${r.billerItemId ?? ''}|${r.paymentCode ?? ''}';

  void check(ValidateCustomerRequest request, {bool immediate = false}) {
    final key = _keyOf(request);
    // Same input already checking or answered: nothing to do (retry clears it).
    if (key == _key && _phase != ValidationPhase.idle) return;
    _key = key;
    _request = request;
    _timer?.cancel();
    final seq = ++_seq;
    _set(ValidationPhase.checking);
    _timer = Timer(immediate ? Duration.zero : debounce, () async {
      final result = await _validate(request);
      if (_disposed || seq != _seq) return;
      _customer = result.customer;
      _message = result.message;
      switch (result.outcome) {
        case CustomerValidationOutcome.verified:
          Haptics.tap();
          _set(ValidationPhase.verified);
        case CustomerValidationOutcome.invalid:
          _set(ValidationPhase.invalid);
        case CustomerValidationOutcome.unavailable:
          _set(ValidationPhase.unavailable);
      }
    });
  }

  void retry() {
    final r = _request;
    if (r == null) return;
    _key = null;
    check(r, immediate: true);
  }

  void reset() {
    _timer?.cancel();
    _seq++;
    _key = null;
    _request = null;
    if (_phase == ValidationPhase.idle && _customer == null) return;
    _customer = null;
    _message = null;
    _set(ValidationPhase.idle);
  }

  void _set(ValidationPhase phase) {
    _phase = phase;
    if (phase == ValidationPhase.checking) {
      _customer = null;
      _message = null;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

/// Inline result under the meter / smartcard field: spinner while checking,
/// the customer's name when verified, or a clear error with Retry.
class CustomerValidationStatus extends StatelessWidget {
  final CustomerValidator validator;
  final String checkingText;
  final String invalidText;

  /// Show the biller's amount due (postpaid meters) when it reports one.
  final bool showAmountDue;

  const CustomerValidationStatus({
    super.key,
    required this.validator,
    required this.checkingText,
    required this.invalidText,
    this.showAmountDue = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: validator,
      builder: (context, _) => AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(validator.phase),
            child: _body(context),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    switch (validator.phase) {
      case ValidationPhase.idle:
        return const SizedBox(width: double.infinity);
      case ValidationPhase.checking:
        return Padding(
          padding: const EdgeInsets.only(top: 10, left: 4),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.goldPrimary),
              ),
              const SizedBox(width: 10),
              Text(checkingText,
                  style: TextStyle(
                      fontSize: 12.5, color: onSurface.withOpacity(0.6))),
            ],
          ),
        );
      case ValidationPhase.verified:
        final c = validator.customer!;
        final due = showAmountDue && (c.amount ?? 0) > 0 ? c.amount : null;
        return _Banner(
          color: AppColors.primary500,
          icon: Icons.verified_rounded,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.customerName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.fullName ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (due != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.l10n.amountDue,
                      style: TextStyle(
                          fontSize: 10.5, color: onSurface.withOpacity(0.5)),
                    ),
                    Text(
                      '₦${NumberFormat('#,##0.00').format(due)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      case ValidationPhase.invalid:
        return _Banner(
          color: AppColors.error,
          icon: Icons.error_outline_rounded,
          child: Text(
            invalidText,
            style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: onSurface.withOpacity(0.8)),
          ),
        );
      case ValidationPhase.unavailable:
        return _Banner(
          color: AppColors.warning,
          icon: Icons.wifi_off_rounded,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.couldNotVerify,
                  style: TextStyle(
                      fontSize: 12.5, color: onSurface.withOpacity(0.8)),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Haptics.press();
                  validator.retry();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.retry,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Widget child;

  const _Banner({required this.color, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
