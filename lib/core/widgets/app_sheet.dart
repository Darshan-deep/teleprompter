import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// Shows a modal sheet with the app's chrome: grab handle, title, optional
/// reset action and a width cap so it stays readable on tablets and desktop.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
  List<Widget> actions = const <Widget>[],
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: context.colors.scrim,
    builder: (BuildContext sheetContext) => AppSheet(
      title: title,
      subtitle: subtitle,
      actions: actions,
      child: child,
    ),
  );
}

/// The sheet surface itself — also usable inline (e.g. inside a test harness).
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.child,
    this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth + 80),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
                border: Border(
                  top: BorderSide(color: colors.outline, width: AppSpacing.hairline),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineStrong,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(title!, style: text.titleLarge),
                                if (subtitle != null) ...<Widget>[
                                  const SizedBox(height: AppSpacing.xxs + 2),
                                  Text(
                                    subtitle!,
                                    style: text.bodySmall?.copyWith(color: colors.textTertiary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          ...actions,
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.sm,
                        AppSpacing.xl,
                        AppSpacing.xl,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
