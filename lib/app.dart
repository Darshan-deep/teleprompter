import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/di/app_dependencies.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/teleprompter/domain/entities/app_settings.dart';
import 'features/teleprompter/presentation/bloc/app_settings_cubit.dart';
import 'features/teleprompter/presentation/bloc/app_settings_state.dart';

/// Root of the application.
///
/// Dependencies are injected once here; the router and the settings cubit are
/// created a single time so navigation state and preferences survive rebuilds.
class TeleprompterApp extends StatelessWidget {
  const TeleprompterApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AppDependencies>.value(
      value: dependencies,
      child: BlocProvider<AppSettingsCubit>(
        create: (BuildContext context) => AppSettingsCubit(
          getAppSettings: dependencies.getAppSettings,
          saveAppSettings: dependencies.saveAppSettings,
          resetAppSettings: dependencies.resetAppSettings,
          getTeleprompterSettings: dependencies.getTeleprompterSettings,
          saveTeleprompterSettings: dependencies.saveTeleprompterSettings,
          resetTeleprompterSettings: dependencies.resetTeleprompterSettings,
        )..load(),
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  /// Created once: the navigator owns route state, so it must outlive rebuilds
  /// caused by theme changes.
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (AppSettingsState previous, AppSettingsState current) =>
          previous.settings.themeMode != current.settings.themeMode,
      builder: (BuildContext context, AppSettingsState state) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: switch (state.settings.themeMode) {
            AppThemeMode.dark => ThemeMode.dark,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.system => ThemeMode.system,
          },
          routerConfig: _router,
        );
      },
    );
  }
}
