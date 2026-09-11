import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/prompter_logo.dart';
import '../../../../core/widgets/setting_row.dart';
import '../../domain/entities/script.dart';
import '../bloc/script_list_cubit.dart';
import '../bloc/script_list_state.dart';
import '../dialogs/script_dialogs.dart';
import '../widgets/script_card.dart';

/// Home: the library of scripts plus the primary "start writing" action.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScriptListCubit, ScriptListState>(
      listenWhen: (ScriptListState previous, ScriptListState current) =>
          current.failure != null && previous.failure != current.failure,
      listener: (BuildContext context, ScriptListState state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppSnackBar(
          context,
          failure.message,
          icon: Icons.error_outline_rounded,
        );
        context.read<ScriptListCubit>().clearFailure();
      },
      builder: (BuildContext context, ScriptListState state) {
        final AppColors colors = context.colors;

        return Scaffold(
          backgroundColor: colors.ink,
          appBar: AppBar(
            titleSpacing: AppSpacing.lg,
            title: const _HomeTitle(),
            actions: <Widget>[
              AppIconButton(
                icon: Icons.settings_outlined,
                tooltip: 'Settings',
                onPressed: () => context.push(AppRoutes.settings),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<ScriptListCubit>().refresh(),
            color: colors.primary,
            backgroundColor: colors.surfaceHigh,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: _slivers(context, state),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _slivers(BuildContext context, ScriptListState state) {
    final ScriptListCubit cubit = context.read<ScriptListCubit>();

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        sliver: SliverList(
          delegate: SliverChildListDelegate(<Widget>[
            _NewScriptButton(
              onTap: () => _createScript(context, cubit),
            ),
            if (state.hasScripts)
              SectionLabel(
                'Your scripts',
                trailing: Text(
                  '${state.scripts.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.colors.textTertiary,
                      ),
                ),
              ),
          ]),
        ),
      ),
      if (state.isLoading && !state.hasScripts)
        SliverPadding(
          padding: AppSpacing.screenPadding.copyWith(top: 0, bottom: AppSpacing.xxl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: ScriptCardSkeleton(),
              ),
              childCount: 3,
            ),
          ),
        )
      else if (state.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.description_outlined,
            title: 'Your scripts will appear here.',
            message:
                'Write or paste a script, then read it from the prompter while you record.',
            actionLabel: 'Create your first script',
            onAction: () => _createScript(context, cubit),
          ),
        )
      else
        SliverPadding(
          padding: AppSpacing.screenPadding.copyWith(top: 0, bottom: AppSpacing.xxxl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final Script script = state.scripts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ScriptCard(
                    script: script,
                    isBusy: state.isBusy(script.id),
                    onOpen: () => context.push(AppRoutes.editScript(script.id)),
                    onPlay: () => context.push(AppRoutes.teleprompter(script.id)),
                    onAction: (ScriptCardAction action) =>
                        _handleCardAction(context, cubit, action, script),
                  ),
                );
              },
              childCount: state.scripts.length,
            ),
          ),
        ),
    ];
  }

  /// Creates an empty script up front so there is always something to return to,
  /// then opens the editor on it.
  Future<void> _createScript(BuildContext context, ScriptListCubit cubit) async {
    final Script? created = await cubit.createScript();
    if (!context.mounted || created == null) return;
    await context.push(AppRoutes.editScript(created.id));
    if (!context.mounted) return;
    await cubit.refresh();
  }

  Future<void> _handleCardAction(
    BuildContext context,
    ScriptListCubit cubit,
    ScriptCardAction action,
    Script script,
  ) async {
    switch (action) {
      case ScriptCardAction.rename:
        final String? name = await showRenameScriptDialog(context, script);
        if (name == null || !context.mounted) return;
        final bool renamed = await cubit.renameScript(script.id, name);
        if (!context.mounted || !renamed) return;
        showAppSnackBar(context, 'Renamed to "$name"', icon: Icons.check_rounded);

      case ScriptCardAction.edit:
        await context.push(AppRoutes.editScript(script.id));
        if (!context.mounted) return;
        await cubit.refresh();

      case ScriptCardAction.duplicate:
        final Script? copy = await cubit.duplicateScript(script.id);
        if (!context.mounted || copy == null) return;
        showAppSnackBar(context, 'Duplicated as "${copy.displayTitle}"',
            icon: Icons.copy_rounded);

      case ScriptCardAction.delete:
        final bool confirmed = await showDeleteScriptDialog(context, script);
        if (!confirmed || !context.mounted) return;
        final bool deleted = await cubit.deleteScript(script.id);
        if (!context.mounted || !deleted) return;
        showAppSnackBar(
          context,
          'Deleted "${script.displayTitle}"',
          icon: Icons.delete_outline_rounded,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.restoreScript(script),
          ),
          duration: const Duration(seconds: 6),
        );
    }
  }
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppColors colors = context.colors;

    return Row(
      children: <Widget>[
        const PrompterLogo(size: 32),
        const SizedBox(width: AppSpacing.md),
        // Expanded + ellipsis so the header survives a 320 px wide phone
        // without a RenderFlex overflow.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                AppConstants.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge,
              ),
              Text(
                AppConstants.appTagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The primary action: unmissable, one-handed reachable, with a hint of what
/// happens next.
class _NewScriptButton extends StatelessWidget {
  const _NewScriptButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      semanticLabel: 'New script',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.add_rounded, color: colors.onPrimary, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'New Script',
                      style: text.titleMedium?.copyWith(color: colors.onPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Write or paste, then read it on camera',
                      style: text.bodySmall?.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: colors.onPrimary.withValues(alpha: 0.85),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
