import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hardware-keyboard control for the prompter.
///
/// On phones this is inert, but the same build runs on tablets with a keyboard,
/// on desktop and on the web — and a presenter driving a prompter from a laptop
/// should never have to hunt for an on-screen button mid-take.
class PrompterShortcuts extends StatelessWidget {
  const PrompterShortcuts({
    required this.child,
    required this.onTogglePlayback,
    required this.onSpeedStep,
    required this.onRestart,
    required this.onToggleMirror,
    required this.onToggleGuide,
    required this.onExit,
    super.key,
  });

  final Widget child;
  final VoidCallback onTogglePlayback;

  /// +1 faster, −1 slower.
  final ValueChanged<int> onSpeedStep;
  final VoidCallback onRestart;
  final VoidCallback onToggleMirror;
  final VoidCallback onToggleGuide;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): onTogglePlayback,
        const SingleActivator(LogicalKeyboardKey.mediaPlayPause): onTogglePlayback,
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => onSpeedStep(1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => onSpeedStep(1),
        const SingleActivator(LogicalKeyboardKey.equal): () => onSpeedStep(1),
        const SingleActivator(LogicalKeyboardKey.add): () => onSpeedStep(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => onSpeedStep(-1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => onSpeedStep(-1),
        const SingleActivator(LogicalKeyboardKey.minus): () => onSpeedStep(-1),
        const SingleActivator(LogicalKeyboardKey.keyR): onRestart,
        const SingleActivator(LogicalKeyboardKey.keyM): onToggleMirror,
        const SingleActivator(LogicalKeyboardKey.keyG): onToggleGuide,
        const SingleActivator(LogicalKeyboardKey.escape): onExit,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
