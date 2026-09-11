import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/text_metrics.dart';

/// A single saved script. Immutable domain object — copies are produced with
/// [copyWith], never mutated in place.
class Script extends Equatable {
  const Script({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a brand-new script from an id the caller generated.
  factory Script.create({
    required String id,
    required DateTime now,
    String title = '',
    String content = '',
  }) {
    return Script(
      id: id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Unique, stable identifier. Never reused after deletion.
  final String id;

  /// Display name. Blank titles are normalised before persisting.
  final String title;

  /// Raw script text. Paragraphs are separated by blank lines.
  final String content;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// A script is only persistable with an id; the data source refuses otherwise.
  bool get hasId => id.isNotEmpty;

  String get displayTitle =>
      title.trim().isEmpty ? AppConstants.untitledScriptTitle : title.trim();

  bool get isEmpty => TextMetrics.isBlank(content);

  int get wordCount => TextMetrics.wordCount(content);

  int get characterCount => TextMetrics.characterCount(content);

  int get paragraphCount => TextMetrics.paragraphCount(content);

  Duration get readTime => TextMetrics.estimatedReadTime(content);

  String get preview => TextMetrics.preview(content);

  Script copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return Script(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// True when the incoming values match what is already stored, so the editor
  /// can skip a pointless write.
  bool matches({required String otherTitle, required String otherContent}) =>
      title.trim() == otherTitle.trim() && content == otherContent;

  /// A new script cloned from this one, with a fresh id and a suffixed title.
  Script duplicate({
    required String newId,
    required DateTime now,
    String? title,
  }) {
    return Script(
      id: newId,
      title: title ?? duplicateTitle(this.title),
      content: content,
      createdAt: now,
      updatedAt: now,
    );
  }

  static const String duplicateSuffix = ' copy';

  /// `My script` → `My script copy`, capped at [AppConstants.maxTitleLength].
  static String duplicateTitle(String source) {
    final String base =
        source.trim().isEmpty ? AppConstants.untitledScriptTitle : source.trim();
    final String candidate = '$base$duplicateSuffix';
    if (candidate.length <= AppConstants.maxTitleLength) return candidate;
    return candidate.substring(0, AppConstants.maxTitleLength).trimRight();
  }

  @override
  List<Object?> get props => <Object?>[id, title, content, createdAt, updatedAt];
}
