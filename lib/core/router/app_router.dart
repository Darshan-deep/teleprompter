import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/teleprompter/presentation/bloc/app_settings_cubit.dart';
import '../../features/teleprompter/presentation/bloc/script_editor_cubit.dart';
import '../../features/teleprompter/presentation/bloc/script_list_cubit.dart';
import '../../features/teleprompter/presentation/bloc/teleprompter_cubit.dart';
import '../../features/teleprompter/presentation/pages/home_page.dart';
import '../../features/teleprompter/presentation/pages/not_found_page.dart';
import '../../features/teleprompter/presentation/pages/script_editor_page.dart';
import '../../features/teleprompter/presentation/pages/settings_page.dart';
import '../../features/teleprompter/presentation/pages/teleprompter_page.dart';
import '../di/app_dependencies.dart';
import 'app_routes.dart';

/// Builds the app's navigator.
///
/// Cubits are created per route so each screen owns exactly the state it needs
/// and disposes it on pop — the home list survives navigation, an editor or a
/// prompter session does not outlive its screen.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          final AppDependencies deps = context.read<AppDependencies>();
          return BlocProvider<ScriptListCubit>(
            create: (BuildContext context) => ScriptListCubit(
              getScripts: deps.getScripts,
              saveScript: deps.saveScript,
              deleteScript: deps.deleteScript,
              duplicateScript: deps.duplicateScript,
            )..load(),
            child: const HomePage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.newScript,
        name: 'newScript',
        builder: (BuildContext context, GoRouterState state) =>
            _editor(context, scriptId: null),
      ),
      GoRoute(
        path: AppRoutes.editScriptPattern,
        name: 'editScript',
        builder: (BuildContext context, GoRouterState state) =>
            _editor(context, scriptId: state.pathParameters[AppRoutes.scriptIdParam]),
      ),
      GoRoute(
        path: AppRoutes.teleprompterPattern,
        name: 'teleprompter',
        builder: (BuildContext context, GoRouterState state) {
          final AppDependencies deps = context.read<AppDependencies>();
          final String? id = state.pathParameters[AppRoutes.scriptIdParam];
          final settings = context.read<AppSettingsCubit>().state.settings.teleprompter;

          return BlocProvider<TeleprompterCubit>(
            create: (BuildContext context) => TeleprompterCubit(
              getScript: deps.getScript,
              defaults: settings,
            )..load(id ?? ''),
            child: TeleprompterPage(scriptId: id ?? ''),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) =>
        NotFoundPage(location: state.uri.toString()),
  );
}

Widget _editor(BuildContext context, {required String? scriptId}) {
  final AppDependencies deps = context.read<AppDependencies>();
  return BlocProvider<ScriptEditorCubit>(
    create: (BuildContext context) => ScriptEditorCubit(
      scriptId: scriptId,
      getScript: deps.getScript,
      saveScript: deps.saveScript,
    )..load(),
    child: const ScriptEditorPage(),
  );
}
