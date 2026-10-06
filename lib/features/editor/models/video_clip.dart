import 'dart:ui';
import 'package:flutter/material.dart';

enum FilterType {
  none,
  grayscale,
  sepia,
  vintage,
  vivid,
  cool,
  warm,
  noir,
  invert,
}

class VisualFilter {
  final FilterType type;
  final String name;
  final String description;
  final IconData icon;
  final List<double> matrix;
  final String ffmpegFilter;

  const VisualFilter({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.matrix,
    required this.ffmpegFilter,
  });

  static const VisualFilter none = VisualFilter(
    type: FilterType.none,
    name: 'Normal',
    description: 'Original colors without filter',
    icon: Icons.filter_none,
    matrix: [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ],
    ffmpegFilter: 'null',
  );

  static const VisualFilter grayscale = VisualFilter(
    type: FilterType.grayscale,
    name: 'B & W',
    description: 'Classic monochrome black and white',
    icon: Icons.monochrome_photos,
    matrix: [
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ],
    ffmpegFilter: 'hue=s=0',
  );

  static const VisualFilter sepia = VisualFilter(
    type: FilterType.sepia,
    name: 'Sepia',
    description: 'Warm nostalgic vintage tone',
    icon: Icons.camera_roll,
    matrix: [
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0,     0,     0,     1, 0,
    ],
    ffmpegFilter: 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131',
  );

  static const VisualFilter vintage = VisualFilter(
    type: FilterType.vintage,
    name: 'Vintage 70s',
    description: 'Retro cinema film stock',
    icon: Icons.history_toggle_off,
    matrix: [
      0.9, 0.1, 0.1, 0, 20,
      0.1, 0.8, 0.1, 0, 10,
      0.1, 0.1, 0.6, 0, 5,
      0,   0,   0,   1, 0,
    ],
    ffmpegFilter: 'curves=vintage',
  );

  static const VisualFilter vivid = VisualFilter(
    type: FilterType.vivid,
    name: 'Vivid Pop',
    description: 'Enhanced color vibrancy & punch',
    icon: Icons.auto_awesome,
    matrix: [
      1.3,  -0.15, -0.15, 0, 0,
      -0.15, 1.3,  -0.15, 0, 0,
      -0.15, -0.15, 1.3,  0, 0,
      0,     0,     0,    1, 0,
    ],
    ffmpegFilter: 'eq=contrast=1.2:saturation=1.4',
  );

  static const VisualFilter cool = VisualFilter(
    type: FilterType.cool,
    name: 'Cool Cyan',
    description: 'Teal & sci-fi cinematic coolness',
    icon: Icons.ac_unit,
    matrix: [
      0.8, 0.1, 0.1, 0, 0,
      0.1, 1.1, 0.1, 0, 10,
      0.1, 0.1, 1.3, 0, 20,
      0,   0,   0,   1, 0,
    ],
    ffmpegFilter: 'colorbalance=rh=-0.1:gh=0.05:bh=0.2',
  );

  static const VisualFilter warm = VisualFilter(
    type: FilterType.warm,
    name: 'Golden Hour',
    description: 'Warm sunset amber glow',
    icon: Icons.wb_sunny,
    matrix: [
      1.2, 0.1, 0.0, 0, 15,
      0.0, 1.1, 0.0, 0, 8,
      0.0, 0.0, 0.8, 0, -10,
      0,   0,   0,   1, 0,
    ],
    ffmpegFilter: 'colorbalance=rh=0.2:gh=0.1:bh=-0.2',
  );

  static const VisualFilter noir = VisualFilter(
    type: FilterType.noir,
    name: 'Film Noir',
    description: 'Moody deep shadow contrast B&W',
    icon: Icons.contrast,
    matrix: [
      0.35, 0.85, 0.15, 0, -25,
      0.35, 0.85, 0.15, 0, -25,
      0.35, 0.85, 0.15, 0, -25,
      0,    0,    0,    1, 0,
    ],
    ffmpegFilter: 'hue=s=0,eq=contrast=1.5:brightness=-0.05',
  );

  static const VisualFilter invert = VisualFilter(
    type: FilterType.invert,
    name: 'Negative',
    description: 'Inverted color spectrum effect',
    icon: Icons.invert_colors,
    matrix: [
      -1,  0,  0, 0, 255,
       0, -1,  0, 0, 255,
       0,  0, -1, 0, 255,
       0,  0,  0, 1,   0,
    ],
    ffmpegFilter: 'negate',
  );

  static const List<VisualFilter> allFilters = [
    none,
    grayscale,
    sepia,
    vintage,
    vivid,
    cool,
    warm,
    noir,
    invert,
  ];

  static VisualFilter fromType(FilterType type) {
    return allFilters.firstWhere(
      (f) => f.type == type,
      orElse: () => none,
    );
  }
}

enum AspectRatioPreset {
  landscape16_9('16:9', 16 / 9, 'Landscape (YouTube)'),
  portrait9_16('9:16', 9 / 16, 'Portrait (Reels / Shorts)'),
  square1_1('1:1', 1.0, 'Square (Feed)'),
  standard4_3('4:3', 4 / 3, 'Standard TV'),
  cinematic21_9('21:9', 21 / 9, 'Cinemascope');

  final String label;
  final double ratio;
  final String description;

  const AspectRatioPreset(this.label, this.ratio, this.description);
}

class VideoClip {
  final String id;
  final String name;
  final String videoPath;
  final bool isNetwork;
  final Duration originalDuration;
  final Duration startTime; // Trim start
  final Duration endTime; // Trim end
  final VisualFilter filter;
  final double filterIntensity; // 0.0 to 1.0
  final double volume; // 0.0 to 1.0
  final double speed; // 0.5 to 2.0
  final Color thumbnailColor; // Visual placeholder color

  const VideoClip({
    required this.id,
    required this.name,
    required this.videoPath,
    this.isNetwork = false,
    required this.originalDuration,
    required this.startTime,
    required this.endTime,
    this.filter = VisualFilter.none,
    this.filterIntensity = 1.0,
    this.volume = 1.0,
    this.speed = 1.0,
    this.thumbnailColor = const Color(0xFFF59E0B),
  });

  /// Duration after trimming
  Duration get effectiveDuration {
    final diff = endTime - startTime;
    return diff.isNegative ? Duration.zero : diff;
  }

  VideoClip copyWith({
    String? id,
    String? name,
    String? videoPath,
    bool? isNetwork,
    Duration? originalDuration,
    Duration? startTime,
    Duration? endTime,
    VisualFilter? filter,
    double? filterIntensity,
    double? volume,
    double? speed,
    Color? thumbnailColor,
  }) {
    return VideoClip(
      id: id ?? this.id,
      name: name ?? this.name,
      videoPath: videoPath ?? this.videoPath,
      isNetwork: isNetwork ?? this.isNetwork,
      originalDuration: originalDuration ?? this.originalDuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      filter: filter ?? this.filter,
      filterIntensity: filterIntensity ?? this.filterIntensity,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      thumbnailColor: thumbnailColor ?? this.thumbnailColor,
    );
  }
}
