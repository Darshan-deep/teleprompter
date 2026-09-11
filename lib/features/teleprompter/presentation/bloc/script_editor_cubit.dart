import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/text_metrics.dart';
import '../../domain/entities/script.dart';
import '../../domain/usecases/script_usecases.dart';
import 'script_editor_state.dart';

/// Drives the script editor: load, edit, auto-save, explicit save.
///
/// Auto-save rules (chosen so the user never loses writing but also never ends
/// up with a list full of empty scripts):
///
/// * a saved script is written back after a short idle debounce;
/// * a brand-new draft is only persisted once it has content or a title;
/// * leaving the editor flushes any pending change immediately.
class ScriptEditorCubit extends Cubit<ScriptEditorState> {
  ScriptEditorCubit({
    required this.scriptId,
    required GetScript getScript,
    required SaveScript saveScript,
  })  : _getScript = getScript,
        _saveScript = saveScript,
        super(const ScriptEditorState());

  /// `null` for a new script.
  final String? scriptId;

  final GetScript _getScript;
  final SaveScript _saveScript;

  Timer? _autosaveTimer;
  bool _closed = false;

  Future<void> load() async {
    final String? id = scriptId;
    if (id == null) {
      emit(state.copyWith(status: ScriptEditorStatus.ready, clearFailure: true));
      return;
    }

    emit(state.copyWith(status: ScriptEditorStatus.loading, clearFailure: true));
    final Result<Script?> result = await _getScript(id);
    if (_closed) return;

    switch (result) {
      case Ok<Script?>(:final value):
        if (value == null) {
          emit(state.copyWith(status: ScriptEditorStatus.missing));
          return;
        }
        emit(
          _withContent(
            state.copyWith(
              status: ScriptEditorStatus.ready,
              scriptId: value.id,
              title: value.title,
              content: value.content,
              isDirty: false,
              savedAt: value.updatedAt,
              clearFailure: true,
            ),
          ),
        );
      case Err<Script?>(:final failure):
        emit(state.copyWith(status: ScriptEditorStatus.failure, failure: failure));
    }
  }

  void titleChanged(String value) {
    if (value == state.title) return;
    emit(_withContent(state.copyWith(title: value, isDirty: true)));
    _scheduleAutosave();
  }

  void contentChanged(String value) {
    if (value == state.content) return;
    emit(_withContent(state.copyWith(content: value, isDirty: true)));
    _scheduleAutosave();
  }

  /// Saves immediately. Returns the persisted script, or `null` on failure.
  ///
  /// [force] persists even an empty draft (used by the explicit Save button so
  /// the user's intent to create something is honoured).
  Future<Script?> saveNow({bool force = false}) async {
    _autosaveTimer?.cancel();

    if (!force && !state.hasContent && state.title.trim().isEmpty) {
      return null; // Nothing worth storing yet.
    }
    if (!state.isDirty && !state.isNew) {
      return _currentScriptSnapshot();
    }

    emit(state.copyWith(isSaving: true, clearFailure: true));

    final Result<Script> result = await _saveScript(
      id: state.scriptId,
      title: state.title,
      content: state.content,
    );
    if (_closed) return result.valueOrNull;

    switch (result) {
      case Ok<Script>(:final value):
        emit(
          state.copyWith(
            status: ScriptEditorStatus.ready,
            scriptId: value.id,
            title: value.title,
            isDirty: false,
            isSaving: false,
            savedAt: value.updatedAt,
            clearFailure: true,
          ),
        );
        return value;
      case Err<Script>(:final failure):
        emit(state.copyWith(isSaving: false, failure: failure));
        return null;
    }
  }

  /// Called right before the screen pops so nothing typed is lost.
  Future<void> flush() async {
    _autosaveTimer?.cancel();
    if (state.status != ScriptEditorStatus.ready) return;
    if (state.isDirty) {
      await saveNow();
    }
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(AppSpacing.autosaveDebounce, () {
      unawaited(saveNow());
    });
  }

  ScriptEditorState _withContent(ScriptEditorState next) {
    final String content = next.content;
    return next.copyWith(
      wordCount: TextMetrics.wordCount(content),
      characterCount: TextMetrics.characterCount(content),
      paragraphCount: TextMetrics.paragraphCount(content),
      readTime: TextMetrics.estimatedReadTime(content),
    );
  }

  Script? _currentScriptSnapshot() {
    final String? id = state.scriptId;
    if (id == null) return null;
    final DateTime stamp = state.savedAt ?? DateTime.now();
    return Script(
      id: id,
      title: state.title,
      content: state.content,
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  @override
  Future<void> close() async {
    _closed = true;
    _autosaveTimer?.cancel();
    return super.close();
  }
}
