import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/script.dart';

/// What the user can do from a card's "more" menu.
enum ScriptCardAction { rename, edit, duplicate, delete }

/// One script in the home list: title, preview, stats, a play button and a
/// secondary-actions menu.
class ScriptCard extends StatelessWidget {
  const ScriptCard({
    required this.script,
    required this.onOpen,
    required this.onPlay,
    required this.onAction,
    this.isBusy = false,
    super.key,
  });

  final Script script;
  final VoidCallback onOpen;
  final VoidCallback onPlay;
  final ValueChanged<ScriptCardAction> onAction;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      script.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      script.isEmpty ? 'Empty script' : script.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: script.isEmpty ? colors.textTertiary : colors.textSecondary,
                        fontStyle: script.isEmpty ? FontStyle.italic : null,
                      ),
                    ),
                  ],
                ),
              ),
              _MoreMenu(onAction: onAction),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    MetaChip(
                      icon: Icons.subject_rounded,
                      label: '${script.wordCount} words',
                    ),
                    if (!script.isEmpty)
                      MetaChip(
                        icon: Icons.schedule_rounded,
                        label: '~${_formatReadTime(script)}',
                      ),
                    MetaChip(
                      icon: Icons.edit_calendar_outlined,
                      label: DateTimeFormat.relative(script.updatedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PlayButton(onPressed: isBusy ? null : onPlay, isBusy: isBusy),
            ],
          ),
        ],
      ),
    );
  }

  String _formatReadTime(Script script) =>
      '${(script.readTime.inSeconds / 60).ceil()} min read';
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed, required this.isBusy});

  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Semantics(
      button: true,
      label: 'Start teleprompter',
      child: Material(
        color: colors.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: isBusy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Icon(Icons.play_arrow_rounded, size: 24, color: colors.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onAction});

  final ValueChanged<ScriptCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return PopupMenuButton<ScriptCardAction>(
      tooltip: 'More options',
      icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary),
      color: colors.surfaceHighest,
      onSelected: onAction,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ScriptCardAction>>[
        _item(ScriptCardAction.rename, Icons.drive_file_rename_outline_rounded, 'Rename'),
        _item(ScriptCardAction.edit, Icons.edit_outlined, 'Edit'),
        _item(ScriptCardAction.duplicate, Icons.copy_rounded, 'Duplicate'),
        const PopupMenuDivider(),
        _item(
          ScriptCardAction.delete,
          Icons.delete_outline_rounded,
          'Delete',
          color: colors.danger,
        ),
      ],
    );
  }

  PopupMenuItem<ScriptCardAction> _item(
    ScriptCardAction value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<ScriptCardAction>(
      value: value,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

/// Placeholder card used while the list loads — same footprint as [ScriptCard]
/// so the layout does not jump when the data arrives.
class ScriptCardSkeleton extends StatelessWidget {
  const ScriptCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          bar(0.55, 18),
          const SizedBox(height: AppSpacing.md),
          bar(0.95, 12),
          const SizedBox(height: AppSpacing.sm),
          bar(0.7, 12),
          const SizedBox(height: AppSpacing.xl),
          bar(0.5, 12),
        ],
      ),
    );
  }
}
