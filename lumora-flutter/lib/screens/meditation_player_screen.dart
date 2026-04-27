import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/meditation.dart';
import '../services/meditation_history_service.dart';

const _kBg = Color(0xFFD0E4F4);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);

class MeditationPlayerScreen extends StatefulWidget {
  final Meditation meditation;

  const MeditationPlayerScreen({super.key, required this.meditation});

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen> {
  final _historyService = MeditationHistoryService();
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubeVideoState>? _videoStateSub;
  StreamSubscription<YoutubePlayerValue>? _playerValueSub;

  String? _historySessionId;
  bool _hasRecordedStart = false;
  bool _hasRecordedCompletion = false;
  int _lastSyncedSecond = -1;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.meditation.youtubeVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
        strictRelatedVideos: true,
        origin: 'https://www.youtube.com',
        userAgent:
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15',
      ),
    );

    _videoStateSub = _controller.videoStateStream.listen(_handleVideoState);
    _playerValueSub = _controller.stream.listen((value) {
      if (value.playerState == PlayerState.ended) {
        _recordCompletionIfNeeded();
      }
    });
  }

  Duration get _effectiveDuration {
    final actual = _controller.metadata.duration;
    if (actual.inSeconds > 0) {
      return actual;
    }
    return Duration(minutes: widget.meditation.durationMinutes);
  }

  String get _sessionTypeLabel {
    return widget.meditation.category == MeditationCategory.quick1Min
        ? 'Quick reset'
        : 'Guided meditation';
  }

  Future<void> _handleVideoState(YoutubeVideoState state) async {
    final positionSeconds = state.position.inSeconds;

    if (!_hasRecordedStart && positionSeconds >= 3) {
      _hasRecordedStart = true;
      try {
        _historySessionId = await _historyService.startSession(
          widget.meditation,
          positionSeconds: positionSeconds,
        );
      } catch (_) {
        _historySessionId = null;
      }
    }

    if (_historySessionId == null) return;

    if (!_hasRecordedCompletion) {
      final durationSeconds = _effectiveDuration.inSeconds;
      final progress =
          durationSeconds <= 0 ? 0.0 : positionSeconds / durationSeconds;
      if (progress >= 0.9) {
        await _recordCompletionIfNeeded(positionSeconds: positionSeconds);
        return;
      }
    }

    if (positionSeconds - _lastSyncedSecond >= 5) {
      _lastSyncedSecond = positionSeconds;
      unawaited(
        _historyService.updateSession(
          sessionId: _historySessionId!,
          positionSeconds: positionSeconds,
          completed: false,
        ),
      );
    }
  }

  Future<void> _recordCompletionIfNeeded({int? positionSeconds}) async {
    if (_historySessionId == null || _hasRecordedCompletion) return;
    _hasRecordedCompletion = true;

    final seconds = positionSeconds ?? _effectiveDuration.inSeconds;
    try {
      await _historyService.updateSession(
        sessionId: _historySessionId!,
        positionSeconds: seconds,
        completed: true,
      );
    } catch (_) {
      // Playback should continue even if history persistence fails.
    }
  }

  @override
  void dispose() {
    _videoStateSub?.cancel();
    _playerValueSub?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      builder: (context, player) {
        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PlayerHeader(title: widget.meditation.title),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: player,
                  ),
                  const SizedBox(height: 14),
                  StreamBuilder<YoutubeVideoState>(
                    stream: _controller.videoStateStream,
                    initialData: const YoutubeVideoState(),
                    builder: (context, snapshot) {
                      final position =
                          snapshot.data?.position.inMilliseconds ?? 0;
                      final duration = _effectiveDuration.inMilliseconds;

                      return LinearProgressIndicator(
                        value: duration <= 0 ? 0 : position / duration,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: Colors.white54,
                        valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.meditation.title,
                          style: const TextStyle(
                            color: _kNavy,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetaChip(label: widget.meditation.durationLabel),
                            _MetaChip(label: _sessionTypeLabel),
                          ],
                        ),
                        if (widget.meditation.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.meditation.description,
                            style: const TextStyle(
                              color: _kSubtitle,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final String title;

  const _PlayerHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDEECF8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _kNavy,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
