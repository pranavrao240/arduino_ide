import 'package:arduino_ide/components/device_status_bar.dart';
import 'package:arduino_ide/components/editor_bottom_nav.dart';
import 'package:arduino_ide/components/editor_toolbar.dart';
import 'package:arduino_ide/controllers/editor_controller.dart';
import 'package:arduino_ide/providers/editor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FilesPage extends HookConsumerWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final files = editorState.files;
    final selectedIndex = editorState.selectedFileIndex;

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

              // 3. Section Title: SKETCHES
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Text(
                  'SKETCHES',
                  style: TextStyle(
                    color: Color(0xff60758a),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // 4. File List Area
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isSelected = index == selectedIndex;
                    final ext = file.extension.toLowerCase();
                    final isHeader = ext == 'h' || ext == 'hpp' || ext == 'c' || ext == 'cpp';

                    return Material(
                      color: isSelected ? const Color(0xff0e343c) : Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ref.read(editorProvider.notifier).selectFile(index);
                          ref.read(editorProvider.notifier).selectNavIndex(0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            border: isSelected
                                ? const Border(
                                    left: BorderSide(
                                      color: Color(0xff00e5ff),
                                      width: 3.5,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Extension Badge Box
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xff16252f),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '.${file.extension.isNotEmpty ? file.extension : 'ino'}',
                                  style: TextStyle(
                                    color: isHeader
                                        ? const Color(0xffec4899)
                                        : const Color(0xff00e5ff),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name & Metadata
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      file.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${file.displaySize} · ${file.displayModifiedTime}',
                                      style: const TextStyle(
                                        color: Color(0xff60758a),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Trailing Chevron Icon
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: Color(0xff60758a),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 5. Bottom Navigation Bar (from @components)
              const EditorBottomNav(),
            ],
          ),
        ),
      ),
    );
  }
}
