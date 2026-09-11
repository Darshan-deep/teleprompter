import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// One consistent feedback channel. Any transient message in the app goes
/// through here so timing, placement and wording stay uniform.
void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final AppColors colors = context.colors;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        action: action,
        content: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
