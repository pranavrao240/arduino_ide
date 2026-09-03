import 'package:arduino_ide/models/serial_log_entry.dart';
import 'package:flutter_riverpod/legacy.dart';

class SerialState {
  const SerialState({
    required this.logs,
    this.baudRate = '9600',
    this.isAutoScroll = true,
  });

  final List<SerialLogEntry> logs;
  final String baudRate;
  final bool isAutoScroll;

  SerialState copyWith({
    List<SerialLogEntry>? logs,
    String? baudRate,
    bool? isAutoScroll,
  }) {
    return SerialState(
      logs: logs ?? this.logs,
      baudRate: baudRate ?? this.baudRate,
      isAutoScroll: isAutoScroll ?? this.isAutoScroll,
    );
  }
}

final List<SerialLogEntry> _initialSerialLogs = [
  const SerialLogEntry(
    timestamp: '14:32:01',
    type: SerialEntryType.sys,
    message: '[sys] Port: /dev/ttyUSB0 @ 9600 baud',
  ),
  const SerialLogEntry(
    timestamp: '14:32:01',
    type: SerialEntryType.sys,
    message: '[sys] Connected',
  ),
  const SerialLogEntry(
    timestamp: '14:32:02',
    type: SerialEntryType.rx,
    message: 'Blink ready',
  ),
  const SerialLogEntry(
    timestamp: '14:32:03',
    type: SerialEntryType.rx,
    message: 'LED_ON interval=1000ms',
  ),
  const SerialLogEntry(
    timestamp: '14:32:04',
    type: SerialEntryType.rx,
    message: 'LED_OFF',
  ),
  const SerialLogEntry(
    timestamp: '14:32:05',
    type: SerialEntryType.rx,
    message: 'LED_ON interval=1000ms',
  ),
  const SerialLogEntry(
    timestamp: '14:32:06',
    type: SerialEntryType.rx,
    message: 'BTN pressed -> fast mode',
  ),
  const SerialLogEntry(
    timestamp: '14:32:07',
    type: SerialEntryType.rx,
    message: 'LED_ON interval=250ms',
  ),
  const SerialLogEntry(
    timestamp: '13:04:09',
    type: SerialEntryType.rx,
    message: 'sensor=23.4°C',
  ),
  const SerialLogEntry(
    timestamp: '13:04:11',
    type: SerialEntryType.rx,
    message: 'LED_ON interval=1000ms',
  ),
];

class SerialNotifier extends StateNotifier<SerialState> {
  SerialNotifier()
      : super(
          SerialState(
            logs: List.from(_initialSerialLogs),
            baudRate: '9600',
            isAutoScroll: true,
          ),
        );

  void setBaudRate(String baud) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    final updated = List<SerialLogEntry>.from(state.logs)
      ..add(
        SerialLogEntry(
          timestamp: timeStr,
          type: SerialEntryType.sys,
          message: '[sys] Baud rate changed to $baud baud',
        ),
      );

    state = state.copyWith(
      baudRate: baud,
      logs: updated,
    );
  }

  void toggleAutoScroll() {
    state = state.copyWith(isAutoScroll: !state.isAutoScroll);
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final updated = List<SerialLogEntry>.from(state.logs)
      ..add(
        SerialLogEntry(
          timestamp: timeStr,
          type: SerialEntryType.tx,
          message: text.trim(),
        ),
      );

    // Simulate echo or acknowledgement response from microcontroller
    if (text.toLowerCase().contains('read') || text.toLowerCase().contains('sensor')) {
      updated.add(
        SerialLogEntry(
          timestamp: timeStr,
          type: SerialEntryType.rx,
          message: 'sensor=24.1°C humidity=48%',
        ),
      );
    } else if (text.toLowerCase().contains('help')) {
      updated.add(
        SerialLogEntry(
          timestamp: timeStr,
          type: SerialEntryType.rx,
          message: 'Commands: HELP, READ, LED_ON, LED_OFF, RESET',
        ),
      );
    } else {
      updated.add(
        SerialLogEntry(
          timestamp: timeStr,
          type: SerialEntryType.rx,
          message: 'ACK: $text',
        ),
      );
    }

    state = state.copyWith(logs: updated);
  }
}

final serialProvider = StateNotifierProvider<SerialNotifier, SerialState>(
  (ref) => SerialNotifier(),
);
