import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../controllers/editor_controller.dart';
import '../models/video_clip.dart';

class VideoViewport extends StatelessWidget {
  final EditorController controller;

  const VideoViewport({
    super.key,
    required this.controller,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$minutes:$seconds.$millis';
  }

  @override
  Widget build(BuildContext context) {
    final clip = controller.selectedClip;
    final ratio = controller.aspectRatio.ratio;

    return Container(
      color: const Color(0xFF000000),
      child: Center(
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. VIDEO PLAYER OR GRAPHICAL PREVIEW
              if (clip != null &&
                  controller.videoPlayerController != null &&
                  controller.isPlayerInitialized &&
                  controller.videoPlayerController!.value.isInitialized)
                // Real-Time GPU ColorFilter on video frame!
                ColorFiltered(
                  colorFilter: ColorFilter.matrix(clip.filter.matrix),
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.videoPlayerController!.value.size.width,
                        height: controller.videoPlayerController!.value.size.height,
                        child: VideoPlayer(controller.videoPlayerController!),
                      ),
                    ),
                  ),
                )
              else
                // Stylized Fallback Preview Canvas when loading or offline
                ColorFiltered(
                  colorFilter: ColorFilter.matrix(clip?.filter.matrix ?? VisualFilter.none.matrix),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          clip?.thumbnailColor.withOpacity(0.85) ?? const Color(0xFF1E1B4B),
                          const Color(0xFF09090B),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            clip != null ? Icons.videocam : Icons.video_library_outlined,
                            size: 48,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            clip?.name ?? 'No Clip Selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clip != null
                                ? 'Filter: ${clip.filter.name} • Speed: ${clip.speed}x'
                                : 'Tap + to import footage or load demo clips',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 2. TAP-TO-PLAY GESTURE OVERLAY
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: controller.togglePlayPause,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: controller.isPlaying ? 0.0 : 0.85,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 42,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. TOP INFO OVERLAY (Aspect Ratio badge, Filter badge)
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.aspect_ratio, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            controller.aspectRatio.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (clip != null && clip.filter.type != FilterType.none) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(clip.filter.icon, size: 13, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              clip.filter.name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 4. BOTTOM TIMECODE BAR OVERLAY
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        '${_formatDuration(controller.currentPosition)} / ${_formatDuration(controller.totalDuration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    if (clip != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          'Clip ${controller.selectedClipIndex + 1}/${controller.clips.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
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
    );
  }
}
