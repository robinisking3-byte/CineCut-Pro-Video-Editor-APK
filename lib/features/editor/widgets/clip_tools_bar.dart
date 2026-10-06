import 'package:flutter/material.dart';
import '../controllers/editor_controller.dart';
import 'trim_sheet.dart';
import 'filter_selector_sheet.dart';

class ClipToolsBar extends StatelessWidget {
  final EditorController controller;

  const ClipToolsBar({
    super.key,
    required this.controller,
  });

  void _showTrimSheet(BuildContext context) {
    if (controller.selectedClip == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrimSheet(controller: controller),
    );
  }

  void _showFilterSheet(BuildContext context) {
    if (controller.selectedClip == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSelectorSheet(controller: controller),
    );
  }

  void _handleSplit(BuildContext context) {
    final success = controller.splitSelectedClipAtPlayhead();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✂️ Clip split into two segments at playhead!'),
          backgroundColor: Color(0xFFF59E0B),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scrub the playhead inside the clip to split (at least 0.3s from edges).'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showMergeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF18181B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Color(0xFF27272A))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.merge_type, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text(
                  'Merge Video Clips',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF27272A),
                child: Icon(Icons.call_merge, color: Color(0xFFF59E0B)),
              ),
              title: const Text('Merge with Next Clip', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                controller.selectedClipIndex < controller.clips.length - 1
                    ? 'Combine current clip with "${controller.clips[controller.selectedClipIndex + 1].name}"'
                    : 'No subsequent clip to merge with',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              enabled: controller.selectedClipIndex < controller.clips.length - 1,
              onTap: () {
                Navigator.pop(ctx);
                final res = controller.mergeSelectedWithNext();
                if (res) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔗 Clips merged successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
            ),
            const Divider(color: Color(0xFF27272A)),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF27272A),
                child: Icon(Icons.auto_awesome_motion, color: Color(0xFF38BDF8)),
              ),
              title: const Text('Merge All Timeline Clips', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Consolidate all ${controller.clips.length} clips into one continuous master segment',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                controller.mergeAllClips();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✨ All timeline clips merged into single sequence!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedDialog(BuildContext context) {
    final clip = controller.selectedClip;
    if (clip == null) return;

    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Row(
          children: [
            Icon(Icons.speed, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Clip Speed', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds.map((speed) {
            final isSelected = (clip.speed - speed).abs() < 0.01;
            return ListTile(
              title: Text('${speed}x Speed', style: TextStyle(color: isSelected ? const Color(0xFFF59E0B) : Colors.white)),
              trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFF59E0B)) : null,
              onTap: () {
                controller.setClipSpeed(speed);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clip = controller.selectedClip;
    final hasClip = clip != null;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        border: Border(
          top: BorderSide(color: Color(0xFF27272A), width: 1),
          bottom: BorderSide(color: Color(0xFF27272A), width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 1. SPLIT (Cut at playhead)
          _buildActionButton(
            icon: Icons.content_cut,
            label: 'Split',
            color: const Color(0xFFF59E0B),
            enabled: hasClip,
            onTap: () => _handleSplit(context),
          ),

          // 2. TRIM (In/Out Trimmer)
          _buildActionButton(
            icon: Icons.crop,
            label: 'Trim',
            color: const Color(0xFF38BDF8),
            enabled: hasClip,
            onTap: () => _showTrimSheet(context),
          ),

          // 3. FILTERS (B&W, Sepia, etc.)
          _buildActionButton(
            icon: Icons.palette_outlined,
            label: 'Filters',
            badge: clip?.filter.name != 'Normal' ? clip?.filter.name : null,
            color: const Color(0xFFA855F7),
            enabled: hasClip,
            onTap: () => _showFilterSheet(context),
          ),

          // 4. MERGE (Join clips)
          _buildActionButton(
            icon: Icons.merge_type,
            label: 'Merge',
            color: const Color(0xFF10B981),
            enabled: controller.clips.length > 1,
            onTap: () => _showMergeOptions(context),
          ),

          // 5. SPEED
          _buildActionButton(
            icon: Icons.speed,
            label: '${clip?.speed ?? 1.0}x Speed',
            color: const Color(0xFFEC4899),
            enabled: hasClip,
            onTap: () => _showSpeedDialog(context),
          ),

          // 6. DUPLICATE
          _buildActionButton(
            icon: Icons.copy,
            label: 'Duplicate',
            color: Colors.white70,
            enabled: hasClip,
            onTap: () {
              controller.duplicateSelectedClip();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Clip duplicated!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          // 7. DELETE
          _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: const Color(0xFFEF4444),
            enabled: hasClip && controller.clips.length > 1,
            onTap: () {
              controller.deleteSelectedClip();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Clip removed from timeline'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    String? badge,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFF09090B) : const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: enabled ? const Color(0xFF27272A) : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: enabled ? color : Colors.white24,
                    ),
                    if (badge != null)
                      Positioned(
                        top: -4,
                        right: -10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
