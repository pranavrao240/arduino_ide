import 'package:arduino_ide/components/device_status_bar.dart';
import 'package:arduino_ide/components/editor_bottom_nav.dart';
import 'package:arduino_ide/components/editor_toolbar.dart';
import 'package:arduino_ide/presentations/editor_page/widgets/arduino_code_editor.dart';
import 'package:arduino_ide/presentations/editor_page/widgets/editor_tab_bar.dart';
import 'package:arduino_ide/presentations/files_page/files_page.dart';
import 'package:arduino_ide/presentations/serial_monitor_page/serial_monitor_page.dart';
import 'package:arduino_ide/presentations/settings_page/settings_page.dart';
import 'package:arduino_ide/providers/editor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditorPage extends HookConsumerWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);

    if (editorState.bottomNavIndex == 1) {
      return const FilesPage();
    } else if (editorState.bottomNavIndex == 2) {
      return const SerialMonitorPage();
    } else if (editorState.bottomNavIndex == 3) {
      return const SettingsPage();
    }

    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xff121a21),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xff121a21),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Device and port status header
              DeviceStatusBar(),

              // 2. Main action toolbar (Verify, Upload, Monitor, Add)
              EditorToolbar(),

              // 3. Tab bar for open sketch & header files
              EditorTabBar(),

              // 4. Code editor area with full Arduino language support
              Expanded(
                child: ArduinoCodeEditor(),
              ),

              // 5. Bottom Navigation Bar
              EditorBottomNav(),
            ],
          ),
        ),
      ),
    );
  }
}
