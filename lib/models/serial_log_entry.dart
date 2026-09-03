enum SerialEntryType {
  sys,
  rx,
  tx,
}

class SerialLogEntry {
  const SerialLogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
  });

  final String timestamp;
  final SerialEntryType type;
  final String message;

  String get typeLabel {
    switch (type) {
      case SerialEntryType.sys:
        return 'SYS';
      case SerialEntryType.rx:
        return 'RX';
      case SerialEntryType.tx:
        return 'TX';
    }
  }
}
