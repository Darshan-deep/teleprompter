import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_settings.dart';

enum AppSettingsStatus { loading, ready, failure }

/// App-wide preferences: theme, keep-awake and the prompter defaults that every
/// new session starts from.
class AppSettingsState extends Equatable {
  const AppSettingsState({
    this.status = AppSettingsStatus.loading,
    this.settings = const AppSettings(),
    this.failure,
  });

  final AppSettingsStatus status;
  final AppSettings settings;
  final Failure? failure;

  bool get isReady => status == AppSettingsStatus.ready;

  AppSettingsState copyWith({
    AppSettingsStatus? status,
    AppSettings? settings,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AppSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, settings, failure];
}
