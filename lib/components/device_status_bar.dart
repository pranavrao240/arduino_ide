import 'dart:async';
import 'package:arduino_ide/providers/editor_provider.dart';
import 'package:arduino_ide/services/serial_port_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeviceStatusBar extends HookConsumerWidget {
  const DeviceStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);

    // Initial check and periodic polling for hot-plugged devices
    useEffect(() {
      ref.read(editorProvider.notifier).checkSerialConnection();

      final timer = Timer.periodic(const Duration(seconds: 4), (_) {
        ref.read(editorProvider.notifier).checkSerialConnection();
      });

      return timer.cancel;
    }, const []);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xff121a21),
      ),
      child: Row(
        children: [
          // Board indicator
          InkWell(
            onTap: () async {
              await ref.read(editorProvider.notifier).checkSerialConnection();
              if (context.mounted) {
                final state = ref.read(editorProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.isConnected
                          ? 'Device detected: ${state.deviceName} on ${state.portName}'
                          : 'No serial port device detected.',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xff162832),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xff22d3ee),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.menu,
                    size: 9,
                    color: Color(0xff22d3ee),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  editorState.deviceName,
                  style: const TextStyle(
                    color: Color(0xff22d3ee),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Port indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi,
                size: 13,
                color: Color(0xff60758a),
              ),
              const SizedBox(width: 5),
              Text(
                editorState.portName,
                style: const TextStyle(
                  color: Color(0xff60758a),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          const Spacer(),

          // Connection status
          InkWell(
            onTap: () async {
              await ref.read(editorProvider.notifier).checkSerialConnection();
            },
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: editorState.isConnected
                        ? const Color(0xff4ade80)
                        : const Color(0xffef4444),
                    boxShadow: editorState.isConnected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xff4ade80,
                              ).withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  editorState.isConnected ? 'CONNECTED' : 'DISCONNECTED',
                  style: TextStyle(
                    color: editorState.isConnected
                        ? const Color(0xff4ade80)
                        : const Color(0xffef4444),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
