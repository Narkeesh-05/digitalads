import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:video_trimmer/video_trimmer.dart';

class VideoTrimScreen extends StatefulWidget {
  final File videoFile;
  final Duration maxDuration;

  const VideoTrimScreen({
    super.key,
    required this.videoFile,
    required this.maxDuration,
  });

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  static const Color whatsappGreen = Color(0xFF25D366);
  static const double _stripHeight = 72;
  static const double _horizontalPadding = 16;
  static const double _handleWidth = 18;

  // Trimmer is kept ONLY for export (saveTrimmedVideo) and play/pause sync —
  // its TrimViewer widget (the buggy part) is never used.
  final Trimmer _trimmer = Trimmer();
  VideoPlayerController? _videoController;

  File? _localVideoFile;
  Duration _videoDuration = Duration.zero;

  double _startFraction = 0; // 0..1 of full video
  double _endFraction = 1; // 0..1 of full video

  bool _loaded = false;
  bool _isPlaying = false;
  bool _isSaving = false;
  double _fileSizeMb = 0;

  // Thumbnail strip state
  List<Uint8List?> _thumbnails = [];
  bool _thumbnailsLoading = true;
  bool _thumbnailsFailed = false;
  int _thumbnailCount = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final localFile = await _ensureLocalCopy(widget.videoFile);
      _localVideoFile = localFile;

      final bytes = await localFile.length();

      // Load into Trimmer purely for export capability later.
      await _trimmer.loadVideo(videoFile: localFile);

      final controller = VideoPlayerController.file(localFile);
      await controller.initialize();

      if (!mounted) return;

      final duration = controller.value.duration;
      final clampedEnd = duration <= widget.maxDuration
          ? duration
          : widget.maxDuration;

      setState(() {
        _videoController = controller;
        _videoDuration = duration;
        _fileSizeMb = bytes / (1024 * 1024);
        _startFraction = 0;
        _endFraction = duration.inMilliseconds == 0
            ? 1
            : clampedEnd.inMilliseconds / duration.inMilliseconds;
        _loaded = true;
      });

      controller.addListener(_onControllerTick);

      _generateThumbnailStrip();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load video: $e')),
      );
    }
  }

  void _onControllerTick() {
    if (!mounted || _videoController == null) return;
    final playing = _videoController!.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }
    // Loop playback within the selected trim range.
    final pos = _videoController!.value.position;
    final endPos = Duration(
      milliseconds: (_endFraction * _videoDuration.inMilliseconds).round(),
    );
    if (playing && pos >= endPos) {
      final startPos = Duration(
        milliseconds: (_startFraction * _videoDuration.inMilliseconds).round(),
      );
      _videoController!.seekTo(startPos);
    }
  }

  // WhatsApp/gallery pickers can hand back a path the native thumbnail
  // generator can't read directly — copy into app temp dir first.
  Future<File> _ensureLocalCopy(File original) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final ext = p.extension(original.path).isNotEmpty
          ? p.extension(original.path)
          : '.mp4';
      final destPath = p.join(
        tempDir.path,
        'trim_src_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      return await original.copy(destPath);
    } catch (_) {
      return original;
    }
  }

  Future<void> _generateThumbnailStrip() async {
    setState(() {
      _thumbnailsLoading = true;
      _thumbnailsFailed = false;
    });

    final path = _localVideoFile?.path ?? widget.videoFile.path;
    debugPrint('[TRIM] generating thumbnails from: $path (exists=${File(path).existsSync()})');
    final durationMs = _videoDuration.inMilliseconds;
    if (durationMs <= 0) {
      setState(() {
        _thumbnailsLoading = false;
        _thumbnailsFailed = true;
      });
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final stripWidth = screenWidth - (_horizontalPadding * 2);
    const thumbTargetWidth = 40.0;
    final count = (stripWidth / thumbTargetWidth).ceil().clamp(4, 30);

    setState(() {
      _thumbnailCount = count;
      _thumbnails = List<Uint8List?>.filled(count, null);
    });

    try {
      // IMPORTANT: firing all N thumbnail requests at once overloads the
      // native decoder on most devices and makes EVERY request miss its
      // timeout (this was the "Retry loading clip" bug). Generate them in
      // small batches instead so each decode gets a fair shot.
      const batchSize = 4;
      for (int batchStart = 0; batchStart < count; batchStart += batchSize) {
        if (!mounted) return;
        final batchEnd = (batchStart + batchSize).clamp(0, count);
        final batchFutures = <Future<void>>[];

        for (int i = batchStart; i < batchEnd; i++) {
          final timeMs = ((i + 0.5) / count * durationMs).round();
          batchFutures.add(
            vt.VideoThumbnail.thumbnailData(
              video: path,
              imageFormat: vt.ImageFormat.JPEG,
              maxWidth: 120,
              quality: 40,
              timeMs: timeMs,
            ).timeout(const Duration(seconds: 10), onTimeout: () {
              debugPrint('[TRIM] thumbnail $i TIMED OUT at ${timeMs}ms, path=$path');
              return null;
            }).then((data) {
              if (!mounted) return;
              debugPrint('[TRIM] thumbnail $i ${data == null ? "returned NULL" : "OK (${data.length} bytes)"}');
              setState(() {
                _thumbnails[i] = data;
              });
            }).catchError((e, st) {
              debugPrint('[TRIM] thumbnail $i THREW: $e');
            }),
          );
        }

        await Future.wait(batchFutures);
      }

      if (!mounted) return;

      final anySucceeded = _thumbnails.any((t) => t != null);
      setState(() {
        _thumbnailsLoading = false;
        _thumbnailsFailed = !anySucceeded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _thumbnailsLoading = false;
        _thumbnailsFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onControllerTick);
    _videoController?.dispose();
    _trimmer.dispose();
    if (_localVideoFile != null &&
        _localVideoFile!.path != widget.videoFile.path) {
      _localVideoFile!.delete().catchError((_) => _localVideoFile!);
    }
    super.dispose();
  }

  Duration get _selectedDuration {
    final ms =
    ((_endFraction - _startFraction) * _videoDuration.inMilliseconds)
        .round();
    return Duration(milliseconds: ms.clamp(0, _videoDuration.inMilliseconds));
  }

  void _togglePlay() {
    if (!_loaded || _videoController == null) return;
    if (_isPlaying) {
      _videoController!.pause();
    } else {
      final startPos = Duration(
        milliseconds: (_startFraction * _videoDuration.inMilliseconds).round(),
      );
      final pos = _videoController!.value.position;
      final endPos = Duration(
        milliseconds: (_endFraction * _videoDuration.inMilliseconds).round(),
      );
      if (pos < startPos || pos >= endPos) {
        _videoController!.seekTo(startPos);
      }
      _videoController!.play();
    }
  }

  // Drag handling -----------------------------------------------------

  double _stripWidth(BuildContext context) =>
      MediaQuery.of(context).size.width - (_horizontalPadding * 2);

  void _onStartDrag(double dx, double stripWidth) {
    final maxFraction = widget.maxDuration.inMilliseconds /
        _videoDuration.inMilliseconds
            .clamp(1, double.infinity);
    double newStart = (_startFraction + dx / stripWidth).clamp(0.0, _endFraction - 0.02);
    // Enforce max selectable duration.
    if (_endFraction - newStart > maxFraction) {
      newStart = _endFraction - maxFraction;
    }
    setState(() => _startFraction = newStart.clamp(0.0, 1.0));
  }

  void _onEndDrag(double dx, double stripWidth) {
    final maxFraction = widget.maxDuration.inMilliseconds /
        _videoDuration.inMilliseconds
            .clamp(1, double.infinity);
    double newEnd = (_endFraction + dx / stripWidth).clamp(_startFraction + 0.02, 1.0);
    if (newEnd - _startFraction > maxFraction) {
      newEnd = _startFraction + maxFraction;
    }
    setState(() => _endFraction = newEnd.clamp(0.0, 1.0));
  }

  Future<void> _saveTrim() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final startValue = _startFraction * _videoDuration.inMilliseconds;
    final endValue = _endFraction * _videoDuration.inMilliseconds;

    try {
      String? outputPath;
      await _trimmer.saveTrimmedVideo(
        startValue: startValue,
        endValue: endValue,
        onSave: (String? path) {
          outputPath = path;
        },
      );

      if (!mounted) return;

      if (outputPath == null || outputPath!.isEmpty) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the trimmed video.')),
        );
        return;
      }

      Navigator.pop(context, File(outputPath!));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trim failed: $e')),
      );
    }
  }

  // UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_loaded
          ? const Center(
        child: CircularProgressIndicator(color: whatsappGreen),
      )
          : SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 12),
            _buildTrimStrip(context),
            const SizedBox(height: 14),
            _buildTimeRow(),
            Expanded(child: _buildPreview()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF101619),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context, null),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
            ),
          ),
          const Spacer(),
          Text(
            'Max ${widget.maxDuration.inSeconds}s',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimStrip(BuildContext context) {
    final stripWidth = _stripWidth(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: SizedBox(
        height: _stripHeight,
        width: stripWidth,
        child: Stack(
          children: [
            // Thumbnail background
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildThumbnailRow(stripWidth),
            ),

            // Dim regions outside the selected range
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: (_startFraction * stripWidth).clamp(0.0, stripWidth),
              child: IgnorePointer(
                child: Container(color: Colors.black.withOpacity(.55)),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: ((1 - _endFraction) * stripWidth).clamp(0.0, stripWidth),
              child: IgnorePointer(
                child: Container(color: Colors.black.withOpacity(.55)),
              ),
            ),

            // Selection border — full box, like WhatsApp's status trimmer,
            // not just top/bottom lines.
            Positioned(
              left: (_startFraction * stripWidth).clamp(0.0, stripWidth),
              width: ((_endFraction - _startFraction) * stripWidth)
                  .clamp(0.0, stripWidth),
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Start handle — vertical bar with circular knobs top & bottom,
            // matching the real WhatsApp trim handle shape.
            Positioned(
              left: (_startFraction * stripWidth - _handleWidth / 2)
                  .clamp(-_handleWidth / 2, stripWidth - _handleWidth / 2),
              top: 0,
              bottom: 0,
              width: _handleWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) =>
                    _onStartDrag(details.delta.dx, stripWidth),
                child: _dragHandle(),
              ),
            ),

            // End handle
            Positioned(
              left: (_endFraction * stripWidth - _handleWidth / 2)
                  .clamp(-_handleWidth / 2, stripWidth - _handleWidth / 2),
              top: 0,
              bottom: 0,
              width: _handleWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) =>
                    _onEndDrag(details.delta.dx, stripWidth),
                child: _dragHandle(),
              ),
            ),

            // Loading / retry overlay
            if (_thumbnailsLoading)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: whatsappGreen,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            else if (_thumbnailsFailed)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(.5),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _generateThumbnailStrip,
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                      label: const Text(
                        'Retry loading clip',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dragHandle() {
    const knobSize = 14.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _knob(knobSize),
        Expanded(
          child: Center(
            child: Container(
              width: 3,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 3),
                ],
              ),
            ),
          ),
        ),
        _knob(knobSize),
      ],
    );
  }

  Widget _knob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 3),
        ],
      ),
    );
  }

  Widget _buildThumbnailRow(double stripWidth) {
    if (_thumbnailCount == 0) {
      return Container(color: const Color(0xFF1C1C1C));
    }
    // Expanded (flex) instead of a manually computed SizedBox width — this
    // always sums exactly to the parent's width regardless of rounding,
    // which is what was causing the "OVERFLOWED BY Npx" error.
    return Row(
      children: List.generate(_thumbnailCount, (i) {
        final data = i < _thumbnails.length ? _thumbnails[i] : null;
        return Expanded(
          child: SizedBox(
            height: _stripHeight,
            child: data != null
                ? Image.memory(data, fit: BoxFit.cover, gaplessPlayback: true)
                : Container(color: const Color(0xFF2A2A2A)),
          ),
        );
      }),
    );
  }

  Widget _buildTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.volume_up_rounded, color: Colors.white, size: 21),
          const SizedBox(width: 10),
          Text(
            '${_selectedDuration.inSeconds}s',
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('•', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ),
          Text(
            '${_fileSizeMb.toStringAsFixed(1)} MB',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return Center(
      child: GestureDetector(
        onTap: _togglePlay,
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isPlaying ? 0 : 1,
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Drag the handles to select the part you want to keep',
              style: TextStyle(
                color: Colors.white.withOpacity(.65),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _isSaving ? null : _saveTrim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: whatsappGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Icon(Icons.check_rounded, color: Colors.white, size: 34),
              ),
            ),
          ),
        ],
      ),
    );
  }
}