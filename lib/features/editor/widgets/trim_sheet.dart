import 'package:flutter/material.dart';
import '../controllers/editor_controller.dart';
import '../models/video_clip.dart';

class TrimSheet extends StatefulWidget {
  final EditorController controller;

  const TrimSheet({
    super.key,
    required this.controller,
  });

  @override
  State<TrimSheet> createState() => _TrimSheetState();
}

class _TrimSheetState extends State<TrimSheet> {
  late double _startSeconds;
  late double _endSeconds;
  late double _maxSeconds;
  late VideoClip _clip;

  @override
  void initState() {
    super.initState();
    _clip = widget.controller.selectedClip!;
    _maxSeconds = _clip.originalDuration.inMilliseconds / 1000.0;
    _startSeconds = _clip.startTime.inMilliseconds / 1000.0;
    _endSeconds = _clip.endTime.inMilliseconds / 1000.0;
  }

  String _formatTime(double sec) {
    final d = Duration(milliseconds: (sec * 1000).round());
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$minutes:$seconds.$millis';
  }

  void _applyTrim() {
    final newStart = Duration(milliseconds: (_startSeconds * 1000).round());
    final newEnd = Duration(milliseconds: (_endSeconds * 1000).round());
    widget.controller.trimSelectedClip(newStart, newEnd);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trim applied to ${_clip.name}'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedDuration = _endSeconds - _startSeconds;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFF27272A), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.content_cut, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Trim: ${_clip.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Duration summary badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF09090B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('In-Point', _formatTime(_startSeconds), const Color(0xFF38BDF8)),
                Container(width: 1, height: 28, color: Colors.white12),
                _buildInfoColumn('Out-Point', _formatTime(_endSeconds), const Color(0xFFF43F5E)),
                Container(width: 1, height: 28, color: Colors.white12),
                _buildInfoColumn('Trimmed Length', _formatTime(trimmedDuration), const Color(0xFFF59E0B)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Visual Filmstrip & Range Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filmstrip visual representation
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3F3F46)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Film perforations & frames simulation
                      Row(
                        children: List.generate(
                          10,
                          (i) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _clip.thumbnailColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Icon(Icons.movie_outlined, size: 16, color: Colors.white.withOpacity(0.15)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Highlighted active trim segment
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final left = (_startSeconds / _maxSeconds) * w;
                            final right = w - ((_endSeconds / _maxSeconds) * w);

                            return Padding(
                              padding: EdgeInsets.only(left: left, right: right),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.35),
                                  border: Border.symmetric(
                                    vertical: const BorderSide(color: Color(0xFFF59E0B), width: 3),
                                    horizontal: BorderSide(color: const Color(0xFFF59E0B).withOpacity(0.7), width: 1.5),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Interactive Range Slider
              RangeSlider(
                values: RangeValues(_startSeconds, _endSeconds),
                min: 0.0,
                max: _maxSeconds > 0 ? _maxSeconds : 1.0,
                activeColor: const Color(0xFFF59E0B),
                inactiveColor: const Color(0xFF27272A),
                divisions: (_maxSeconds * 10).round() > 0 ? (_maxSeconds * 10).round() : 1,
                labels: RangeLabels(
                  _formatTime(_startSeconds),
                  _formatTime(_endSeconds),
                ),
                onChanged: (RangeValues values) {
                  // Ensure minimum duration of 0.3 seconds
                  if (values.end - values.start >= 0.3) {
                    setState(() {
                      _startSeconds = values.start;
                      _endSeconds = values.end;
                    });
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick Action Shortcuts: Set to Playhead, Reset
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('Start at Playhead', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF3F3F46)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    final playheadSec = widget.controller.currentPosition.inMilliseconds / 1000.0;
                    if (playheadSec < _endSeconds - 0.3 && playheadSec >= 0) {
                      setState(() => _startSeconds = playheadSec);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('Reset', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF3F3F46)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      _startSeconds = 0.0;
                      _endSeconds = _maxSeconds;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Apply button
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 20),
            label: const Text(
              'Apply Trim',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _applyTrim,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
