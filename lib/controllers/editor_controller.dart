import 'package:arduino_ide/models/editor_file_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

export 'package:arduino_ide/providers/editor_provider.dart';

const String _initialBlinkCode = '''/*
 * Blink – turns on LED for 1s, off for 1s.
 * Board: Arduino Uno  Pin: 13
 */

// Pin configuration
const int LED_PIN = 13;
const int BUTTON_PIN = 2;

volatile bool buttonState = false;
int blinkInterval = 1000;

void setup() {
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  Serial.begin(9600);
  Serial.println("Blink ready");
  attachInterrupt(
    digitalPinToInterrupt(BUTTON_PIN),
    onButtonPress, FALLING
  );
}

void loop() {
  digitalWrite(LED_PIN, HIGH);
  delay(blinkInterval);
  digitalWrite(LED_PIN, LOW);
}
''';

const String _initialConfigCode = '''#ifndef CONFIG_H
#define CONFIG_H

// System configurations
#define BAUD_RATE 9600
#define DEFAULT_INTERVAL 1000

struct PinConfig {
  const int ledPin;
  const int buttonPin;
};

#endif // CONFIG_H
''';

const String _sensorLibCode = '''/*
 * SensorLib – Ultrasonic distance sensor reading.
 * Board: Arduino Uno
 */

#define TRIG_PIN 9
#define ECHO_PIN 10

long duration;
int distanceCm;

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  Serial.begin(9600);
  Serial.println("Ultrasonic Sensor Initialized");
}

void loop() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  duration = pulseIn(ECHO_PIN, HIGH);
  distanceCm = duration * 0.034 / 2;
  
  Serial.print("Distance: ");
  Serial.print(distanceCm);
  Serial.println(" cm");
  delay(500);
}
''';

const String _wifiConnectCode = '''/*
 * WiFiConnect – Connects Arduino to WiFi network.
 */

#include <WiFiEsp.h>

char ssid[] = "ArduinoNet_2.4G";
char pass[] = "SecureIotKey2026";
int status = WL_IDLE_STATUS;

void setup() {
  Serial.begin(9600);
  Serial.println("Connecting to WiFi...");
  
  while (status != WL_CONNECTED) {
    Serial.print("Attempting to connect to SSID: ");
    Serial.println(ssid);
    status = WiFi.begin(ssid, pass);
    delay(5000);
  }
  
  Serial.println("Connected to WiFi!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  delay(10000);
}
''';

const String _servoControlCode = '''/*
 * Servo_Control – Sweeps servo motor shaft back and forth.
 */

#include <Servo.h>

Servo myServo;
int servoPin = 9;
int angle = 0;

void setup() {
  myServo.attach(servoPin);
  Serial.begin(9600);
  Serial.println("Servo sweep initialized");
}

void loop() {
  for (angle = 0; angle <= 180; angle += 5) {
    myServo.write(angle);
    delay(20);
  }
  delay(500);
  for (angle = 180; angle >= 0; angle -= 5) {
    myServo.write(angle);
    delay(20);
  }
  delay(500);
}
''';

class EditorState {
  const EditorState({
    required this.files,
    this.selectedFileIndex = 0,
    this.deviceName = 'Arduino Uno',
    this.portName = '/dev/ttyUSB0',
    this.isConnected = true,
    this.bottomNavIndex = 0,
    this.isVerifying = false,
    this.isUploading = false,
  });

  final List<EditorFile> files;
  final int selectedFileIndex;
  final String deviceName;
  final String portName;
  final bool isConnected;
  final int bottomNavIndex;
  final bool isVerifying;
  final bool isUploading;

  EditorFile get activeFile =>
      files.isNotEmpty && selectedFileIndex < files.length
      ? files[selectedFileIndex]
      : const EditorFile(name: 'Untitled.ino', content: '');

  EditorState copyWith({
    List<EditorFile>? files,
    int? selectedFileIndex,
    String? deviceName,
    String? portName,
    bool? isConnected,
    int? bottomNavIndex,
    bool? isVerifying,
    bool? isUploading,
  }) {
    return EditorState(
      files: files ?? this.files,
      selectedFileIndex: selectedFileIndex ?? this.selectedFileIndex,
      deviceName: deviceName ?? this.deviceName,
      portName: portName ?? this.portName,
      isConnected: isConnected ?? this.isConnected,
      bottomNavIndex: bottomNavIndex ?? this.bottomNavIndex,
      isVerifying: isVerifying ?? this.isVerifying,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier()
    : super(
        const EditorState(
          files: [
            EditorFile(
              name: 'Blink.ino',
              content: _initialBlinkCode,
              hasError: true,
              errorLine: 19,
              cursorLine: 24,
              sizeText: '1.2 KB',
              modifiedTimeText: 'Today, 14:32',
            ),
            EditorFile(
              name: 'config.h',
              content: _initialConfigCode,
              sizeText: '348 B',
              modifiedTimeText: 'Today, 14:28',
            ),
            EditorFile(
              name: 'SensorLib.ino',
              content: _sensorLibCode,
              sizeText: '4.7 KB',
              modifiedTimeText: 'Yesterday',
            ),
            EditorFile(
              name: 'WiFiConnect.ino',
              content: _wifiConnectCode,
              sizeText: '2.1 KB',
              modifiedTimeText: 'Sep 1',
            ),
            EditorFile(
              name: 'Servo_Control.ino',
              content: _servoControlCode,
              sizeText: '3.4 KB',
              modifiedTimeText: 'Aug 30',
            ),
          ],
          selectedFileIndex: 0,
        ),
      );

  void selectFile(int index) {
    if (index >= 0 && index < state.files.length) {
      state = state.copyWith(selectedFileIndex: index);
    }
  }

  void updateActiveContent(String newContent) {
    final updatedFiles = List<EditorFile>.from(state.files);
    final current = updatedFiles[state.selectedFileIndex];
    updatedFiles[state.selectedFileIndex] = current.copyWith(
      content: newContent,
    );
    state = state.copyWith(files: updatedFiles);
  }

  void addNewFile(String name, [String content = '']) {
    final newFile = EditorFile(
      name: name,
      content: content.isEmpty
          ? '// $name\nvoid setup() {}\nvoid loop() {}\n'
          : content,
      sizeText: content.isEmpty ? '64 B' : '${content.length} B',
      modifiedTimeText: 'Just now',
    );
    final updatedFiles = [...state.files, newFile];
    state = state.copyWith(
      files: updatedFiles,
      selectedFileIndex: updatedFiles.length - 1,
    );
  }

  void removeFile(int index) {
    if (index < 0 || index >= state.files.length) return;
    final updatedFiles = List<EditorFile>.from(state.files)..removeAt(index);
    final newIndex = state.selectedFileIndex >= updatedFiles.length
        ? (updatedFiles.isNotEmpty ? updatedFiles.length - 1 : 0)
        : state.selectedFileIndex;
    state = state.copyWith(
      files: updatedFiles,
      selectedFileIndex: newIndex,
    );
  }

  void selectNavIndex(int index) {
    state = state.copyWith(bottomNavIndex: index);
  }

  void toggleConnection() {
    state = state.copyWith(isConnected: !state.isConnected);
  }
}
