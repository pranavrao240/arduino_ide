import 'package:arduino_ide/controllers/editor_controller.dart';
import 'package:arduino_ide/providers/editor_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditorToolbar extends HookConsumerWidget {
  const EditorToolbar({
    super.key,
    this.onVerify,
    this.onUpload,
    this.onAddFile,
    this.onOpenSerial,
  });

  final VoidCallback? onVerify;
  final VoidCallback? onUpload;
  final VoidCallback? onAddFile;
  final VoidCallback? onOpenSerial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xff152028),
      ),
      child: Row(
        children: [
          // Action node icon button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xff00cbb8),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff00cbb8).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.all_inclusive_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Upload Button
          InkWell(
            onTap:
                (ref.watch(editorProvider).isUploading ||
                    ref.watch(editorProvider).isVerifying)
                ? null
                : (onUpload ??
                      () {
                        ref.read(editorProvider.notifier).upload();
                      }),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ref.watch(editorProvider).isUploading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_upload_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                  const SizedBox(width: 6),
                  Text(
                    ref.watch(editorProvider).isUploading
                        ? (ref.watch(editorProvider).uploadProgress > 0
                              ? 'Uploading ${(ref.watch(editorProvider).uploadProgress * 100).toInt()}%'
                              : 'Uploading...')
                        : 'Upload',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Split / Terminal toggle button
          InkWell(
            onTap:
                onOpenSerial ??
                () {
                  ref.read(editorProvider.notifier).toggleTerminal();
                },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ref.watch(editorProvider).isTerminalOpen
                    ? const Color(0xff223844)
                    : const Color(0xff182730),
                borderRadius: BorderRadius.circular(8),
                border: ref.watch(editorProvider).isTerminalOpen
                    ? Border.all(color: const Color(0xff00e5ff), width: 1)
                    : null,
              ),
              child: Icon(
                Icons.terminal_rounded,
                size: 18,
                color: ref.watch(editorProvider).isTerminalOpen
                    ? const Color(0xff00e5ff)
                    : const Color(0xff60758a),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Add file button
          InkWell(
            onTap:
                onAddFile ??
                () {
                  _showNewFileDialog(context, ref);
                },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xff182730),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                size: 20,
                color: Color(0xff60758a),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewFileDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: 'secrets.h');
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xff16222b),
        title: const Text(
          'New File',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'filename.ino or filename.h',
            hintStyle: TextStyle(color: Color(0xff60758a)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xff22d3ee)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xff60758a)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff00cbb8),
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(editorProvider.notifier).addNewFile(name);
              }
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
