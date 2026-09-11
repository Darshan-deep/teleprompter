import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps the display on while a prompter session is running.
///
/// Implemented with a tiny platform channel rather than a third-party package:
///
/// * Android sets `FLAG_KEEP_SCREEN_ON` on the window;
/// * iOS sets `UIApplication.shared.isIdleTimerDisabled`;
/// * platforms without a handler (web, desktop) resolve to a no-op, and the
///   service stays silent instead of throwing.
abstract interface class KeepAwakeService {
  Future<void> enable();

  Future<void> disable();
}

class ScreenKeepAwakeService implements KeepAwakeService {
  const ScreenKeepAwakeService();

  static const MethodChannel channel = MethodChannel('teleprompter/screen');

  static const String _enableMethod = 'enableKeepAwake';
  static const String _disableMethod = 'disableKeepAwake';

  @override
  Future<void> enable() => _invoke(_enableMethod);

  @override
  Future<void> disable() => _invoke(_disableMethod);

  Future<void> _invoke(String method) async {
    if (kIsWeb) return;
    try {
      await channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Desktop/web builds have no handler — nothing to do.
    } on PlatformException catch (error) {
      debugPrint('KeepAwake: $method failed (${error.code})');
    }
  }
}

/// Enables the keep-awake behaviour for as long as it is mounted, and re-applies
/// it whenever the app returns to the foreground (Android clears the flag when
/// the activity is recreated).
class KeepAwakeScope extends StatefulWidget {
  const KeepAwakeScope({
    required this.enabled,
    required this.child,
    this.service = const ScreenKeepAwakeService(),
    super.key,
  });

  final bool enabled;
  final Widget child;
  final KeepAwakeService service;

  @override
  State<KeepAwakeScope> createState() => _KeepAwakeScopeState();
}

class _KeepAwakeScopeState extends State<KeepAwakeScope> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apply();
  }

  @override
  void didUpdateWidget(covariant KeepAwakeScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _apply();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-assert after returning from the background.
      _apply();
    }
  }

  void _apply() {
    final Future<void> action =
        widget.enabled ? widget.service.enable() : widget.service.disable();
    action.catchError((Object _) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving the prompter always restores normal screen behaviour.
    widget.service.disable().catchError((Object _) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
