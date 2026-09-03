import 'package:arduino_ide/controllers/editor_controller.dart';
import 'package:arduino_ide/models/terminal_log.dart';
import 'package:arduino_ide/providers/editor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CompilerTerminal extends HookConsumerWidget {
  const CompilerTerminal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final isVerifying = editorState.isVerifying;
    final logs = editorState.terminalLogs;
    final compileResult = editorState.compileResult;
    final scrollController = useScrollController();

    // Auto scroll to bottom when new logs arrive
    useEffect(() {
      if (scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        });
      }
      return null;
    }, [logs.length]);

    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: Color(0xff0d151c),
        border: Border(
          top: BorderSide(
            color: Color(0xff1f2f3d),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xff121d26),
              border: Border(
                bottom: BorderSide(
                  color: Color(0xff1c2b36),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  size: 16,
                  color: Color(0xff00e5ff),
                ),
                const SizedBox(width: 8),
                const Text(
                  'OUTPUT',
                  style: TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 10),

                // Status Badge
                if (editorState.isUploading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff00cbb8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xff00cbb8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xff00e5ff),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          editorState.uploadProgress > 0
                              ? 'Uploading ${(editorState.uploadProgress * 100).toInt()}%'
                              : 'Uploading...',
                          style: const TextStyle(
                            color: Color(0xff00e5ff),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isVerifying)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff00cbb8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xff00cbb8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xff00e5ff),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Compiling...',
                          style: TextStyle(
                            color: Color(0xff00e5ff),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (editorState.uploadResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: editorState.uploadResult!.success
                          ? const Color(0xff4ade80).withValues(alpha: 0.15)
                          : const Color(0xfff43f5e).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: editorState.uploadResult!.success
                            ? const Color(0xff4ade80).withValues(alpha: 0.4)
                            : const Color(0xfff43f5e).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          editorState.uploadResult!.success
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          size: 13,
                          color: editorState.uploadResult!.success
                              ? const Color(0xff4ade80)
                              : const Color(0xfff43f5e),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          editorState.uploadResult!.success
                              ? 'Upload complete (${editorState.uploadResult!.durationMs}ms)'
                              : 'Upload failed',
                          style: TextStyle(
                            color: editorState.uploadResult!.success
                                ? const Color(0xff4ade80)
                                : const Color(0xfff43f5e),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (compileResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: compileResult.success
                          ? const Color(0xff4ade80).withValues(alpha: 0.15)
                          : const Color(0xfff43f5e).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: compileResult.success
                            ? const Color(0xff4ade80).withValues(alpha: 0.4)
                            : const Color(0xfff43f5e).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          compileResult.success
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          size: 13,
                          color: compileResult.success
                              ? const Color(0xff4ade80)
                              : const Color(0xfff43f5e),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          compileResult.success
                              ? 'Done compiling (${compileResult.durationMs}ms)'
                              : '${compileResult.errors.length} error(s)',
                          style: TextStyle(
                            color: compileResult.success
                                ? const Color(0xff4ade80)
                                : const Color(0xfff43f5e),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Clear Logs Button
                InkWell(
                  onTap: () {
                    ref.read(editorProvider.notifier).clearTerminal();
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                      color: Color(0xff60758a),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Close Terminal Button
                InkWell(
                  onTap: () {
                    ref.read(editorProvider.notifier).toggleTerminal(false);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xff60758a),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Terminal Output Logs
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'Press "Verify" to compile the active sketch.',
                      style: TextStyle(
                        color: Color(0xff475569),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: SelectableText(
                          log.message,
                          style: TextStyle(
                            color: _getLogColor(log.type),
                            fontSize: 12.5,
                            fontFamily: 'monospace',
                            height: 1.4,
                            fontWeight: log.type == TerminalLogType.command ||
                                    log.type == TerminalLogType.error ||
                                    log.type == TerminalLogType.success
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(TerminalLogType type) {
    switch (type) {
      case TerminalLogType.command:
        return const Color(0xff22d3ee); // Cyan command
      case TerminalLogType.error:
        return const Color(0xfff43f5e); // Vibrant red error
      case TerminalLogType.warning:
        return const Color(0xfffbbf24); // Amber warning
      case TerminalLogType.success:
        return const Color(0xff4ade80); // Green success
      case TerminalLogType.info:
        return const Color(0xffcbd5e1); // Default log text
    }
  }
}
