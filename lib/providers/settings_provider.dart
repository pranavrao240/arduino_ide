import 'package:flutter_riverpod/legacy.dart';

class SettingsState {
  const SettingsState({
    this.board = 'Arduino Uno',
    this.port = '/dev/ttyUSB0',
    this.baudRate = '9600',
    this.programmer = 'AVRISP mkII',
    this.lineNumbers = true,
    this.autoIndent = true,
    this.syntaxHighlighting = true,
    this.autoSave = false,
    this.verboseOutput = false,
  });

  final String board;
  final String port;
  final String baudRate;
  final String programmer;
  final bool lineNumbers;
  final bool autoIndent;
  final bool syntaxHighlighting;
  final bool autoSave;
  final bool verboseOutput;

  SettingsState copyWith({
    String? board,
    String? port,
    String? baudRate,
    String? programmer,
    bool? lineNumbers,
    bool? autoIndent,
    bool? syntaxHighlighting,
    bool? autoSave,
    bool? verboseOutput,
  }) {
    return SettingsState(
      board: board ?? this.board,
      port: port ?? this.port,
      baudRate: baudRate ?? this.baudRate,
      programmer: programmer ?? this.programmer,
      lineNumbers: lineNumbers ?? this.lineNumbers,
      autoIndent: autoIndent ?? this.autoIndent,
      syntaxHighlighting: syntaxHighlighting ?? this.syntaxHighlighting,
      autoSave: autoSave ?? this.autoSave,
      verboseOutput: verboseOutput ?? this.verboseOutput,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setBoard(String board) => state = state.copyWith(board: board);
  void setPort(String port) => state = state.copyWith(port: port);
  void setBaudRate(String baudRate) => state = state.copyWith(baudRate: baudRate);
  void setProgrammer(String programmer) => state = state.copyWith(programmer: programmer);

  void toggleLineNumbers(bool value) => state = state.copyWith(lineNumbers: value);
  void toggleAutoIndent(bool value) => state = state.copyWith(autoIndent: value);
  void toggleSyntaxHighlighting(bool value) => state = state.copyWith(syntaxHighlighting: value);
  void toggleAutoSave(bool value) => state = state.copyWith(autoSave: value);
  void toggleVerboseOutput(bool value) => state = state.copyWith(verboseOutput: value);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
