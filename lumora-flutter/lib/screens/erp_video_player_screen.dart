import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/meditation.dart';

const _kBlue = Color(0xFF6BAED4);

class ErpVideoPlayerScreen extends StatefulWidget {
  final Meditation meditation;
  final Duration timerDuration;

  const ErpVideoPlayerScreen({
    super.key,
    required this.meditation,
    required this.timerDuration,
  });

  @override
  State<ErpVideoPlayerScreen> createState() => _ErpVideoPlayerScreenState();
}

class _ErpVideoPlayerScreenState extends State<ErpVideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Timer? _timer;

  late int _secondsRemaining;
  bool _isLoading = true;
  bool _completed = false;
  bool _allowPop = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.timerDuration.inSeconds;
    _startErpTimer();
    _initializePlayer();
  }

  void _startErpTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 1) {
        _finishCompleted();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  Future<void> _initializePlayer() async {
    try {
      final downloadUrl =
          await FirebaseStorage.instance
              .ref(widget.meditation.videoPath)
              .getDownloadURL();

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(downloadUrl),
      );
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: _kBlue,
          handleColor: Colors.white,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      _timer?.cancel();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load video';
      });
    }
  }

  void _finishCompleted() {
    if (_completed || !mounted) return;
    _completed = true;
    _allowPop = true;
    _timer?.cancel();
    setState(() => _secondsRemaining = 0);
    Navigator.of(context).pop(true);
  }

  Future<void> _handleExit() async {
    if (_completed) return;
    _allowPop = true;
    _timer?.cancel();
    Navigator.of(context).pop(false);
  }

  String get _timeDisplay {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, __) {
        if (didPop) return;
        if (!_completed) _handleExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: _kBlue)
                        : _errorMessage != null
                        ? _VideoError(message: _errorMessage!)
                        : Chewie(controller: _chewieController!),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 14,
              child: _OverlayButton(
                icon: Icons.close_rounded,
                onTap: _handleExit,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _timeDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _VideoError extends StatelessWidget {
  final String message;

  const _VideoError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Go back and choose another video.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
