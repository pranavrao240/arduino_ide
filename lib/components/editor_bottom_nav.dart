import 'package:arduino_ide/controllers/editor_controller.dart';
import 'package:arduino_ide/providers/editor_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditorBottomNav extends HookConsumerWidget {
  const EditorBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final selectedIndex = editorState.bottomNavIndex;

    final items = [
      const _NavItem(
        index: 0,
        label: 'Editor',
        icon: Icons.code_rounded,
      ),
      const _NavItem(
        index: 1,
        label: 'Files',
        icon: Icons.folder_outlined,
      ),
      const _NavItem(
        index: 2,
        label: 'Serial',
        icon: Icons.terminal_rounded,
        customIconText: '>_',
      ),
      const _NavItem(
        index: 3,
        label: 'Settings',
        icon: Icons.radio_button_checked_rounded,
      ),
    ];

    return Container(
      height: 56,
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
        children: items.map((item) {
          final isSelected = item.index == selectedIndex;
          final color = isSelected
              ? const Color(0xff00e5ff)
              : const Color(0xff60758a);

          return Expanded(
            child: InkWell(
              onTap: () {
                ref.read(editorProvider.notifier).selectNavIndex(item.index);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top indicator line for active item
                  if (isSelected)
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 44,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xff00e5ff),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 2),
                      if (item.customIconText != null)
                        Text(
                          item.customIconText!,
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            height: 1,
                          ),
                        )
                      else
                        Icon(
                          item.icon,
                          size: 20,
                          color: color,
                        ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.index,
    required this.label,
    required this.icon,
    this.customIconText,
  });

  final int index;
  final String label;
  final IconData icon;
  final String? customIconText;
}
