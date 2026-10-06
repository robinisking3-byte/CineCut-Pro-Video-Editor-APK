import 'package:flutter/material.dart';
import 'controllers/editor_controller.dart';
import 'models/video_clip.dart';
import 'widgets/video_viewport.dart';
import 'widgets/clip_tools_bar.dart';
import 'widgets/timeline_view.dart';
import 'widgets/export_dialog.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditorController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAspectRatioMenu() {
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
                Icon(Icons.aspect_ratio, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text(
                  'Canvas Aspect Ratio',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...AspectRatioPreset.values.map((preset) {
              final isSelected = _controller.aspectRatio == preset;
              return ListTile(
                title: Text(preset.label, style: TextStyle(color: isSelected ? const Color(0xFFF59E0B) : Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(preset.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFF59E0B)) : null,
                onTap: () {
                  _controller.setAspectRatio(preset);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (_) => ExportDialog(controller: _controller),
    );
  }

  void _editProjectTitle() {
    final textCtrl = TextEditingController(text: _controller.projectTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Rename Project', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter project title',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF09090B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
            child: const Text('Save'),
            onPressed: () {
              if (textCtrl.text.trim().isNotEmpty) {
                _controller.setProjectTitle(textCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: const Color(0xFF09090B),
          appBar: AppBar(
            backgroundColor: const Color(0xFF09090B),
            elevation: 0,
            titleSpacing: 12,
            title: InkWell(
              onTap: _editProjectTitle,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _controller.projectTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 14, color: Colors.white38),
                ],
              ),
            ),
            actions: [
              // Aspect ratio button
              TextButton.icon(
                icon: const Icon(Icons.crop, size: 16, color: Color(0xFFF59E0B)),
                label: Text(
                  _controller.aspectRatio.label,
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: _showAspectRatioMenu,
              ),

              const SizedBox(width: 6),

              // Reload demo samples button
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: Colors.white70),
                tooltip: 'Reset to Sample Clips',
                onPressed: () {
                  _controller.loadDemoClips();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sample project clips loaded!'),
                      backgroundColor: Color(0xFFF59E0B),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

              // Export Button
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                  label: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showExportDialog,
                ),
              ),
            ],
          ),
          body: isLandscape
              ? _buildLandscapeLayout()
              : _buildPortraitLayout(),
        );
      },
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // 1. VIDEO VIEWPORT (Canvas preview with real-time filters)
        Expanded(
          flex: 5,
          child: VideoViewport(controller: _controller),
        ),

        // 2. QUICK ACTIONS TOOLBAR (Split, Trim, Filters, Merge, Speed, etc.)
        ClipToolsBar(controller: _controller),

        // 3. MULTI-SEGMENT TIMELINE (Time ruler, scrubber, clips)
        Expanded(
          flex: 4,
          child: TimelineView(controller: _controller),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Viewport on left side in landscape
        Expanded(
          flex: 6,
          child: VideoViewport(controller: _controller),
        ),
        // Toolbar and Timeline on right side
        Expanded(
          flex: 5,
          child: Column(
            children: [
              ClipToolsBar(controller: _controller),
              Expanded(
                child: TimelineView(controller: _controller),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
