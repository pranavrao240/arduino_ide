import 'package:arduino_ide/controllers/editor_controller.dart';
import 'package:arduino_ide/providers/editor_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditorTabBar extends HookConsumerWidget {
  const EditorTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final files = editorState.files;
    final selectedIndex = editorState.selectedFileIndex;

    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xff121b22),
        border: Border(
          bottom: BorderSide(
            color: Color(0xff1c2b36),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isSelected = index == selectedIndex;

          return InkWell(
            onTap: () {
              ref.read(editorProvider.notifier).selectFile(index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xff00e5ff) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                file.name,
                style: TextStyle(
                  color: isSelected ? const Color(0xffffffff) : const Color(0xff60758a),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'monospace',
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
