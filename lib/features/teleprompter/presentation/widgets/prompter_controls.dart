import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/script_typography.dart';
import '../../domain/entities/teleprompter_settings.dart';

/// Colours for the prompter chrome, derived from the canvas so the controls stay
/// readable on white paper backgrounds *and* on near-black ones.
@immutable
class PrompterChrome {
  const PrompterChrome({
    required this.panel,
    required this.foreground,
    required this.muted,
    required this.accent,
    required this.accentForeground,
    required this.border,
  });

  factory PrompterChrome.forCanvas({required bool isDark}) {
    if (isDark) {
      return PrompterChrome(
        panel: const Color(0xE6101013),
        foreground: const Color(0xFFF7F7FA),
        muted: const Color(0xFFA0A0AE),
        accent: const Color(0xFF7C8CFF),
        accentForeground: const Color(0xFF0B0B14),
        border: const Color(0x33FFFFFF),
      );
    }
    return PrompterChrome(
      panel: const Color(0xF2FFFFFF),
      foreground: const Color(0xFF14141A),
      muted: const Color(0xFF63636F),
      accent: const Color(0xFF4453E0),
      accentForeground: const Color(0xFFFFFFFF),
      border: const Color(0x1F000000),
    );
  }

  final Color panel;
  final Color foreground;
  final Color muted;
  final Color accent;
  final Color accentForeground;
  final Color border;
}

/// The prompter's control surface.
///
/// Designed to be glanced at, not studied: speed and transport are always in the
/// same place, everything is reachable with one thumb, and the whole panel
/// slides away after a few seconds while reading.
class PrompterControls extends StatelessWidget {
  const PrompterControls({
    required this.settings,
    required this.isRunning,
    required this.chrome,
    required this.compact,
    required this.onSpeedChanged,
    required this.onSpeedStep,
    required this.onTogglePlayback,
    required this.onRestart,
    required this.onFontSizeChanged,
    required this.onToggleMirror,
    required this.onToggleGuide,
    required this.onOpenSettings,
    required this.onExit,
    required this.onToggleRecording,
    required this.isRecording,
    super.key,
  });

  final TeleprompterSettings settings;
  final bool isRunning;
  final PrompterChrome chrome;

  /// Landscape phones / short windows: a single dense row instead of a panel.
  final bool compact;

  final ValueChanged<double> onSpeedChanged;
  /// +1 / −1: a single step of the speed range.
  final ValueChanged<int> onSpeedStep;
  final VoidCallback onTogglePlayback;
  final VoidCallback onRestart;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onToggleMirror;
  final VoidCallback onToggleGuide;
  final VoidCallback onOpenSettings;
  final VoidCallback onExit;
  final VoidCallback onToggleRecording;
  final ValueNotifier<bool> isRecording;

  static const double _fontStep = 2;

  @override
  Widget build(BuildContext context) {
    final Widget content = compact ? _buildCompact(context) : _buildFull(context);

    return Padding(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: chrome.panel,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: chrome.border, width: AppSpacing.hairline),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.md : AppSpacing.lg,
                vertical: compact ? AppSpacing.sm : AppSpacing.md,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- full layout

  Widget _buildFull(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _SpeedRow(
          settings: settings,
          chrome: chrome,
          onSpeedStep: onSpeedStep,
        ),
        const SizedBox(height: AppSpacing.xs),
        _PrompterSlider(
          value: settings.speed,
          min: TeleprompterSettings.minSpeed,
          max: TeleprompterSettings.maxSpeed,
          startLabel: 'Slow',
          endLabel: 'Fast',
          chrome: chrome,
          semanticLabel: 'Scrolling speed',
          onChanged: onSpeedChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            _ChromeIconButton(
              icon: Icons.restart_alt_rounded,
              tooltip: 'Restart from the top',
              chrome: chrome,
              onPressed: onRestart,
            ),
            Expanded(
              child: Center(
                child: _PlayButton(
                  isRunning: isRunning,
                  chrome: chrome,
                  onPressed: onTogglePlayback,
                ),
              ),
            ),
            _ChromeIconButton(
              icon: Icons.text_decrease_rounded,
              tooltip: 'Smaller text',
              chrome: chrome,
              onPressed: settings.fontSize > ScriptTypography.minFontSize
                  ? () => onFontSizeChanged(settings.fontSize - _fontStep)
                  : null,
            ),
            SizedBox(
              width: 44,
              child: Text(
                TeleprompterSettings.fontSizeLabel(settings.fontSize),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: chrome.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
            _ChromeIconButton(
              icon: Icons.text_increase_rounded,
              tooltip: 'Larger text',
              chrome: chrome,
              onPressed: settings.fontSize < ScriptTypography.maxFontSize
                  ? () => onFontSizeChanged(settings.fontSize + _fontStep)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionRow(
          settings: settings,
          chrome: chrome,
          onToggleMirror: onToggleMirror,
          onToggleGuide: onToggleGuide,
          onOpenSettings: onOpenSettings,
          onExit: onExit,
          onToggleRecording: onToggleRecording,
          isRecording: isRecording,
        ),
      ],
    );
  }

  // ----------------------------------------------------------- compact layout

  Widget _buildCompact(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            _ChromeIconButton(
              icon: Icons.remove_rounded,
              tooltip: 'Slower',
              chrome: chrome,
              onPressed: () => onSpeedStep(-1),
            ),
            SizedBox(
              width: 52,
              child: Text(
                settings.speed.toStringAsFixed(2),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: chrome.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
            _ChromeIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Faster',
              chrome: chrome,
              onPressed: () => onSpeedStep(1),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PlayButton(
              isRunning: isRunning,
              chrome: chrome,
              onPressed: onTogglePlayback,
              size: 44,
            ),
            const Spacer(),
            _ChromeIconButton(
              icon: Icons.restart_alt_rounded,
              tooltip: 'Restart',
              chrome: chrome,
              onPressed: onRestart,
            ),
            _ChromeIconButton(
              icon: Icons.flip_rounded,
              tooltip: 'Mirror text',
              chrome: chrome,
              isActive: settings.mirrored,
              onPressed: onToggleMirror,
            ),
            _RecordIconButton(
              chrome: chrome,
              isRecording: isRecording,
              onToggleRecording: onToggleRecording,
            ),
            _ChromeIconButton(
              icon: Icons.tune_rounded,
              tooltip: 'Settings',
              chrome: chrome,
              onPressed: onOpenSettings,
            ),
            _ChromeIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Exit prompter',
              chrome: chrome,
              onPressed: onExit,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _PrompterSlider(
          value: settings.speed,
          min: TeleprompterSettings.minSpeed,
          max: TeleprompterSettings.maxSpeed,
          startLabel: 'Slow',
          endLabel: 'Fast',
          chrome: chrome,
          semanticLabel: 'Scrolling speed',
          onChanged: onSpeedChanged,
        ),
      ],
    );
  }
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow({
    required this.settings,
    required this.chrome,
    required this.onSpeedStep,
  });

  final TeleprompterSettings settings;
  final PrompterChrome chrome;
  final ValueChanged<int> onSpeedStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _ChromeIconButton(
          icon: Icons.remove_rounded,
          tooltip: 'Slower',
          chrome: chrome,
          onPressed: () => onSpeedStep(-1),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Speed  ${settings.speed.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: chrome.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                TeleprompterSettings.speedLabel(settings.speed),
                textAlign: TextAlign.center,
                style: TextStyle(color: chrome.muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
        _ChromeIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Faster',
          chrome: chrome,
          onPressed: () => onSpeedStep(1),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.settings,
    required this.chrome,
    required this.onToggleMirror,
    required this.onToggleGuide,
    required this.onOpenSettings,
    required this.onExit,
    required this.onToggleRecording,
    required this.isRecording,
  });

  final TeleprompterSettings settings;
  final PrompterChrome chrome;
  final VoidCallback onToggleMirror;
  final VoidCallback onToggleGuide;
  final VoidCallback onOpenSettings;
  final VoidCallback onExit;
  final VoidCallback onToggleRecording;
  final ValueNotifier<bool> isRecording;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ChromeChip(
            icon: Icons.flip_rounded,
            label: 'Mirror',
            chrome: chrome,
            isActive: settings.mirrored,
            onPressed: onToggleMirror,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ChromeChip(
            icon: Icons.horizontal_rule_rounded,
            label: 'Guide',
            chrome: chrome,
            isActive: settings.showReadingGuide,
            onPressed: onToggleGuide,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ChromeChip(
            icon: Icons.videocam_rounded,
            label: 'Record',
            chrome: chrome,
            isActive: false,
            onPressed: onToggleRecording,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        
        Expanded(
          child: _ChromeChip(
            icon: Icons.close_rounded,
            label: 'Exit',
            chrome: chrome,
            onPressed: onExit,
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isRunning,
    required this.chrome,
    required this.onPressed,
    this.size = 64,
  });

  final bool isRunning;
  final PrompterChrome chrome;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isRunning ? 'Pause scrolling' : 'Start scrolling',
      child: Material(
        color: chrome.accent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: chrome.accentForeground,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.tooltip,
    required this.chrome,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final PrompterChrome chrome;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color color = onPressed == null
        ? chrome.muted.withValues(alpha: 0.45)
        : (isActive ? chrome.accent : chrome.foreground);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: AppSpacing.minTapTarget - AppSpacing.xs,
            height: AppSpacing.minTapTarget - AppSpacing.xs,
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

class _ChromeChip extends StatelessWidget {
  const _ChromeChip({
    required this.icon,
    required this.label,
    required this.chrome,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final PrompterChrome chrome;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isActive ? chrome.accent : chrome.foreground;

    return Material(
      color: isActive ? chrome.accent.withValues(alpha: 0.16) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: AppSpacing.minTapTarget,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: chrome.border, width: AppSpacing.hairline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: AppSpacing.xs + 2),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prompter slider with end labels and a dark/light aware palette.
class _PrompterSlider extends StatelessWidget {
  const _PrompterSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.startLabel,
    required this.endLabel,
    required this.chrome,
    required this.semanticLabel,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final String startLabel;
  final String endLabel;
  final PrompterChrome chrome;
  final String semanticLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(startLabel, style: TextStyle(color: chrome.muted, fontSize: 11)),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: chrome.accent,
              inactiveTrackColor: chrome.foreground.withValues(alpha: 0.18),
              thumbColor: chrome.accent,
              overlayColor: chrome.accent.withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
              semanticFormatterCallback: (double v) => 'Speed ${v.toStringAsFixed(2)}',
            ),
          ),
        ),
        Text(endLabel, style: TextStyle(color: chrome.muted, fontSize: 11)),
      ],
    );
  }
}


class _RecordIconButton extends StatelessWidget {
  const _RecordIconButton({
    required this.chrome,
    required this.isRecording,
    required this.onToggleRecording,
  });

  final PrompterChrome chrome;
  final ValueNotifier<bool> isRecording;
  final VoidCallback onToggleRecording;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isRecording,
      builder: (context, recording, _) {
        return _ChromeIconButton(
          icon: Icons.videocam_rounded,
          tooltip: recording ? 'Stop recording' : 'Start recording',
          chrome: chrome,
          isActive: recording,
          onPressed: onToggleRecording,
        );
      },
    );
  }
}
