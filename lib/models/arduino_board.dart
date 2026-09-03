class ArduinoBoard {
  const ArduinoBoard({
    required this.name,
    required this.fqbn,
    required this.architecture,
    this.maxFlashBytes = 32256,
    this.maxRamBytes = 2048,
  });

  final String name;
  final String fqbn;
  final String architecture;
  final int maxFlashBytes;
  final int maxRamBytes;

  static const ArduinoBoard esp32DevModule = ArduinoBoard(
    name: 'ESP32 Dev Module',
    fqbn: 'esp32:esp32:esp32',
    architecture: 'esp32',
    maxFlashBytes: 1310720, // 1.25 MB default partition
    maxRamBytes: 327680,   // 320 KB SRAM
  );

  static const ArduinoBoard arduinoUno = ArduinoBoard(
    name: 'Arduino Uno',
    fqbn: 'arduino:avr:uno',
    architecture: 'avr',
    maxFlashBytes: 32256,
    maxRamBytes: 2048,
  );

  static const ArduinoBoard arduinoNano = ArduinoBoard(
    name: 'Arduino Nano',
    fqbn: 'arduino:avr:nano',
    architecture: 'avr',
    maxFlashBytes: 30720,
    maxRamBytes: 2048,
  );

  static const ArduinoBoard arduinoMega = ArduinoBoard(
    name: 'Arduino Mega 2560',
    fqbn: 'arduino:avr:mega',
    architecture: 'avr',
    maxFlashBytes: 253952,
    maxRamBytes: 8192,
  );

  static const List<ArduinoBoard> supportedBoards = [
    esp32DevModule,
    arduinoUno,
    arduinoNano,
    arduinoMega,
  ];

  static ArduinoBoard fromName(String name) {
    return supportedBoards.firstWhere(
      (b) => b.name.toLowerCase() == name.toLowerCase(),
      orElse: () => esp32DevModule,
    );
  }

  static ArduinoBoard fromFqbn(String fqbn) {
    return supportedBoards.firstWhere(
      (b) => b.fqbn == fqbn,
      orElse: () => esp32DevModule,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArduinoBoard &&
          runtimeType == other.runtimeType &&
          fqbn == other.fqbn;

  @override
  int get hashCode => fqbn.hashCode;
}
