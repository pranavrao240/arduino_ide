import 'package:arduino_ide/app/app.dart';
import 'package:arduino_ide/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
