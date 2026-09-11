import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

/// Inline, borderless title editor for the app bar.
///
/// Renaming a script should not require a dialog: the title is just another
/// thing you can type in, so it behaves like the writing surface below it.
class ScriptTitleField extends StatelessWidget {
  const ScriptTitleField({
    required this.controller,
    required this.onChanged,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(AppConstants.maxTitleLength),
      ],
      cursorColor: colors.primary,
      style: text.titleLarge?.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        hintText: 'Untitled script',
        hintStyle: text.titleLarge?.copyWith(color: colors.textTertiary),
      ),
    );
  }
}
