import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/teleprompter_settings.dart';

/// The script itself, laid out for reading on camera.
///
/// Each paragraph is its own text block so the spacing between paragraphs is
/// exact, the layout of a long script is spread across many small render
/// objects instead of one enormous paragraph, and alignment applies per
/// paragraph. Mirroring is applied to the whole block with a single transform —
/// the underlying text is never modified.
class PromptTextView extends StatelessWidget {
  const PromptTextView({
    required this.content,
    required this.settings,
    required this.textColor,
    required this.horizontalPadding,
    super.key,
  });

  final String content;
  final TeleprompterSettings settings;
  final Color textColor;
  final double horizontalPadding;

  static final RegExp _paragraphSplit = RegExp(r'\n[ \t]*\n');

  List<String> get _paragraphs {
    final String normalized = content.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const <String>[''];
    return normalized
        .split(_paragraphSplit)
        .map((String paragraph) => paragraph.trim())
        .where((String paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = settings.textStyle(textColor);
    final List<String> paragraphs = _paragraphs;

    final Widget column = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < paragraphs.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: settings.paragraphSpacing),
            Text(
              paragraphs[i],
              textAlign: settings.alignment,
              style: style,
              // No ellipsis, no clipping: prompter text is never truncated.
              softWrap: true,
            ),
          ],
        ],
      ),
    );

    if (!settings.mirrored) return column;

    // Horizontal mirror for beam-splitter rigs.
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1, 1, 1),
      child: column,
    );
  }
}

/// Blocks the prompter text for accessibility readers without exposing every
/// paragraph separately as a focusable node.
class PromptSemantics extends StatelessWidget {
  const PromptSemantics({required this.content, required this.child, super.key});

  final String content;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      readOnly: true,
      label: 'Script text',
      value: content,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Padding conventions for the prompter canvas, kept in one place so the editor
/// preview and the live session agree.
abstract final class PrompterLayout {
  /// Where the reading line sits vertically (38% down the screen — slightly
  /// above centre, which is where a reader's eye naturally rests).
  static const double readingLineFraction = 0.38;

  static const double maxHorizontalPadding = 40;

  static double horizontalPaddingFor(double width) =>
      (width * 0.06).clamp(AppSpacing.lg, maxHorizontalPadding);
}
