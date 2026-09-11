import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppDependencies dependencies = await AppDependencies.bootstrap();
  runApp(TeleprompterApp(dependencies: dependencies));
}
