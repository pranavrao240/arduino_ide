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

          // Verify Button
          InkWell(
            onTap: onVerify ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compiling sketch... Done compiling!'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Color(0xff162832),
                    ),
                  );
                },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xff182730),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xff223844),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check,
                    size: 17,
                    color: Color(0xff22d3ee),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Verify',
                    style: TextStyle(
                      color: Color(0xff22d3ee),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Upload Button
          InkWell(
            onTap: onUpload ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Uploading to Arduino Uno on /dev/ttyUSB0... Done!'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Color(0xff00cbb8),
                    ),
                  );
                },
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Upload',
                    style: TextStyle(
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

          // Split / Serial button
          InkWell(
            onTap: onOpenSerial ??
                () {
                  ref.read(editorProvider.notifier).selectNavIndex(2);
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
                Icons.calendar_view_week_rounded,
                size: 18,
                color: Color(0xff60758a),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Add file button
          InkWell(
            onTap: onAddFile ??
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
            child: const Text('Cancel', style: TextStyle(color: Color(0xff60758a))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff00cbb8)),
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
