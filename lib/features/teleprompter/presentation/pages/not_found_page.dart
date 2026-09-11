import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';

/// Shown for unknown routes (bad deep link, mistyped URL) — never a red screen.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({this.location, super.key});

  final String? location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: EmptyState(
              icon: Icons.explore_off_outlined,
              title: 'This screen does not exist',
              message: location == null
                  ? 'The link you followed is not part of the app.'
                  : 'Nothing lives at $location.',
              actionLabel: 'Back to scripts',
              onAction: () => context.go(AppRoutes.home),
            ),
          ),
        ),
      ),
      backgroundColor: context.colors.ink,
    );
  }
}
