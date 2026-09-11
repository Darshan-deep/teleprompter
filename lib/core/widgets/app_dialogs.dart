import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// Confirmation dialog. Returns `true` only when the user explicitly confirms;
/// dismissing it (barrier tap / back) resolves to `false`, so destructive
/// actions require intent.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final AppColors colors = context.colors;
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              cancelLabel,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? colors.danger : colors.primary,
              foregroundColor: destructive ? Colors.white : colors.onPrimary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Single-field text prompt used for creating and renaming scripts.
/// Returns the trimmed value, or `null` if the user cancelled.
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  String? message,
  String initialValue = '',
  String hintText = 'Script name',
  String confirmLabel = 'Save',
  int maxLength = AppConstants.maxTitleLength,
}) async {
  final TextEditingController controller = TextEditingController(text: initialValue);
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      final TextTheme text = Theme.of(dialogContext).textTheme;
      final AppColors colors = dialogContext.colors;

      void submit() {
        final String value = controller.text.trim();
        if (value.isEmpty) return;
        Navigator.of(dialogContext).pop(value);
      }

      return AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (message != null) ...<Widget>[
                Text(message, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextFormField(
                controller: controller,
                autofocus: true,
                maxLength: maxLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => submit(),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
                style: text.bodyLarge,
                decoration: InputDecoration(
                  hintText: hintText,
                  counterStyle: text.bodySmall?.copyWith(color: colors.textTertiary),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          FilledButton(onPressed: submit, child: Text(confirmLabel)),
        ],
      );
    },
  );

  controller.dispose();
  return result;
}

/// Informational dialog that explains a state the user cannot act on
/// (e.g. a deep link to a script that no longer exists).
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}
