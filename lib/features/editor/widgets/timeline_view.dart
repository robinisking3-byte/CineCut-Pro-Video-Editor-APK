import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../controllers/editor_controller.dart';
import '../models/video_clip.dart';

class TimelineView extends StatelessWidget {
  final EditorController controller;

  const TimelineView({
    super.key,
    required this.controller,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$minutes:$seconds.$millis';
  }

  void _handlePickMedia(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            const uuid = Uuid();
            final newClip = VideoClip(
              id: uuid.v4(),
              name: file.name,
              videoPath: file.path!,
              isNetwork: false,
              originalDuration: const Duration(seconds: 10),
              startTime: Duration.zero,
              endTime: const Duration(seconds: 10),
              thumbnailColor: const Color(0xFF6366F1),
            );
            controller.addClip(newClip);
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${result.files.length} clip(s) to timeline!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      debugPrint('File picker note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File picker note: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSec = controller.totalDuration.inMilliseconds / 1000.0;
    final currentSec = controller.currentPosition.inMilliseconds / 1000.0;
    // Scale: pixels per second (min 20px/s, flexible)
    const pixelsPerSecond = 24.0;
    final timelineWidth = (totalSec * pixelsPerSecond).clamp(320.0, 5000.0);

    return Container(
      color: const Color(0xFF09090B),
      child: Column(
        children: [
          // 1. PLAYBACK CONTROLS STRIP (Play/Pause, Loop, Skip, Undo/Redo)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
            ),
            child: Row(
              children: [
                // Play / Pause
                IconButton(
                  icon: Icon(
                    controller.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: const Color(0xFFF59E0B),
                    size: 28,
                  ),
                  onPressed: controller.togglePlayPause,
                ),

                // Jump to Start
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 20),
                  onPressed: () => controller.seekTo(Duration.zero),
                  tooltip: 'Jump to Start',
                ),

                // Jump to End
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white70, size: 20),
                  onPressed: () => controller.seekTo(controller.totalDuration),
                  tooltip: 'Jump to End',
                ),

                // Loop toggle
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: controller.isLooping ? const Color(0xFFF59E0B) : Colors.white38,
                    size: 20,
                  ),
                  onPressed: controller.toggleLoop,
                  tooltip: 'Loop Playback',
                ),

                const Spacer(),

                // Timecode
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09090B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Text(
                    _formatDuration(controller.currentPosition),
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Undo
                IconButton(
                  icon: Icon(
                    Icons.undo,
                    color: controller.canUndo ? Colors.white70 : Colors.white24,
                    size: 20,
                  ),
                  onPressed: controller.canUndo ? controller.undo : null,
                  tooltip: 'Undo',
                ),

                // Redo
                IconButton(
                  icon: Icon(
                    Icons.redo,
                    color: controller.canRedo ? Colors.white70 : Colors.white24,
                    size: 20,
                  ),
                  onPressed: controller.canRedo ? controller.redo : null,
                  tooltip: 'Redo',
                ),
              ],
            ),
          ),

          // 2. SCROLLABLE TIMELINE TRACKS WITH RULER & PLAYHEAD
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: timelineWidth + 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Time Ruler Bar
                    SizedBox(
                      height: 24,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final tickIntervalSec = 2; // tick every 2s
                                final totalTicks = (totalSec / tickIntervalSec).ceil() + 2;

                                return Row(
                                  children: List.generate(totalTicks, (i) {
                                    final sec = i * tickIntervalSec;
                                    return SizedBox(
                                      width: tickIntervalSec * pixelsPerSecond,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(width: 1, height: 12, color: Colors.white30),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${sec}s',
                                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // B. Interactive Clip Blocks on Video Track
                    Expanded(
                      child: Stack(
                        children: [
                          // Sequential Clips
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...controller.clips.asMap().entries.map((entry) {
                                final index = entry.key;
                                final clip = entry.value;
                                final isSelected = index == controller.selectedClipIndex;
                                final clipSec = clip.effectiveDuration.inMilliseconds / 1000.0;
                                final blockWidth = (clipSec * pixelsPerSecond).clamp(64.0, 3000.0);

                                return GestureDetector(
                                  onTap: () => controller.selectClip(index),
                                  child: Container(
                                    width: blockWidth,
                                    margin: const EdgeInsets.only(right: 3),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF27272A)
                                          : const Color(0xFF18181B),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF3F3F46),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Stack(
                                        children: [
                                          // Background thumbnail color tint
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  clip.thumbnailColor.withOpacity(0.35),
                                                  const Color(0xFF18181B),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Clip Information
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.movie,
                                                      size: 14,
                                                      color: isSelected
                                                          ? const Color(0xFFF59E0B)
                                                          : Colors.white70,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        clip.name,
                                                        style: TextStyle(
                                                          color: isSelected
                                                              ? Colors.white
                                                              : Colors.white70,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Duration pill
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '${clipSec.toStringAsFixed(1)}s',
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 10,
                                                          fontFamily: 'monospace',
                                                        ),
                                                      ),
                                                    ),

                                                    // Filter Tag badge
                                                    if (clip.filter.type != FilterType.none)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(
                                                            color: const Color(0xFFF59E0B).withOpacity(0.5),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(clip.filter.icon, size: 10, color: const Color(0xFFF59E0B)),
                                                            const SizedBox(width: 2),
                                                            Text(
                                                              clip.filter.name,
                                                              style: const TextStyle(
                                                                color: Color(0xFFF59E0B),
                                                                fontSize: 9,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Left/Right Trim Handle Visual Indicators when selected
                                          if (isSelected) ...[
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              bottom: 0,
                                              width: 8,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFF59E0B),
                                                  borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.drag_indicator, size: 10, color: Colors.black),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              bottom: 0,
                                              width: 8,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFF59E0B),
                                                  borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.drag_indicator, size: 10, color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // Add clip "+" button at the end
                              Container(
                                width: 56,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18181B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF3F3F46), style: BorderStyle.solid),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _handlePickMedia(context),
                                  child: const Center(
                                    child: Icon(Icons.add, color: Color(0xFFF59E0B), size: 24),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // C. Draggable Scrubber Playhead Line
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: (currentSec * pixelsPerSecond).clamp(0.0, timelineWidth + 100),
                            child: GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                final newSec = currentSec + (details.delta.dx / pixelsPerSecond);
                                controller.seekTo(Duration(milliseconds: (newSec * 1000).round()));
                              },
                              child: Container(
                                width: 14,
                                transform: Matrix4.translationValues(-7, 0, 0),
                                color: Colors.transparent,
                                child: Column(
                                  children: [
                                    // Playhead Head indicator
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    // Vertical red line
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
