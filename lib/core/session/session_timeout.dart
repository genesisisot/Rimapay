import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/l10n.dart';

/// Signs the user out after a period without interaction — standard for
/// banking apps, so an unlocked phone or an open browser tab doesn't leave
/// the account exposed.
///
/// - Any tap, scroll or key press restarts the countdown.
/// - [warningBefore] the end, a dialog counts down with "Stay signed in".
/// - Time spent in the background counts: coming back after [timeout] signs
///   out immediately.
///
/// Only runs while [isSessionActive] is true (signed in, not on a public
/// screen such as login or onboarding).
class SessionTimeout extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final Duration warningBefore;
  final bool Function() isSessionActive;
  final Future<void> Function() onExpire;

  /// Context below the app's Navigator, for showing the warning dialog.
  final BuildContext? Function() navigatorContext;

  const SessionTimeout({
    super.key,
    required this.child,
    required this.isSessionActive,
    required this.onExpire,
    required this.navigatorContext,
    this.timeout = const Duration(minutes: 5),
    this.warningBefore = const Duration(seconds: 30),
  });

  @override
  State<SessionTimeout> createState() => _SessionTimeoutState();
}

class _SessionTimeoutState extends State<SessionTimeout>
    with WidgetsBindingObserver {
  Timer? _warnTimer;
  DateTime _lastActivity = DateTime.now();
  bool _warning = false;
  bool _expiring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _warnTimer?.cancel();
    super.dispose();
  }

  bool _onKey(KeyEvent _) {
    _activity();
    return false; // never consume the key
  }

  /// User did something: restart the countdown (ignored while the warning is
  /// up — only its buttons decide).
  void _activity() {
    if (_warning || _expiring) return;
    _lastActivity = DateTime.now();
    _restart();
  }

  void _restart() {
    _warnTimer?.cancel();
    final untilWarning = widget.timeout - widget.warningBefore;
    _warnTimer = Timer(untilWarning, _showWarning);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Timers don't run reliably in the background; judge by the clock.
      if (widget.isSessionActive() &&
          DateTime.now().difference(_lastActivity) >= widget.timeout) {
        _expire();
      } else if (!_warning) {
        _restart();
      }
    }
  }

  Future<void> _showWarning() async {
    if (!widget.isSessionActive()) {
      _restart(); // not signed in yet — keep watching quietly
      return;
    }
    final ctx = widget.navigatorContext();
    if (ctx == null || !ctx.mounted) {
      _restart();
      return;
    }
    _warning = true;
    final stay = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _SessionWarningDialog(seconds: widget.warningBefore.inSeconds),
    );
    _warning = false;
    if (!mounted || _expiring) return;
    if (stay == true) {
      _lastActivity = DateTime.now();
      _restart();
    } else {
      await _expire(alreadyClosed: true);
    }
  }

  Future<void> _expire({bool alreadyClosed = false}) async {
    if (_expiring) return;
    _expiring = true;
    _warnTimer?.cancel();
    final ctx = widget.navigatorContext();
    if (!alreadyClosed && _warning && ctx != null && ctx.mounted) {
      Navigator.of(ctx, rootNavigator: true).pop(false);
    }
    try {
      await widget.onExpire();
    } finally {
      _expiring = false;
      _warning = false;
      _lastActivity = DateTime.now();
      if (mounted) _restart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _activity(),
      onPointerSignal: (_) => _activity(),
      child: widget.child,
    );
  }
}

/// "Still there?" with a live countdown. Pops `true` to stay, `false` (or
/// when the count hits zero) to sign out.
class _SessionWarningDialog extends StatefulWidget {
  final int seconds;

  const _SessionWarningDialog({required this.seconds});

  @override
  State<_SessionWarningDialog> createState() => _SessionWarningDialogState();
}

class _SessionWarningDialogState extends State<_SessionWarningDialog> {
  late int _left = widget.seconds;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_left <= 1) {
        _tick?.cancel();
        Navigator.of(context).pop(false);
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      icon: const Icon(Icons.lock_clock_rounded,
          size: 36, color: Color(0xFF166C46)),
      title: Text(l10n.sessionExpiringTitle, textAlign: TextAlign.center),
      content: Text(
        l10n.sessionExpiringBody(_left),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.logOut),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF166C46)),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.staySignedIn),
        ),
      ],
    );
  }
}
