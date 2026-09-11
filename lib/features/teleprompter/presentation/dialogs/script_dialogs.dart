import 'package:flutter/material.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/script.dart';

/// Rename / duplicate-name handling for a script.
Future<String?> showRenameScriptDialog(BuildContext context, Script script) {
  return showTextPromptDialog(
    context,
    title: 'Rename script',
    initialValue: script.title.trim().isEmpty ? '' : script.title,
    hintText: 'Script name',
    confirmLabel: 'Rename',
  );
}

/// Destructive-action confirmation that names the script it will remove, so it
/// is obvious what is about to disappear.
Future<bool> showDeleteScriptDialog(BuildContext context, Script script) {
  final int words = script.wordCount;
  return showConfirmDialog(
    context,
    title: 'Delete script?',
    message:
        '"${script.displayTitle}" will be permanently removed from this device'
        '${words > 0 ? ' ($words words)' : ''}. This cannot be undone.',
    confirmLabel: 'Delete',
    destructive: true,
  );
}
