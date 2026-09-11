/// Every route in the app, in one place so paths are never hand-written in a
/// widget and a typo becomes a compile error.
abstract final class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';

  static const String newScript = '/script/new';
  static const String editScriptPattern = '/script/:id/edit';
  static const String teleprompterPattern = '/teleprompter/:id';

  static const String scriptIdParam = 'id';

  static String editScript(String id) => '/script/$id/edit';

  static String teleprompter(String id) => '/teleprompter/$id';
}
