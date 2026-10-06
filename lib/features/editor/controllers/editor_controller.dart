import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';
import '../models/video_clip.dart';

class EditorHistoryState {
  final List<VideoClip> clips;
  final int selectedClipIndex;

  EditorHistoryState({
    required this.clips,
    required this.selectedClipIndex,
  });
}

class EditorController extends ChangeNotifier {
  static const _uuid = Uuid();

  // Project state
  String _projectTitle = 'Cinematic Master';
  AspectRatioPreset _aspectRatio = AspectRatioPreset.landscape16_9;
  List<VideoClip> _clips = [];
  int _selectedClipIndex = 0;

  // Global Timeline Playhead
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  bool _isLooping = false;
  bool _isMuted = false;

  // Video player controller for active clip preview
  VideoPlayerController? _videoPlayerController;
  bool _isPlayerInitialized = false;
  String? _currentPlayerPath;

  // History for Undo / Redo
  final List<EditorHistoryState> _undoStack = [];
  final List<EditorHistoryState> _redoStack = [];

  // Ticker timer for playback synchronization
  Timer? _playbackTimer;

  EditorController() {
    loadDemoClips();
  }

  // Getters
  String get projectTitle => _projectTitle;
  AspectRatioPreset get aspectRatio => _aspectRatio;
  List<VideoClip> get clips => List.unmodifiable(_clips);
  int get selectedClipIndex => _selectedClipIndex;
  Duration get currentPosition => _currentPosition;
  bool get isPlaying => _isPlaying;
  bool get isLooping => _isLooping;
  bool get isMuted => _isMuted;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  bool get isPlayerInitialized => _isPlayerInitialized;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  VideoClip? get selectedClip {
    if (_clips.isEmpty || _selectedClipIndex < 0 || _selectedClipIndex >= _clips.length) {
      return null;
    }
    return _clips[_selectedClipIndex];
  }

  Duration get totalDuration {
    if (_clips.isEmpty) return Duration.zero;
    return _clips.fold(Duration.zero, (total, clip) => total + clip.effectiveDuration);
  }

  void setProjectTitle(String title) {
    _projectTitle = title;
    notifyListeners();
  }

  void setAspectRatio(AspectRatioPreset ratio) {
    _aspectRatio = ratio;
    notifyListeners();
  }

  void selectClip(int index) {
    if (index >= 0 && index < _clips.length) {
      _selectedClipIndex = index;
      _updatePlayerForSelectedClip();
      notifyListeners();
    }
  }

  // ==========================================
  // CLIP LOADING & SAMPLES
  // ==========================================

  void loadDemoClips() {
    _recordHistory();
    _clips = [
      VideoClip(
        id: _uuid.v4(),
        name: 'Scene 1 - Sunset Horizon',
        videoPath: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        isNetwork: true,
        originalDuration: const Duration(seconds: 15),
        startTime: const Duration(seconds: 1),
        endTime: const Duration(seconds: 9),
        filter: VisualFilter.none,
        thumbnailColor: const Color(0xFFF59E0B),
      ),
      VideoClip(
        id: _uuid.v4(),
        name: 'Scene 2 - Urban Cyberpunk',
        videoPath: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        isNetwork: true,
        originalDuration: const Duration(seconds: 15),
        startTime: const Duration(seconds: 2),
        endTime: const Duration(seconds: 8),
        filter: VisualFilter.cool,
        thumbnailColor: const Color(0xFF3B82F6),
      ),
      VideoClip(
        id: _uuid.v4(),
        name: 'Scene 3 - Classic Cinema',
        videoPath: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        isNetwork: true,
        originalDuration: const Duration(seconds: 15),
        startTime: const Duration(seconds: 0),
        endTime: const Duration(seconds: 6),
        filter: VisualFilter.sepia,
        thumbnailColor: const Color(0xFF10B981),
      ),
    ];
    _selectedClipIndex = 0;
    _currentPosition = Duration.zero;
    _updatePlayerForSelectedClip();
    notifyListeners();
  }

  void addClip(VideoClip clip) {
    _recordHistory();
    _clips.add(clip);
    _selectedClipIndex = _clips.length - 1;
    _updatePlayerForSelectedClip();
    notifyListeners();
  }

  void duplicateSelectedClip() {
    final clip = selectedClip;
    if (clip == null) return;
    _recordHistory();

    final duplicated = clip.copyWith(
      id: _uuid.v4(),
      name: '${clip.name} (Copy)',
    );

    _clips.insert(_selectedClipIndex + 1, duplicated);
    _selectedClipIndex += 1;
    _updatePlayerForSelectedClip();
    notifyListeners();
  }

  void deleteSelectedClip() {
    if (_clips.isEmpty) return;
    _recordHistory();

    _clips.removeAt(_selectedClipIndex);
    if (_selectedClipIndex >= _clips.length) {
      _selectedClipIndex = _clips.length - 1;
    }

    if (_clips.isNotEmpty) {
      _updatePlayerForSelectedClip();
    } else {
      _disposePlayer();
    }
    notifyListeners();
  }

  // ==========================================
  // CORE OPERATION 1: TRIMMING
  // ==========================================

  /// Trims the currently selected clip to new start & end time offsets
  bool trimSelectedClip(Duration newStartTime, Duration newEndTime) {
    final clip = selectedClip;
    if (clip == null) return false;

    // Validate bounds
    if (newStartTime < Duration.zero) newStartTime = Duration.zero;
    if (newEndTime > clip.originalDuration) newEndTime = clip.originalDuration;
    if (newEndTime <= newStartTime) {
      // Must have at least 200ms duration
      newEndTime = newStartTime + const Duration(milliseconds: 200);
      if (newEndTime > clip.originalDuration) {
        newStartTime = clip.originalDuration - const Duration(milliseconds: 200);
      }
    }

    _recordHistory();
    _clips[_selectedClipIndex] = clip.copyWith(
      startTime: newStartTime,
      endTime: newEndTime,
    );

    // Seek player to trim start for instant preview verification
    _seekLocalClip(newStartTime);
    notifyListeners();
    return true;
  }

  /// Sets trim in-point to the current relative playhead position
  void setTrimStartAtPlayhead() {
    final clip = selectedClip;
    if (clip == null) return;

    final localPos = _getLocalPositionForClip(_selectedClipIndex, _currentPosition);
    final absoluteOffset = clip.startTime + localPos;

    if (absoluteOffset < clip.endTime - const Duration(milliseconds: 300)) {
      trimSelectedClip(absoluteOffset, clip.endTime);
    }
  }

  /// Sets trim out-point to the current relative playhead position
  void setTrimEndAtPlayhead() {
    final clip = selectedClip;
    if (clip == null) return;

    final localPos = _getLocalPositionForClip(_selectedClipIndex, _currentPosition);
    final absoluteOffset = clip.startTime + localPos;

    if (absoluteOffset > clip.startTime + const Duration(milliseconds: 300)) {
      trimSelectedClip(clip.startTime, absoluteOffset);
    }
  }

  // ==========================================
  // CORE OPERATION 2: SPLITTING
  // ==========================================

  /// Splits the selected clip at the current playhead position into two segments
  bool splitSelectedClipAtPlayhead() {
    final clip = selectedClip;
    if (clip == null) return false;

    final localPos = _getLocalPositionForClip(_selectedClipIndex, _currentPosition);

    // Validate that split is inside the clip bounds with at least 300ms on each side
    const minPadding = Duration(milliseconds: 300);
    if (localPos < minPadding || localPos > (clip.effectiveDuration - minPadding)) {
      return false;
    }

    final splitPoint = clip.startTime + localPos;
    return splitClipAtOffset(_selectedClipIndex, splitPoint);
  }

  /// Splits a clip at a given absolute timestamp within original duration
  bool splitClipAtOffset(int clipIndex, Duration splitPoint) {
    if (clipIndex < 0 || clipIndex >= _clips.length) return false;
    final original = _clips[clipIndex];

    if (splitPoint <= original.startTime || splitPoint >= original.endTime) {
      return false;
    }

    _recordHistory();

    // Segment A: from original.startTime to splitPoint
    final partA = original.copyWith(
      id: _uuid.v4(),
      name: '${original.name} [Part 1]',
      endTime: splitPoint,
    );

    // Segment B: from splitPoint to original.endTime
    final partB = original.copyWith(
      id: _uuid.v4(),
      name: '${original.name} [Part 2]',
      startTime: splitPoint,
    );

    // Replace original with Part A and Part B
    _clips.removeAt(clipIndex);
    _clips.insert(clipIndex, partA);
    _clips.insert(clipIndex + 1, partB);

    _selectedClipIndex = clipIndex;
    _updatePlayerForSelectedClip();
    notifyListeners();
    return true;
  }

  // ==========================================
  // CORE OPERATION 3: MERGING
  // ==========================================

  /// Merges the selected clip with the next adjacent clip if possible
  bool mergeSelectedWithNext() {
    if (_clips.length < 2 || _selectedClipIndex >= _clips.length - 1) {
      return false;
    }

    final clip1 = _clips[_selectedClipIndex];
    final clip2 = _clips[_selectedClipIndex + 1];

    _recordHistory();

    // If both originate from the same video file and are contiguous, merge seamlessly
    if (clip1.videoPath == clip2.videoPath &&
        clip1.endTime == clip2.startTime) {
      final merged = clip1.copyWith(
        id: _uuid.v4(),
        name: clip1.name.replaceAll(RegExp(r'\[Part \d+\]'), '').trim(),
        endTime: clip2.endTime,
      );
      _clips.removeAt(_selectedClipIndex + 1);
      _clips[_selectedClipIndex] = merged;
    } else {
      // Cross-source or non-contiguous merge
      // Creates a combined representation preserving overall effective duration
      final combinedDuration = clip1.effectiveDuration + clip2.effectiveDuration;
      final merged = VideoClip(
        id: _uuid.v4(),
        name: '${clip1.name} + ${clip2.name}',
        videoPath: clip1.videoPath,
        isNetwork: clip1.isNetwork,
        originalDuration: combinedDuration,
        startTime: Duration.zero,
        endTime: combinedDuration,
        filter: clip1.filter,
        thumbnailColor: clip1.thumbnailColor,
      );
      _clips.removeAt(_selectedClipIndex + 1);
      _clips[_selectedClipIndex] = merged;
    }

    _updatePlayerForSelectedClip();
    notifyListeners();
    return true;
  }

  /// Merges all clips on the timeline into sequential chapters / unified sequence
  void mergeAllClips() {
    if (_clips.length <= 1) return;
    _recordHistory();

    final total = totalDuration;
    final first = _clips.first;

    final masterClip = VideoClip(
      id: _uuid.v4(),
      name: 'Merged Sequence (${_clips.length} Clips)',
      videoPath: first.videoPath,
      isNetwork: first.isNetwork,
      originalDuration: total,
      startTime: Duration.zero,
      endTime: total,
      filter: first.filter,
      thumbnailColor: const Color(0xFFF59E0B),
    );

    _clips = [masterClip];
    _selectedClipIndex = 0;
    _currentPosition = Duration.zero;
    _updatePlayerForSelectedClip();
    notifyListeners();
  }

  /// Reorders clips on timeline
  void reorderClips(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _clips.length || newIndex < 0 || newIndex > _clips.length) {
      return;
    }
    _recordHistory();

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final clip = _clips.removeAt(oldIndex);
    _clips.insert(newIndex, clip);
    _selectedClipIndex = newIndex;
    notifyListeners();
  }

  // ==========================================
  // CORE OPERATION 4: VISUAL FILTERS
  // ==========================================

  /// Applies a visual filter to the selected clip
  void setFilterForSelectedClip(VisualFilter filter, {double intensity = 1.0}) {
    final clip = selectedClip;
    if (clip == null) return;

    _recordHistory();
    _clips[_selectedClipIndex] = clip.copyWith(
      filter: filter,
      filterIntensity: intensity.clamp(0.0, 1.0),
    );
    notifyListeners();
  }

  /// Applies a visual filter across ALL clips in the timeline with 1 click
  void applyFilterToAllClips(VisualFilter filter, {double intensity = 1.0}) {
    if (_clips.isEmpty) return;
    _recordHistory();

    for (int i = 0; i < _clips.length; i++) {
      _clips[i] = _clips[i].copyWith(
        filter: filter,
        filterIntensity: intensity.clamp(0.0, 1.0),
      );
    }
    notifyListeners();
  }

  void setClipSpeed(double speed) {
    final clip = selectedClip;
    if (clip == null) return;
    _recordHistory();

    _clips[_selectedClipIndex] = clip.copyWith(speed: speed);
    _videoPlayerController?.setPlaybackSpeed(speed);
    notifyListeners();
  }

  void setClipVolume(double volume) {
    final clip = selectedClip;
    if (clip == null) return;
    _recordHistory();

    _clips[_selectedClipIndex] = clip.copyWith(volume: volume);
    _videoPlayerController?.setVolume(_isMuted ? 0.0 : volume);
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    final clip = selectedClip;
    if (clip != null) {
      _videoPlayerController?.setVolume(_isMuted ? 0.0 : clip.volume);
    }
    notifyListeners();
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  // ==========================================
  // UNDO / REDO SYSTEM
  // ==========================================

  void _recordHistory() {
    _undoStack.add(EditorHistoryState(
      clips: _clips.map((c) => c.copyWith()).toList(),
      selectedClipIndex: _selectedClipIndex,
    ));
    if (_undoStack.length > 30) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;

    _redoStack.add(EditorHistoryState(
      clips: _clips.map((c) => c.copyWith()).toList(),
      selectedClipIndex: _selectedClipIndex,
    ));

    final prevState = _undoStack.removeLast();
    _clips = prevState.clips;
    _selectedClipIndex = prevState.selectedClipIndex.clamp(0, _clips.isEmpty ? 0 : _clips.length - 1);
    _updatePlayerForSelectedClip();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;

    _undoStack.add(EditorHistoryState(
      clips: _clips.map((c) => c.copyWith()).toList(),
      selectedClipIndex: _selectedClipIndex,
    ));

    final nextState = _redoStack.removeLast();
    _clips = nextState.clips;
    _selectedClipIndex = nextState.selectedClipIndex.clamp(0, _clips.isEmpty ? 0 : _clips.length - 1);
    _updatePlayerForSelectedClip();
    notifyListeners();
  }

  // ==========================================
  // TIMELINE & PLAYBACK CONTROLLER
  // ==========================================

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (_clips.isEmpty) return;
    _isPlaying = true;
    _videoPlayerController?.play();
    _startPlaybackTimer();
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    _videoPlayerController?.pause();
    _playbackTimer?.cancel();
    notifyListeners();
  }

  void seekTo(Duration position) {
    if (position < Duration.zero) position = Duration.zero;
    final total = totalDuration;
    if (position > total) position = total;

    _currentPosition = position;

    // Determine which clip corresponds to this global position
    final targetClipIndex = _findClipIndexAtPosition(position);
    if (targetClipIndex != _selectedClipIndex && targetClipIndex >= 0) {
      _selectedClipIndex = targetClipIndex;
      _updatePlayerForSelectedClip(seekAfterInit: true);
    } else if (selectedClip != null) {
      final localPos = _getLocalPositionForClip(_selectedClipIndex, position);
      _seekLocalClip(selectedClip!.startTime + localPos);
    }

    notifyListeners();
  }

  int _findClipIndexAtPosition(Duration position) {
    Duration accumulated = Duration.zero;
    for (int i = 0; i < _clips.length; i++) {
      final clipDuration = _clips[i].effectiveDuration;
      if (position <= (accumulated + clipDuration)) {
        return i;
      }
      accumulated += clipDuration;
    }
    return _clips.isEmpty ? 0 : _clips.length - 1;
  }

  Duration _getLocalPositionForClip(int clipIndex, Duration globalPosition) {
    Duration accumulated = Duration.zero;
    for (int i = 0; i < clipIndex; i++) {
      accumulated += _clips[i].effectiveDuration;
    }
    final local = globalPosition - accumulated;
    return local.isNegative ? Duration.zero : local;
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_isPlaying || _clips.isEmpty) {
        timer.cancel();
        return;
      }

      final nextPos = _currentPosition + const Duration(milliseconds: 33);
      final total = totalDuration;

      if (nextPos >= total) {
        if (_isLooping) {
          seekTo(Duration.zero);
        } else {
          pause();
          seekTo(total);
        }
      } else {
        _currentPosition = nextPos;
        final targetIndex = _findClipIndexAtPosition(nextPos);
        if (targetIndex != _selectedClipIndex) {
          _selectedClipIndex = targetIndex;
          _updatePlayerForSelectedClip(autoPlay: true);
        }
        notifyListeners();
      }
    });
  }

  void _seekLocalClip(Duration time) {
    _videoPlayerController?.seekTo(time);
  }

  // ==========================================
  // VIDEO PLAYER INITIALIZATION
  // ==========================================

  Future<void> _updatePlayerForSelectedClip({bool autoPlay = false, bool seekAfterInit = false}) async {
    final clip = selectedClip;
    if (clip == null) return;

    if (_currentPlayerPath == clip.videoPath && _videoPlayerController != null) {
      // Same video source, seek to appropriate trim position
      final localPos = _getLocalPositionForClip(_selectedClipIndex, _currentPosition);
      await _videoPlayerController!.seekTo(clip.startTime + localPos);
      if (autoPlay || _isPlaying) {
        _videoPlayerController!.play();
      }
      return;
    }

    _currentPlayerPath = clip.videoPath;
    _isPlayerInitialized = false;
    notifyListeners();

    await _videoPlayerController?.dispose();

    try {
      if (clip.isNetwork) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(clip.videoPath));
      } else {
        // Local asset / file fallback
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(clip.videoPath));
      }

      await _videoPlayerController!.initialize();
      _isPlayerInitialized = true;
      _videoPlayerController!.setVolume(_isMuted ? 0.0 : clip.volume);
      _videoPlayerController!.setPlaybackSpeed(clip.speed);

      final localPos = _getLocalPositionForClip(_selectedClipIndex, _currentPosition);
      await _videoPlayerController!.seekTo(clip.startTime + localPos);

      if (autoPlay || _isPlaying) {
        _videoPlayerController!.play();
      }
    } catch (e) {
      debugPrint('VideoPlayer init warning: $e');
      _isPlayerInitialized = true; // allow UI fallback to render gracefully
    }

    notifyListeners();
  }

  void _disposePlayer() {
    _playbackTimer?.cancel();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _isPlayerInitialized = false;
    _currentPlayerPath = null;
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
