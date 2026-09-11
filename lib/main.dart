import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage is opened once, before the first frame, so the home screen
  // never has to flash a spinner just to read a preference file.
  final AppDependencies dependencies = await AppDependencies.bootstrap();

  runApp(TeleprompterApp(dependencies: dependencies));
}
