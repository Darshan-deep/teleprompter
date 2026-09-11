import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/script_typography.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/script.dart';
import '../../domain/entities/teleprompter_settings.dart';
import '../bloc/app_settings_cubit.dart';
import '../bloc/script_editor_cubit.dart';
import '../bloc/script_editor_state.dart';
import '../widgets/editor_stats_bar.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/script_style_sheet.dart';
import '../widgets/script_title_field.dart';

/// The writing surface.
///
/// Deliberately not a form: no field borders, no labels competing with the
/// text, auto-save instead of a save dialog — but an explicit Save and Start in
/// the app bar for people who want to be sure.
class ScriptEditorPage extends StatefulWidget {
  const ScriptEditorPage({super.key});

  @override
  State<ScriptEditorPage> createState() => _ScriptEditorPageState();
}

class _ScriptEditorPageState extends State<ScriptEditorPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _contentFocus = FocusNode(debugLabel: 'script-content');
  final UndoHistoryController _undoController = UndoHistoryController();

  bool _seeded = false;
  bool _leaving = false;

  /// The editor renders the script in the prompter's typeface, but at a size
  /// that is comfortable to *write* at — the setup sheet shows a true-size
  /// preview of the real reading appearance.
  static const double _minWritingFontSize = 16;
  static const double _maxWritingFontSize = 30;

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _contentFocus.dispose();
    _undoController.dispose();
    super.dispose();
  }

  void _seedIfReady(ScriptEditorState state) {
    if (_seeded || state.status != ScriptEditorStatus.ready) return;
    _seeded = true;
    _titleController.text = state.title;
    _contentController.text = state.content;
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final ScriptEditorCubit cubit = context.read<ScriptEditorCubit>();
    await cubit.flush();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _save({bool announce = true}) async {
    final ScriptEditorCubit cubit = context.read<ScriptEditorCubit>();
    final Script? saved = await cubit.saveNow(force: true);
    if (!mounted) return;
    if (saved == null) {
      showAppSnackBar(context, 'Could not save this script', icon: Icons.error_outline_rounded);
      return;
    }
    if (announce) {
      showAppSnackBar(context, 'Saved', icon: Icons.check_rounded);
    }
  }

  Future<void> _startTeleprompter() async {
    final ScriptEditorCubit cubit = context.read<ScriptEditorCubit>();
    if (!cubit.state.hasContent) {
      showAppSnackBar(
        context,
        'Add some text before you start reading',
        icon: Icons.info_outline_rounded,
      );
      _contentFocus.requestFocus();
      return;
    }

    final Script? saved = await cubit.saveNow(force: true);
    if (!mounted) return;
    if (saved == null) {
      showAppSnackBar(context, 'Could not save this script', icon: Icons.error_outline_rounded);
      return;
    }
    await context.push(AppRoutes.teleprompter(saved.id));
  }

  void _openSetup(TeleprompterSettings settings) {
    final AppSettingsCubit appSettings = context.read<AppSettingsCubit>();
    showScriptStyleSheet(
      context: context,
      settings: settings,
      title: 'Reading setup',
      subtitle: 'Defaults for every prompter session',
      onChanged: appSettings.updateTeleprompter,
      onReset: () => appSettings.updateTeleprompter(
        const TeleprompterSettings(),
        immediate: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return BlocConsumer<ScriptEditorCubit, ScriptEditorState>(
      listenWhen: (ScriptEditorState previous, ScriptEditorState current) =>
          previous.status != current.status || current.failure != null,
      listener: (BuildContext context, ScriptEditorState state) {
        _seedIfReady(state);
        final failure = state.failure;
        if (failure != null) {
          showAppSnackBar(context, failure.message, icon: Icons.error_outline_rounded);
          context.read<ScriptEditorCubit>().clearFailure();
        }
      },
      builder: (BuildContext context, ScriptEditorState state) {
        _seedIfReady(state);
        final TeleprompterSettings settings =
            context.watch<AppSettingsCubit>().state.settings.teleprompter;

        return PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) return;
            _leave();
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
              const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
              const SingleActivator(LogicalKeyboardKey.enter, control: true):
                  _startTeleprompter,
              const SingleActivator(LogicalKeyboardKey.enter, meta: true):
                  _startTeleprompter,
            },
            child: Focus(
              autofocus: false,
              child: Scaffold(
                backgroundColor: colors.ink,
                appBar: AppBar(
                  leading: AppIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: _leave,
                  ),
                  titleSpacing: 0,
                  title: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ScriptTitleField(
                      controller: _titleController,
                      onChanged: context.read<ScriptEditorCubit>().titleChanged,
                    ),
                  ),
                  actions: <Widget>[
                    _SaveButton(state: state, onPressed: _save),
                    const SizedBox(width: AppSpacing.sm),
                    _StartButton(
                      enabled: state.hasContent,
                      onPressed: _startTeleprompter,
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                ),
                body: _body(context, state, settings),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    ScriptEditorState state,
    TeleprompterSettings settings,
  ) {
    switch (state.status) {
      case ScriptEditorStatus.loading:
        return Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        );

      case ScriptEditorStatus.missing:
        return EmptyState(
          icon: Icons.description_outlined,
          title: 'This script is no longer available',
          message: 'It was deleted, so there is nothing to edit here.',
          actionLabel: 'Create a new script',
          onAction: () => context.pushReplacement(AppRoutes.newScript),
        );

      case ScriptEditorStatus.failure:
        return EmptyState(
          icon: Icons.error_outline_rounded,
          title: "Couldn't open this script",
          message: state.failure?.message,
          actionLabel: 'Try again',
          onAction: () => context.read<ScriptEditorCubit>().load(),
        );

      case ScriptEditorStatus.ready:
        return Column(
          children: <Widget>[
            Expanded(child: _writingSurface(context, settings)),
            EditorStatsBar(state: state),
            EditorToolbar(
              settings: settings,
              onSettingsChanged: (TeleprompterSettings next) =>
                  context.read<AppSettingsCubit>().updateTeleprompter(next),
              onOpenSetup: () => _openSetup(settings),
              canUndo: _undoController.value.canUndo,
              canRedo: _undoController.value.canRedo,
              onUndo: _undoController.undo,
              onRedo: _undoController.redo,
            ),
          ],
        );
    }
  }

  Widget _writingSurface(BuildContext context, TeleprompterSettings settings) {
    final AppColors colors = context.colors;

    final TextStyle style = ScriptTypography.build(
      fontFamily: settings.fontFamily.family,
      fontSize: settings.fontSize.clamp(_minWritingFontSize, _maxWritingFontSize),
      lineHeight: settings.lineHeight,
      color: colors.textPrimary,
      align: settings.alignment,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: TextField(
            key: const ValueKey<String>('editor-content-field'),
            controller: _contentController,
            focusNode: _contentFocus,
            undoController: _undoController,
            onChanged: context.read<ScriptEditorCubit>().contentChanged,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlign: settings.alignment,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: colors.primary,
            scrollPhysics: const ClampingScrollPhysics(),
            style: style,
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText:
                  'Type or paste your script.\n\nLeave a blank line between paragraphs — '
                  'the prompter adds your paragraph spacing there.',
              hintStyle: style.copyWith(
                color: colors.textTertiary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.state, required this.onPressed});

  final ScriptEditorState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    if (state.isSaving) {
      return SizedBox(
        width: AppSpacing.minTapTarget,
        height: AppSpacing.minTapTarget,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
          ),
        ),
      );
    }

    return AppIconButton(
      icon: state.isDirty ? Icons.save_outlined : Icons.check_circle_outline_rounded,
      tooltip: state.isDirty ? 'Save' : 'Saved',
      onPressed: onPressed,
      foreground: state.isDirty ? colors.textPrimary : colors.textTertiary,
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: const Text('Start'),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ),
      ),
    );
  }
}
