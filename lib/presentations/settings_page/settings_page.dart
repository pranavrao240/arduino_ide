import 'package:arduino_ide/components/device_status_bar.dart';
import 'package:arduino_ide/components/editor_bottom_nav.dart';
import 'package:arduino_ide/components/editor_toolbar.dart';
import 'package:arduino_ide/models/arduino_board.dart';
import 'package:arduino_ide/providers/editor_provider.dart';
import 'package:arduino_ide/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  static const List<String> _boards = [
    'Arduino Uno',
    'Arduino Mega 2560',
    'Arduino Nano',
    'ESP32 Dev Module',
    'ESP8266 NodeMCU',
    'Raspberry Pi Pico',
  ];

  static const List<String> _ports = [
    '/dev/ttyUSB0',
    '/dev/ttyACM0',
    'COM1',
    'COM3 (Arduino Uno)',
    'COM4',
    '/dev/cu.usbserial-1410',
  ];

  static const List<String> _baudRates = [
    '300',
    '1200',
    '2400',
    '4800',
    '9600',
    '19200',
    '38400',
    '57600',
    '74880',
    '115200',
    '230400',
  ];

  static const List<String> _programmers = [
    'AVRISP mkII',
    'USBasp',
    'Arduino as ISP',
    'AVR ISP',
    'Atmel-ICE',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xff121a21),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xff121a21),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Device and port status header (from @components)
              const DeviceStatusBar(),

              // 2. Action toolbar (from @components)
              const EditorToolbar(),

              // 3. Scrollable Settings Content
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Section 1: HARDWARE
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
                      child: Text(
                        'HARDWARE',
                        style: TextStyle(
                          color: Color(0xff60758a),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),

                    // Board Dropdown
                    _buildDropdownField(
                      label: 'Board',
                      value: settings.board,
                      items: _boards,
                      onChanged: (val) {
                        if (val != null) {
                          notifier.setBoard(val);
                          ref.read(editorProvider.notifier).selectBoard(ArduinoBoard.fromName(val));
                        }
                      },
                    ),

                    // Port Dropdown
                    _buildDropdownField(
                      label: 'Port',
                      value: settings.port,
                      items: _ports,
                      onChanged: (val) {
                        if (val != null) notifier.setPort(val);
                      },
                    ),

                    // Baud Rate Dropdown
                    _buildDropdownField(
                      label: 'Baud Rate',
                      value: settings.baudRate,
                      items: _baudRates,
                      onChanged: (val) {
                        if (val != null) notifier.setBaudRate(val);
                      },
                    ),

                    // Programmer Dropdown
                    _buildDropdownField(
                      label: 'Programmer',
                      value: settings.programmer,
                      items: _programmers,
                      onChanged: (val) {
                        if (val != null) notifier.setProgrammer(val);
                      },
                    ),

                    // Section 2: EDITOR
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 22, 16, 8),
                      child: Text(
                        'EDITOR',
                        style: TextStyle(
                          color: Color(0xff60758a),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),

                    // Switch Rows
                    _buildSwitchTile(
                      label: 'Line numbers',
                      value: settings.lineNumbers,
                      onChanged: (val) => notifier.toggleLineNumbers(val),
                    ),
                    const Divider(color: Color(0xff1c2b36), height: 1),

                    _buildSwitchTile(
                      label: 'Auto-indent',
                      value: settings.autoIndent,
                      onChanged: (val) => notifier.toggleAutoIndent(val),
                    ),
                    const Divider(color: Color(0xff1c2b36), height: 1),

                    _buildSwitchTile(
                      label: 'Syntax highlighting',
                      value: settings.syntaxHighlighting,
                      onChanged: (val) =>
                          notifier.toggleSyntaxHighlighting(val),
                    ),
                    const Divider(color: Color(0xff1c2b36), height: 1),

                    _buildSwitchTile(
                      label: 'Auto-save',
                      value: settings.autoSave,
                      onChanged: (val) => notifier.toggleAutoSave(val),
                    ),
                    const Divider(color: Color(0xff1c2b36), height: 1),

                    _buildSwitchTile(
                      label: 'Verbose output',
                      value: settings.verboseOutput,
                      onChanged: (val) => notifier.toggleVerboseOutput(val),
                    ),
                    const Divider(color: Color(0xff1c2b36), height: 1),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // 4. Bottom Navigation Bar (from @components)
              const EditorBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff60758a),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xff16222b),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xff223542),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : items.first,
                dropdownColor: const Color(0xff16222b),
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xff60758a),
                  size: 20,
                ),
                style: const TextStyle(
                  color: Color(0xfff1f5f9),
                  fontSize: 14,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xfff1f5f9),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xff00cbb8),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xff334155),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
