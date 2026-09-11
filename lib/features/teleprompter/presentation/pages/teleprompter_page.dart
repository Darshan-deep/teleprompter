import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/keep_awake_service.dart';
import '../../../../core/theme/prompt_palette.dart';
import '../../domain/entities/teleprompter_settings.dart';
import '../../domain/usecases/compute_scroll_speed.dart';
import '../bloc/app_settings_cubit.dart';
import '../bloc/teleprompter_cubit.dart';
import '../bloc/teleprompter_state.dart';
import '../engine/text_scroll_controller.dart';
import '../widgets/prompt_text_view.dart';
import '../widgets/prompter_controls.dart';
import '../widgets/prompter_shortcuts.dart';
import '../widgets/reading_guide.dart';
import '../widgets/script_style_sheet.dart';

/// The teleprompter itself: a full-screen, distraction-free reading surface.
class TeleprompterPage extends StatefulWidget {
  const TeleprompterPage({required this.scriptId, super.key});

  /// Kept so a failed load can be retried without another round trip through
  /// the cubit state.
  final String scriptId;

  @override
  State<TeleprompterPage> createState() => _TeleprompterPageState();
}

class _TeleprompterPageState extends State<TeleprompterPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final TextScrollController _engine;
  final ValueNotifier<bool> _controlsVisible = ValueNotifier<bool>(true);

  Timer? _hideTimer;
  Timer? _resumeTimer;
  TeleprompterSettings? _lastSettings;
  bool _wasPlayingBeforeDrag = false;
  bool _completionDismissed = false;
  bool _controlsWereVisibleOnPointerDown = false;

  @override
  void initState() {
    super.initState();
    _engine = TextScrollController(vsync: this)
      ..onCompleted = _handleEndReached;
    WidgetsBinding.instance.addObserver(this);
    _enterImmersiveMode();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _resumeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _exitImmersiveMode();
    _engine.dispose();
    _controlsVisible.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ app lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    // Sending the app to the background mid-read pauses the session so the
    // reader comes back to the same place instead of a script that ran on.
    final TeleprompterCubit cubit = context.read<TeleprompterCubit>();
    if (cubit.state.isRunning) cubit.pause();
  }

  @override
  void didChangeMetrics() {
    // Rotation / window resize: keep the reader's place in the script.
    _preserveReadingPosition();
  }

  void _enterImmersiveMode() {
    // The prompter is a full-screen tool: chrome from the OS would compete with
    // the text. Failures are ignored (desktop and web simply do nothing).
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } on Object {
      // Not supported on this platform — carry on.
    }
  }

  void _exitImmersiveMode() {
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } on Object {
      // Not supported on this platform — carry on.
    }
  }

  // ------------------------------------------------------------------ engine

  void _handleEndReached() {
    if (!mounted) return;
    context.read<TeleprompterCubit>().complete();
    _showControls(autoHide: false);
  }

  void _syncEngine(TeleprompterState state) {
    _engine.setPixelsPerSecond(state.pixelsPerSecond());

    if (state.isRunning) {
      if (!_engine.isPlaying) {
        if (_engine.isScrollable && _engine.isAtEnd) {
          _engine.restart();
        } else {
          _engine.play();
        }
      }
      _scheduleHide();
      return;
    }

    if (_engine.isPlaying) _engine.pause();
    // Paused, ready or finished: leave the controls up so the reader can act.
    _showControls(autoHide: false);
  }

  void _preserveReadingPosition() {
    final double fraction = _engine.currentFraction;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _engine.seekToFraction(fraction);
    });
  }

  /// Settings changed while reading (size, spacing, font): hold the reader's
  /// place in the script even though the pixel geometry changed.
  void _handleSettingsChanged(TeleprompterState state) {
    if (_lastSettings == state.settings) return;
    _lastSettings = state.settings;
    _preserveReadingPosition();
  }

  // ---------------------------------------------------------------- controls

  void _showControls({bool autoHide = true}) {
    _controlsVisible.value = true;
    _hideTimer?.cancel();
    if (autoHide) _scheduleHide();
  }

  void _hideControls() {
    _hideTimer?.cancel();
    _controlsVisible.value = false;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(AppSpacing.controlsAutoHide, () {
      if (mounted) _controlsVisible.value = false;
    });
  }

  /// Reveals the controls the instant a finger touches the screen.
  ///
  /// This runs from a raw [Listener], not from the gesture detector: with a
  /// double-tap handler in the arena (pause/resume), even `onTapDown` is
  /// withheld for the ~300 ms double-tap window. A raw pointer-down is
  /// immediate, and only *hiding* waits for a confirmed single tap.
  void _handlePointerDown() {
    _controlsWereVisibleOnPointerDown = _controlsVisible.value;
    if (_controlsVisible.value) return;
    _showControls(autoHide: context.read<TeleprompterCubit>().state.isRunning);
  }

  /// A confirmed single tap (i.e. not the first half of a double tap) hides the
  /// controls if they were already on screen.
  void _handleTap() {
    if (_controlsWereVisibleOnPointerDown) _hideControls();
  }

  void _togglePlayback() {
    _showControls();
    context.read<TeleprompterCubit>().togglePlayback();
  }

  void _stepSpeed(int direction) {
    _showControls();
    context.read<TeleprompterCubit>().adjustSpeed(direction * TeleprompterSpeedBounds.step);
  }

  void _restart() {
    _engine.restart();
    context.read<TeleprompterCubit>().restart();
    _showControls();
  }

  void _exit() {
    // Close the session down before the route animates away: the engine stops
    // ticking, the state machine returns to `ready` and the keep-awake flag is
    // released by [KeepAwakeScope] on dispose.
    context.read<TeleprompterCubit>().stop();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _openSettings(TeleprompterState state) async {
    final TeleprompterCubit cubit = context.read<TeleprompterCubit>();
    final AppSettingsCubit appSettings = context.read<AppSettingsCubit>();

    await showScriptStyleSheet(
      context: context,
      settings: state.settings,
      title: 'Prompter settings',
      subtitle: 'Applies to this session',
      onChanged: cubit.applySettings,
      onReset: cubit.resetToDefaults,
      footer: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: OutlinedButton.icon(
          onPressed: () {
            appSettings.updateTeleprompter(cubit.state.settings, immediate: true);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
          label: const Text('Save as my defaults'),
        ),
      ),
    );
  }

  /// Swipe up/down hands control to the reader; auto-scroll resumes shortly
  /// after they let go so reading never stalls.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification && notification.dragDetails != null) {
      _resumeTimer?.cancel();
      _wasPlayingBeforeDrag = _engine.isPlaying;
      _engine.pauseForInteraction();
      _showControls();
      return false;
    }

    if (notification is ScrollEndNotification && notification.dragDetails != null) {
      if (_wasPlayingBeforeDrag) {
        _resumeTimer?.cancel();
        _resumeTimer = Timer(AppSpacing.resumeAfterDrag, () {
          if (!mounted) return;
          // Adopt the position the reader dragged to before continuing.
          _engine.seekToFraction(_engine.currentFraction);
          _engine.resumeAfterInteraction();
          _showControls();
        });
      }
      _wasPlayingBeforeDrag = false;
    }
    return false;
  }

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeleprompterCubit, TeleprompterState>(
      listener: (BuildContext context, TeleprompterState state) {
        _handleSettingsChanged(state);
        _syncEngine(state);
        if (!state.isCompleted && _completionDismissed) {
          setState(() => _completionDismissed = false);
        }
      },
      builder: (BuildContext context, TeleprompterState state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _engine.syncLayout();
        });

        final bool keepAwake =
            context.watch<AppSettingsCubit>().state.settings.keepScreenAwake;

        return KeepAwakeScope(
          enabled: keepAwake,
          child: PrompterShortcuts(
            onTogglePlayback: _togglePlayback,
            onSpeedStep: _stepSpeed,
            onRestart: _restart,
            onToggleMirror: context.read<TeleprompterCubit>().toggleMirror,
            onToggleGuide: context.read<TeleprompterCubit>().toggleReadingGuide,
            onExit: _exit,
            child: _surface(context, state),
          ),
        );
      },
    );
  }

  Widget _surface(BuildContext context, TeleprompterState state) {
    final PromptPalette palette = state.palette;
    final PrompterChrome chrome = PrompterChrome.forCanvas(isDark: palette.isDark);

    if (state.isLoading || state.status == TeleprompterStatus.initial) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(child: CircularProgressIndicator(color: palette.foreground)),
      );
    }

    if (state.status == TeleprompterStatus.error) {
      return Scaffold(
        backgroundColor: palette.background,
        body: _ErrorState(
          failureMessage: state.failure?.message,
          onExit: _exit,
          scriptId: widget.scriptId,
        ),
      );
    }

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final bool compact = screenHeight < AppSpacing.compactHeightBreakpoint + 60;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: _readingSurface(context, state, palette)),
          Positioned.fill(
            child: ReadingGuide(
              color: palette.foreground,
              visible: state.settings.showReadingGuide,
            ),
          ),
          // Gesture layer: tap toggles the controls, double tap pauses/resumes.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _handlePointerDown(),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _handleTap,
                onDoubleTap: _togglePlayback,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _engine,
                builder: (BuildContext context, double progress, Widget? child) =>
                    Align(
                  alignment: Alignment.bottomCenter,
                  child: _ProgressLine(progress: progress, chrome: chrome),
                ),
              ),
            ),
          ),
          if (state.isCompleted && !_completionDismissed)
            Positioned.fill(
              child: _CompletedOverlay(
                chrome: chrome,
                onRestart: _restart,
                onExit: _exit,
                onDismiss: () => setState(() => _completionDismissed = true),
              ),
            ),
          // Controls and top bar share one visibility signal.
          ValueListenableBuilder<bool>(
            valueListenable: _controlsVisible,
            builder: (BuildContext context, bool visible, Widget? child) {
              return IgnorePointer(
                ignoring: !visible,
                child: Stack(
                  children: <Widget>[
                    _TopBar(
                      chrome: chrome,
                      visible: visible,
                      title: state.title,
                      progressListenable: _engine,
                      onExit: _exit,
                      onRestart: _restart,
                      onOpenSettings: () => _openSettings(state),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedSlide(
                        duration: AppSpacing.fast,
                        curve: Curves.easeOutCubic,
                        offset: visible ? Offset.zero : const Offset(0, 0.25),
                        child: AnimatedOpacity(
                          duration: AppSpacing.fast,
                          opacity: visible ? 1 : 0,
                          child: PrompterControls(
                            settings: state.settings,
                            isRunning: state.isRunning,
                            chrome: chrome,
                            compact: compact,
                            onSpeedChanged: context.read<TeleprompterCubit>().setSpeed,
                            onSpeedStep: _stepSpeed,
                            onTogglePlayback: _togglePlayback,
                            onRestart: _restart,
                            onFontSizeChanged:
                                context.read<TeleprompterCubit>().setFontSize,
                            onToggleMirror:
                                context.read<TeleprompterCubit>().toggleMirror,
                            onToggleGuide:
                                context.read<TeleprompterCubit>().toggleReadingGuide,
                            onOpenSettings: () => _openSettings(state),
                            onExit: _exit,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _readingSurface(
    BuildContext context,
    TeleprompterState state,
    PromptPalette palette,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight = constraints.maxHeight;
        final double lineBox = state.settings.fontSize * state.settings.lineHeight;
        final double guideY = viewportHeight * PrompterLayout.readingLineFraction;

        // The first line starts exactly on the guide, and the last line can
        // travel all the way up to it — so a short script is readable
        // immediately and a long one ends without an awkward jump.
        final double leadIn = (guideY - lineBox / 2).clamp(0.0, double.infinity);
        final double tailOut = viewportHeight - guideY + lineBox;

        return NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: SingleChildScrollView(
            controller: _engine.scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: leadIn, bottom: tailOut),
              child: MediaQuery.withNoTextScaling(
                child: PromptSemantics(
                  content: state.script?.content ?? '',
                  child: PromptTextView(
                    content: state.script?.content ?? '',
                    settings: state.settings,
                    textColor: palette.foreground,
                    horizontalPadding:
                        PrompterLayout.horizontalPaddingFor(constraints.maxWidth),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress, required this.chrome});

  final double progress;
  final PrompterChrome chrome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusPill),
        ),
        child: SizedBox(
          height: 3,
          // Same trap as the reading guide: a height-only box inside a loose
          // constraint would collapse to zero width and never paint.
          width: double.infinity,
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            backgroundColor: chrome.foreground.withValues(alpha: 0.14),
            valueColor: AlwaysStoppedAnimation<Color>(chrome.accent),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.chrome,
    required this.visible,
    required this.title,
    required this.progressListenable,
    required this.onExit,
    required this.onRestart,
    required this.onOpenSettings,
  });

  final PrompterChrome chrome;
  final bool visible;
  final String title;
  final ValueListenable<double> progressListenable;
  final VoidCallback onExit;
  final VoidCallback onRestart;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedSlide(
        duration: AppSpacing.fast,
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, -0.25),
        child: AnimatedOpacity(
          duration: AppSpacing.fast,
          opacity: visible ? 1 : 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: chrome.panel,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: chrome.border, width: AppSpacing.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: <Widget>[
                      _TopBarButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Exit prompter',
                        chrome: chrome,
                        onPressed: onExit,
                      ),
                      _TopBarButton(
                        icon: Icons.restart_alt_rounded,
                        tooltip: 'Restart',
                        chrome: chrome,
                        onPressed: onRestart,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: chrome.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ValueListenableBuilder<double>(
                        valueListenable: progressListenable,
                        builder: (BuildContext context, double progress, Widget? child) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: chrome.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _TopBarButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Prompter settings',
                        chrome: chrome,
                        onPressed: onOpenSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({
    required this.icon,
    required this.tooltip,
    required this.chrome,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final PrompterChrome chrome;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: chrome.foreground),
          ),
        ),
      ),
    );
  }
}

class _CompletedOverlay extends StatelessWidget {
  const _CompletedOverlay({
    required this.chrome,
    required this.onRestart,
    required this.onExit,
    required this.onDismiss,
  });

  final PrompterChrome chrome;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  /// Tapping outside keeps the finished script on screen (people often want to
  /// scroll back over the last lines) instead of forcing a choice.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: chrome.panel,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: chrome.border, width: AppSpacing.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.check_circle_outline_rounded,
                        color: chrome.accent, size: 30),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "That's the whole script",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: chrome.foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'You read to the end. Restart, or leave the prompter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: chrome.muted, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onRestart,
                            icon: const Icon(Icons.restart_alt_rounded, size: 18),
                            label: const Text('Restart'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: chrome.foreground,
                              side: BorderSide(color: chrome.border),
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onExit,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Done'),
                            style: FilledButton.styleFrom(
                              backgroundColor: chrome.accent,
                              foregroundColor: chrome.accentForeground,
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.failureMessage,
    required this.onExit,
    required this.scriptId,
  });

  final String? failureMessage;
  final VoidCallback onExit;
  final String scriptId;

  @override
  Widget build(BuildContext context) {
    final TeleprompterCubit cubit = context.read<TeleprompterCubit>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 34, color: Colors.white70),
            const SizedBox(height: AppSpacing.lg),
            Text(
              failureMessage ?? 'This script could not be opened.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  onPressed: onExit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  child: const Text('Back'),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton(
                  onPressed: () => cubit.retry(scriptId),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
