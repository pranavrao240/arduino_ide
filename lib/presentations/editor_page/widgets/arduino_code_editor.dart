import 'package:arduino_ide/constants/arduino_editor_theme.dart';
import 'package:arduino_ide/controllers/editor_controller.dart';
import 'package:arduino_ide/providers/editor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ArduinoCodeEditor extends HookConsumerWidget {
  const ArduinoCodeEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final activeFile = editorState.activeFile;

    final controller = useMemoized(
      () => CodeController(
        text: activeFile.content,
        language: activeFile.languageMode,
      ),
      [editorState.selectedFileIndex, activeFile.name],
    );

    useEffect(
      () {
        void listener() {
          if (controller.text != activeFile.content) {
            ref
                .read(editorProvider.notifier)
                .updateActiveContent(controller.text);
          }
        }

        controller.addListener(listener);
        return () {
          controller.removeListener(listener);
          controller.dispose();
        };
      },
      [controller],
    );

    final scrollController = useScrollController();

    return Container(
      color: const Color(0xff121b22),
      child: Stack(
        children: [
          // Background line highlight renderer for error and active lines
          if ((activeFile.hasError && activeFile.errorLine != null) ||
              activeFile.cursorLine != null)
            _LineHighlightLayer(
              errorLine: activeFile.hasError ? activeFile.errorLine : null,
              cursorLine: activeFile.cursorLine,
              scrollController: scrollController,
            ),

          // Code Field with CodeTheme
          CodeTheme(
            data: CodeThemeData(styles: arduinoEditorTheme),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CodeField(
                controller: controller,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13.5,
                  height: 1.45,
                  color: Color(0xfff1f5f9),
                ),
                lineNumberStyle: const LineNumberStyle(
                  width: 38,
                  margin: 10,
                  textStyle: TextStyle(
                    color: Color(0xff3e5162),
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                    height: 1.45,
                  ),
                  background: Color(0xff121b22),
                ),
                background: Colors.transparent,
                cursorColor: const Color(0xff00e5ff),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineHighlightLayer extends HookWidget {
  const _LineHighlightLayer({
    required this.scrollController,
    this.errorLine,
    this.cursorLine,
  });

  final ScrollController scrollController;
  final int? errorLine;
  final int? cursorLine;

  @override
  Widget build(BuildContext context) {
    useListenable(scrollController);
    final scrollOffset = scrollController.hasClients
        ? scrollController.offset
        : 0.0;

    const lineHeight = 19.575; // 13.5 * 1.45
    const topPadding = 8.0;

    return IgnorePointer(
      child: Stack(
        children: [
          // Error Line highlight (e.g. line 19)
          if (errorLine != null)
            Positioned(
              top: topPadding + (errorLine! - 1) * lineHeight - scrollOffset,
              left: 0,
              right: 0,
              height: lineHeight,
              child: Row(
                children: [
                  Container(
                    width: 2.5,
                    color: const Color(0xfff43f5e),
                  ),
                  Expanded(
                    child: Container(
                      color: const Color(0xff3b1f25).withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),

          // Active Cursor Line highlight (e.g. line 24)
          if (cursorLine != null)
            Positioned(
              top: topPadding + (cursorLine! - 1) * lineHeight - scrollOffset,
              left: 0,
              right: 0,
              height: lineHeight,
              child: Row(
                children: [
                  Container(
                    width: 2.5,
                    color: const Color(0xff00e5ff),
                  ),
                  Expanded(
                    child: Container(
                      color: const Color(0xff0e343c).withOpacity(0.9),
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
