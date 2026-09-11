import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../../core/utils/text_metrics.dart';
import '../bloc/script_editor_state.dart';

/// Live word/character/read-time readout plus the auto-save status.
///
/// Kept as one compact row above the toolbar so the writer always knows where
/// they stand without the numbers competing with the script itself.
class EditorStatsBar extends StatelessWidget {
  const EditorStatsBar({required this.state, super.key});

  final ScriptEditorState state;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _Stat(
                    value: '${state.wordCount}',
                    label: _plural(state.wordCount, 'word'),
                  ),
                  _divider(colors),
                  _Stat(
                    value: '${state.characterCount}',
                    label: _plural(state.characterCount, 'character'),
                  ),
                  _divider(colors),
                  _Stat(
                    value: '${state.paragraphCount}',
                    label: _plural(state.paragraphCount, 'paragraph'),
                  ),
                  if (state.wordCount > 0) ...<Widget>[
                    _divider(colors),
                    _Stat(
                      value: TextMetrics.formatReadTime(state.readTime),
                      label: 'read',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _SaveStatus(state: state),
        ],
      ),
    );
  }

  /// `1 word` / `2 words` — tiny detail, but the readout is on screen constantly.
  static String _plural(int value, String singular) =>
      value == 1 ? singular : '${singular}s';

  Widget _divider(AppColors colors) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(width: AppSpacing.hairline, height: 16, color: colors.outline),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          value,
          style: text.labelLarge?.copyWith(
            color: colors.textPrimary,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: text.bodySmall?.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.state});

  final ScriptEditorState state;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    final (IconData icon, String label, Color color) = switch (state) {
      ScriptEditorState(isSaving: true) => (
          Icons.sync_rounded,
          'Saving…',
          colors.textTertiary,
        ),
      ScriptEditorState(isDirty: true) => (
          Icons.cloud_upload_outlined,
          'Unsaved',
          colors.warning,
        ),
      ScriptEditorState(savedAt: final DateTime savedAt) => (
          Icons.cloud_done_outlined,
          'Saved ${DateTimeFormat.relative(savedAt)}',
          colors.textTertiary,
        ),
      _ => (Icons.cloud_done_outlined, 'Saved', colors.textTertiary),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs + 1),
        Text(label, style: text.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
