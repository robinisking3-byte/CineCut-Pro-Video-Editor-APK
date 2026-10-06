import 'package:flutter/material.dart';
import '../controllers/editor_controller.dart';
import '../models/video_clip.dart';

class FilterSelectorSheet extends StatefulWidget {
  final EditorController controller;

  const FilterSelectorSheet({
    super.key,
    required this.controller,
  });

  @override
  State<FilterSelectorSheet> createState() => _FilterSelectorSheetState();
}

class _FilterSelectorSheetState extends State<FilterSelectorSheet> {
  late VisualFilter _selectedFilter;
  late double _intensity;
  late VideoClip _clip;

  @override
  void initState() {
    super.initState();
    _clip = widget.controller.selectedClip!;
    _selectedFilter = _clip.filter;
    _intensity = _clip.filterIntensity;
  }

  void _applyToSelected() {
    widget.controller.setFilterForSelectedClip(_selectedFilter, intensity: _intensity);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied "${_selectedFilter.name}" to ${_clip.name}'),
        backgroundColor: const Color(0xFFF59E0B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applyToAll() {
    widget.controller.applyFilterToAllClips(_selectedFilter, intensity: _intensity);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied "${_selectedFilter.name}" to all ${widget.controller.clips.length} clips'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.palette_outlined, color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visual Filters & Color Grading',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Active: ${_clip.name}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Selection Carousel
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: VisualFilter.allFilters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final filter = VisualFilter.allFilters[index];
                final isSelected = filter.type == _selectedFilter.type;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    // Instant live preview
                    widget.controller.setFilterForSelectedClip(filter, intensity: _intensity);
                  },
                  child: Container(
                    width: 88,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF27272A) : const Color(0xFF09090B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF3F3F46),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Live Filtered thumbnail swatch
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(filter.matrix),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _clip.thumbnailColor,
                                  const Color(0xFFEC4899),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(filter.icon, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          filter.name,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFF59E0B) : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Filter Description Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF09090B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Row(
              children: [
                Icon(_selectedFilter.icon, size: 16, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFilter.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Intensity Slider
          Row(
            children: [
              const Text('Intensity', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Text(
                '${(_intensity * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Slider(
            value: _intensity,
            min: 0.1,
            max: 1.0,
            activeColor: const Color(0xFFF59E0B),
            inactiveColor: const Color(0xFF27272A),
            onChanged: (val) {
              setState(() => _intensity = val);
              widget.controller.setFilterForSelectedClip(_selectedFilter, intensity: val);
            },
          ),

          const SizedBox(height: 16),

          // Dual Action Buttons: Apply to Selected vs Apply to All Clips
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF3F3F46)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _applyToAll,
                  child: const Text('Apply to All Clips', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _applyToSelected,
                  child: const Text(
                    'Apply Filter',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
