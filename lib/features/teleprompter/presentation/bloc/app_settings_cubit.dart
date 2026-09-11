import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/teleprompter_settings.dart';
import '../../domain/usecases/settings_usecases.dart';
import 'app_settings_state.dart';

/// Owns persisted preferences.
///
/// Writes are coalesced: dragging a slider only ever produces one disk write,
/// while a toggle (which is a deliberate, final action) is written immediately.
class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit({
    required GetAppSettings getAppSettings,
    required SaveAppSettings saveAppSettings,
    required ResetAppSettings resetAppSettings,
    required GetTeleprompterSettings getTeleprompterSettings,
    required SaveTeleprompterSettings saveTeleprompterSettings,
    required ResetTeleprompterSettings resetTeleprompterSettings,
  })  : _getAppSettings = getAppSettings,
        _saveAppSettings = saveAppSettings,
        _resetAppSettings = resetAppSettings,
        _getTeleprompterSettings = getTeleprompterSettings,
        _saveTeleprompterSettings = saveTeleprompterSettings,
        _resetTeleprompterSettings = resetTeleprompterSettings,
        super(const AppSettingsState());

  final GetAppSettings _getAppSettings;
  final SaveAppSettings _saveAppSettings;
  final ResetAppSettings _resetAppSettings;
  final GetTeleprompterSettings _getTeleprompterSettings;
  final SaveTeleprompterSettings _saveTeleprompterSettings;
  final ResetTeleprompterSettings _resetTeleprompterSettings;

  Timer? _writeDebounce;
  AppSettings? _pendingWrite;
  bool _closed = false;

  Future<void> load() async {
    final Result<AppSettings> appResult = await _getAppSettings();
    final Result<TeleprompterSettings> prompterResult = await _getTeleprompterSettings();
    if (_closed) return;

    final AppSettings? app = appResult.valueOrNull;
    final TeleprompterSettings? prompter = prompterResult.valueOrNull;

    if (app == null && prompter == null) {
      emit(
        state.copyWith(
          status: AppSettingsStatus.failure,
          failure: appResult.failureOrNull ?? prompterResult.failureOrNull,
        ),
      );
      return;
    }

    // Prompter defaults live in their own key so a session never has to write
    // the whole app settings blob.
    emit(
      state.copyWith(
        status: AppSettingsStatus.ready,
        settings: (app ?? const AppSettings())
            .copyWith(teleprompter: prompter ?? const TeleprompterSettings()),
        clearFailure: true,
      ),
    );
  }

  void setThemeMode(AppThemeMode mode) {
    if (mode == state.settings.themeMode) return;
    _emitSettings(state.settings.copyWith(themeMode: mode), immediate: true);
  }

  void setKeepScreenAwake(bool value) {
    if (value == state.settings.keepScreenAwake) return;
    _emitSettings(state.settings.copyWith(keepScreenAwake: value), immediate: true);
  }

  /// Updates the prompter defaults. Pass `immediate: true` for discrete changes
  /// (a tap) and leave it false while a slider is being dragged.
  void updateTeleprompter(TeleprompterSettings settings, {bool immediate = false}) {
    if (settings == state.settings.teleprompter) return;
    _emitSettings(state.settings.copyWith(teleprompter: settings), immediate: immediate);
  }

  /// Restores every default, including clearing the stored prompter settings.
  Future<void> resetToDefaults() async {
    await _resetTeleprompterSettings();
    await _resetAppSettings();
    if (_closed) return;
    _pendingWrite = null;
    _writeDebounce?.cancel();
    emit(
      state.copyWith(
        status: AppSettingsStatus.ready,
        settings: const AppSettings(),
        clearFailure: true,
      ),
    );
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  void _emitSettings(AppSettings next, {required bool immediate}) {
    emit(state.copyWith(settings: next, status: AppSettingsStatus.ready));
    _pendingWrite = next;
    _writeDebounce?.cancel();

    if (immediate) {
      unawaited(_flushWrite());
      return;
    }
    _writeDebounce = Timer(AppSpacing.settingsPersistDebounce, () {
      unawaited(_flushWrite());
    });
  }

  Future<void> _flushWrite() async {
    final AppSettings? pending = _pendingWrite;
    if (pending == null) return;
    _pendingWrite = null;
    _writeDebounce?.cancel();

    await _saveAppSettings(pending);

    final Result<void> prompterResult = await _saveTeleprompterSettings(pending.teleprompter);
    if (_closed) return;

    final Failure? failure = prompterResult.failureOrNull;
    if (failure != null) emit(state.copyWith(failure: failure));
  }

  @override
  Future<void> close() async {
    _closed = true;
    _writeDebounce?.cancel();
    // Best-effort flush so a change made just before exit is not lost.
    final AppSettings? pending = _pendingWrite;
    if (pending != null) {
      _pendingWrite = null;
      unawaited(_saveAppSettings(pending));
      unawaited(_saveTeleprompterSettings(pending.teleprompter));
    }
    return super.close();
  }
}
