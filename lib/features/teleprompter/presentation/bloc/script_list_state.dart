import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/script.dart';

/// Lifecycle of the scripts list.
enum ScriptListStatus { initial, loading, ready, error }

class ScriptListState extends Equatable {
  const ScriptListState({
    this.status = ScriptListStatus.initial,
    this.scripts = const <Script>[],
    this.failure,
    this.busyScriptIds = const <String>{},
    this.showEmptyState = true,
  });

  final ScriptListStatus status;

  /// Most recently edited first.
  final List<Script> scripts;

  final Failure? failure;

  /// Scripts with an in-flight mutation, so their card can show a spinner
  /// instead of reacting to a tap that has already been handled.
  final Set<String> busyScriptIds;

  /// False once the user has created at least one script (drives the empty
  /// state vs. the list, and keeps the UI stable during a reload).
  final bool showEmptyState;

  bool get isLoading => status == ScriptListStatus.loading;

  bool get hasScripts => scripts.isNotEmpty;

  bool get isEmpty =>
      status == ScriptListStatus.ready && scripts.isEmpty;

  bool isBusy(String id) => busyScriptIds.contains(id);

  ScriptListState copyWith({
    ScriptListStatus? status,
    List<Script>? scripts,
    Failure? failure,
    bool clearFailure = false,
    Set<String>? busyScriptIds,
    bool? showEmptyState,
  }) {
    return ScriptListState(
      status: status ?? this.status,
      scripts: scripts ?? this.scripts,
      failure: clearFailure ? null : (failure ?? this.failure),
      busyScriptIds: busyScriptIds ?? this.busyScriptIds,
      showEmptyState: showEmptyState ?? this.showEmptyState,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[status, scripts, failure, busyScriptIds, showEmptyState];
}
