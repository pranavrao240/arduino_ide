import 'package:arduino_ide/constants/navigation.dart';
import 'package:arduino_ide/presentations/editor_page/editor_page.dart';
import 'package:arduino_ide/presentations/files_page/files_page.dart';
import 'package:arduino_ide/presentations/serial_monitor_page/serial_monitor_page.dart';
import 'package:arduino_ide/presentations/settings_page/settings_page.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRoute {
  const AppRoute({required this.path, required this.name});
  final String path;
  final String name;
}

class RouteConstants {
  static const editor = AppRoute(path: '/', name: 'editor');
  static const files = AppRoute(path: '/files', name: 'files');
  static const serial = AppRoute(path: '/serial', name: 'serial');
  static const settings = AppRoute(path: '/settings', name: 'settings');
}

Future<bool> isUserLoggedIn() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');

    // Check if token exists and isn't empty
    if (token == null || token.isEmpty) {
      return false;
    }

    return true;
  } on Exception {
    return false;
  }
}

final List<String> publicRoutes = [
  RouteConstants.editor.path,
  RouteConstants.files.path,
  RouteConstants.serial.path,
  RouteConstants.settings.path,
];

final List<String> protectedRoutes = [];

final GoRouter router = GoRouter(
  navigatorKey: NavConstants.navigatorKey,
  initialLocation: RouteConstants.editor.path,
  redirect: (context, state) async {
    return null;
  },
  routes: [
    GoRoute(
      name: RouteConstants.editor.name,
      path: RouteConstants.editor.path,
      builder: (_, __) => const EditorPage(),
    ),
    GoRoute(
      name: RouteConstants.files.name,
      path: RouteConstants.files.path,
      builder: (_, __) => const FilesPage(),
    ),
    GoRoute(
      name: RouteConstants.serial.name,
      path: RouteConstants.serial.path,
      builder: (_, __) => const SerialMonitorPage(),
    ),
    GoRoute(
      name: RouteConstants.settings.name,
      path: RouteConstants.settings.path,
      builder: (_, __) => const SettingsPage(),
    ),
  ],
);
