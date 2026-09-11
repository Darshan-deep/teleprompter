import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';

enum ScriptEditorStatus {
  loading,

  /// Editing (existing script or a new draft).
  ready,

  /// The requested script id no longer exists.
  missing,

  /// Loading failed for another reason.
  failure,
}

/// Everything the editor screen renders. Statistics are computed once, in the
/// cubit, so a keystroke never triggers text scanning inside a build method.
class ScriptEditorState extends Equatable {
  const ScriptEditorState({
    this.status = ScriptEditorStatus.loading,
    this.scriptId,
    this.title = '',
    this.content = '',
    this.isSaving = false,
    this.isDirty = false,
    this.savedAt,
    this.failure,
    this.wordCount = 0,
    this.characterCount = 0,
    this.paragraphCount = 0,
    this.readTime = Duration.zero,
  });

  final ScriptEditorStatus status;

  /// `null` until a draft is saved for the first time.
  final String? scriptId;

  final String title;
  final String content;

  final bool isSaving;
  final bool isDirty;
  final DateTime? savedAt;
  final Failure? failure;

  final int wordCount;
  final int characterCount;
  final int paragraphCount;
  final Duration readTime;

  bool get isNew => scriptId == null;

  bool get isLoading => status == ScriptEditorStatus.loading;

  bool get isReady => status == ScriptEditorStatus.ready;

  /// The script is available for a prompter session.
  bool get canRead => status == ScriptEditorStatus.ready && wordCount > 0;

  bool get hasContent => content.trim().isNotEmpty;

  bool get isBlankDraft => !hasContent && title.trim().isEmpty;

  ScriptEditorState copyWith({
    ScriptEditorStatus? status,
    String? scriptId,
    String? title,
    String? content,
    bool? isSaving,
    bool? isDirty,
    DateTime? savedAt,
    Failure? failure,
    bool clearFailure = false,
    int? wordCount,
    int? characterCount,
    int? paragraphCount,
    Duration? readTime,
  }) {
    return ScriptEditorState(
      status: status ?? this.status,
      scriptId: scriptId ?? this.scriptId,
      title: title ?? this.title,
      content: content ?? this.content,
      isSaving: isSaving ?? this.isSaving,
      isDirty: isDirty ?? this.isDirty,
      savedAt: savedAt ?? this.savedAt,
      failure: clearFailure ? null : (failure ?? this.failure),
      wordCount: wordCount ?? this.wordCount,
      characterCount: characterCount ?? this.characterCount,
      paragraphCount: paragraphCount ?? this.paragraphCount,
      readTime: readTime ?? this.readTime,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        scriptId,
        title,
        content,
        isSaving,
        isDirty,
        savedAt,
        failure,
        wordCount,
        characterCount,
        paragraphCount,
        readTime,
      ];
}
