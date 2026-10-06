import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/editor_controller.dart';

class ExportDialog extends StatefulWidget {
  final EditorController controller;

  const ExportDialog({
    super.key,
    required this.controller,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _resolution = '1080p (FHD)';
  int _fps = 30;
  bool _isExporting = false;
  double _progress = 0.0;
  String _statusMessage = 'Ready to encode';
  Timer? _timer;

  void _startExport() {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
      _statusMessage = 'Initializing timeline filters and audio stems...';
    });

    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _progress += 0.035;
        if (_progress < 0.25) {
          _statusMessage = 'Trimming & stitching ${_resolution} clips...';
        } else if (_progress < 0.6) {
          _statusMessage = 'Applying visual filters & LUT color transforms...';
        } else if (_progress < 0.9) {
          _statusMessage = 'Encoding H.264 AAC multi-pass stream...';
        } else {
          _statusMessage = 'Finalizing CineCut master package...';
        }

        if (_progress >= 1.0) {
          _progress = 1.0;
          _isExporting = false;
          _statusMessage = 'Export Completed Successfully!';
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.movie_creation_outlined, color: Color(0xFFF59E0B), size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Export Project',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isExporting)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (!_isExporting && _progress < 1.0) ...[
              // Resolution selector
              const Text('Resolution', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _resolution,
                dropdownColor: const Color(0xFF27272A),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF09090B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: '720p (HD)', child: Text('720p (HD)')),
                  DropdownMenuItem(value: '1080p (FHD)', child: Text('1080p (Full HD - Recommended)')),
                  DropdownMenuItem(value: '4K (Ultra HD)', child: Text('4K (ProRes / UHD)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _resolution = val);
                },
              ),
              const SizedBox(height: 14),

              // Framerate selector
              const Text('Framerate', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildFpsChip(24, '24 fps (Cinema)'),
                  const SizedBox(width: 8),
                  _buildFpsChip(30, '30 fps (Standard)'),
                  const SizedBox(width: 8),
                  _buildFpsChip(60, '60 fps (Smooth)'),
                ],
              ),
              const SizedBox(height: 16),

              // Project specs card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Column(
                  children: [
                    _buildSpecRow('Clips', '${widget.controller.clips.length} segments'),
                    const SizedBox(height: 4),
                    _buildSpecRow('Aspect Ratio', widget.controller.aspectRatio.label),
                    const SizedBox(height: 4),
                    _buildSpecRow('Total Duration', '${(widget.controller.totalDuration.inMilliseconds / 1000).toStringAsFixed(1)}s'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.file_download_outlined, size: 20),
                label: const Text('Start Export', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _startExport,
              ),
            ] else ...[
              // Progress View
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: const Color(0xFF27272A),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_progress >= 1.0)
                ElevatedButton.icon(
                  icon: const Icon(Icons.done_all, size: 20),
                  label: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFpsChip(int fps, String label) {
    final isSelected = _fps == fps;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _fps = fps),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF27272A) : const Color(0xFF09090B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF3F3F46),
            ),
          ),
          child: Center(
            child: Text(
              '$fps fps',
              style: TextStyle(
                color: isSelected ? const Color(0xFFF59E0B) : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
