import 'package:arduino_ide/components/device_status_bar.dart';
import 'package:arduino_ide/components/editor_bottom_nav.dart';
import 'package:arduino_ide/components/editor_toolbar.dart';
import 'package:arduino_ide/controllers/editor_controller.dart';
import 'package:arduino_ide/models/serial_log_entry.dart';
import 'package:arduino_ide/providers/serial_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SerialMonitorPage extends HookConsumerWidget {
  const SerialMonitorPage({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serialState = ref.watch(serialProvider);
    final editorState = ref.watch(editorProvider);
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    // Auto-scroll when new logs arrive if auto-scroll is enabled
    useEffect(() {
      if (serialState.isAutoScroll && scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
      return null;
    }, [serialState.logs.length, serialState.isAutoScroll]);

    void handleSend() {
      final text = textController.text.trim();
      if (text.isNotEmpty) {
        ref.read(serialProvider.notifier).sendMessage(text);
        textController.clear();
      }
    }

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

              // 3. Serial Monitor Controls & Subheader
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    // Left: Title + Port Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SERIAL MONITOR',
                          style: TextStyle(
                            color: Color(0xff60758a),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: editorState.isConnected
                                    ? const Color(0xff4ade80)
                                    : const Color(0xffef4444),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              editorState.portName,
                              style: const TextStyle(
                                color: Color(0xff60758a),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Right: Baud Rate Dropdown
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xff18242c),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xff223542),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: serialState.baudRate,
                          dropdownColor: const Color(0xff18242c),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xff60758a),
                          ),
                          style: const TextStyle(
                            color: Color(0xfff1f5f9),
                            fontSize: 12.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                          items: _baudRates.map((baud) {
                            return DropdownMenuItem<String>(
                              value: baud,
                              child: Text(baud),
                            );
                          }).toList(),
                          onChanged: (newBaud) {
                            if (newBaud != null) {
                              ref
                                  .read(serialProvider.notifier)
                                  .setBaudRate(newBaud);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Clear button (Trash icon)
                    InkWell(
                      onTap: () {
                        ref.read(serialProvider.notifier).clearLogs();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: Color(0xff60758a),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Auto-scroll checkbox
                    InkWell(
                      onTap: () {
                        ref.read(serialProvider.notifier).toggleAutoScroll();
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: serialState.isAutoScroll
                                    ? const Color(0xff00cbb8)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: serialState.isAutoScroll
                                      ? const Color(0xff00cbb8)
                                      : const Color(0xff60758a),
                                  width: 1.4,
                                ),
                              ),
                              child: serialState.isAutoScroll
                                  ? const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Auto',
                              style: TextStyle(
                                color: Color(0xff60758a),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Divider / Top line for terminal
              const Divider(
                color: Color(0xff1c2b36),
                height: 1,
                thickness: 1,
              ),

              // 5. Console Logs Terminal Area
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: serialState.logs.length,
                  itemBuilder: (context, index) {
                    final log = serialState.logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timestamp (e.g. 14:32:01)
                          SizedBox(
                            width: 64,
                            child: Text(
                              log.timestamp,
                              style: const TextStyle(
                                color: Color(0xff475569),
                                fontSize: 12.5,
                                fontFamily: 'monospace',
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Type Badge (SYS, RX, TX)
                          SizedBox(
                            width: 32,
                            child: Text(
                              log.typeLabel,
                              style: TextStyle(
                                color: _getTypeColor(log.type),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Message
                          Expanded(
                            child: Text(
                              log.message,
                              style: TextStyle(
                                color: _getMessageColor(log.type),
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: log.type == SerialEntryType.rx
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 6. Serial Send Input Box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xff121a21),
                  border: Border(
                    top: BorderSide(
                      color: Color(0xff1c2b36),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Text Field
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xff16222b),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xff223542),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: textController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontFamily: 'monospace',
                          ),
                          onSubmitted: (_) => handleSend(),
                          decoration: const InputDecoration(
                            hintText: 'Send  message...',
                            hintStyle: TextStyle(
                              color: Color(0xff60758a),
                              fontSize: 13.5,
                              fontFamily: 'monospace',
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Send Button
                    InkWell(
                      onTap: handleSend,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xff00cbb8),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff00cbb8).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 7. Bottom Navigation Bar (from @components)
              const EditorBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(SerialEntryType type) {
    switch (type) {
      case SerialEntryType.sys:
        return const Color(0xff4c6b8a);
      case SerialEntryType.rx:
        return const Color(0xff00cbb8);
      case SerialEntryType.tx:
        return const Color(0xfff59e0b);
    }
  }

  Color _getMessageColor(SerialEntryType type) {
    switch (type) {
      case SerialEntryType.sys:
        return const Color(0xff4c6b8a);
      case SerialEntryType.rx:
        return const Color(0xfff1f5f9);
      case SerialEntryType.tx:
        return const Color(0xfffbbf24);
    }
  }
}
