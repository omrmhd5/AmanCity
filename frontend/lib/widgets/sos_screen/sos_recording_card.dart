import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../models/sos/sos_recording.dart';
import '../../utils/app_theme.dart';

class SosRecordingCard extends StatefulWidget {
  final SosRecording recording;
  final AudioPlayer sharedPlayer;
  final String? currentlyPlayingId;
  final VoidCallback onDelete;
  final ValueChanged<String?> onPlayStateChange;

  const SosRecordingCard({
    Key? key,
    required this.recording,
    required this.sharedPlayer,
    required this.currentlyPlayingId,
    required this.onDelete,
    required this.onPlayStateChange,
  }) : super(key: key);

  @override
  State<SosRecordingCard> createState() => _SosRecordingCardState();
}

class _SosRecordingCardState extends State<SosRecordingCard> {
  bool get _isPlaying => widget.currentlyPlayingId == widget.recording.id;
  bool _playPressed = false;
  bool _deletePressed = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _seeking = false;

  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  @override
  void initState() {
    super.initState();
    _positionSub = widget.sharedPlayer.onPositionChanged.listen((pos) {
      if (_isPlaying && !_seeking && mounted) {
        setState(() => _position = pos);
      }
    });
    _durationSub = widget.sharedPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
      }
    });
  }

  @override
  void didUpdateWidget(SosRecordingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset position display when this card stops playing
    if (oldWidget.currentlyPlayingId == widget.recording.id &&
        widget.currentlyPlayingId != widget.recording.id) {
      setState(() {
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }
    // Sync duration/position from player when this card becomes active
    if (oldWidget.currentlyPlayingId != widget.recording.id &&
        widget.currentlyPlayingId == widget.recording.id) {
      widget.sharedPlayer.getDuration().then((dur) {
        if (dur != null && mounted) setState(() => _duration = dur);
      });
      widget.sharedPlayer.getCurrentPosition().then((pos) {
        if (pos != null && mounted) setState(() => _position = pos);
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final recordingId = widget.recording.id;
    final filePath = widget.recording.path;

    if (_isPlaying) {
      await widget.sharedPlayer.pause();
      widget.onPlayStateChange(null);
    } else {
      try {
        final file = File(filePath);
        if (!file.existsSync()) return;

        final source = DeviceFileSource(filePath);
        await widget.sharedPlayer.stop();
        await widget.sharedPlayer.setReleaseMode(ReleaseMode.stop);
        await widget.sharedPlayer.play(source, volume: 1.0);
        widget.onPlayStateChange(recordingId);
      } catch (e) {
        rethrow;
      }
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDurationObj(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  •  $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.recording;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isPlaying
              ? AppColors.secondary.withOpacity(0.5)
              : AppTheme.getBorderColor(),
          width: _isPlaying ? 1 : 0.75,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Play / pause button
                GestureDetector(
                  onTap: _togglePlay,
                  onTapDown: (_) => setState(() => _playPressed = true),
                  onTapUp: (_) => setState(() => _playPressed = false),
                  onTapCancel: () => setState(() => _playPressed = false),
                  child: AnimatedScale(
                    scale: _playPressed ? 0.93 : 1.0,
                    duration: Duration(milliseconds: _playPressed ? 80 : 300),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: _isPlaying
                            ? const LinearGradient(
                                colors: [
                                  AppColors.secondary,
                                  Color(0xFF00897B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _isPlaying
                            ? null
                            : AppColors.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.2),
                          width: 0.75,
                        ),
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: _isPlaying ? Colors.white : AppColors.secondary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(recording.dateTime),
                        style: TextStyle(
                          color: AppTheme.getPrimaryTextColor(),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(recording.durationSeconds),
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(),
                              fontSize: 12,
                            ),
                          ),
                          if (recording.latitude != null) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.recording.address ??
                                    '${recording.latitude!.toStringAsFixed(4)}, '
                                        '${recording.longitude!.toStringAsFixed(4)}',
                                style: TextStyle(
                                  color: AppTheme.getSecondaryTextColor(),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete
                GestureDetector(
                  onTap: widget.onDelete,
                  onTapDown: (_) => setState(() => _deletePressed = true),
                  onTapUp: (_) => setState(() => _deletePressed = false),
                  onTapCancel: () => setState(() => _deletePressed = false),
                  child: AnimatedScale(
                    scale: _deletePressed ? 0.93 : 1.0,
                    duration: Duration(milliseconds: _deletePressed ? 80 : 300),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.15),
                          width: 0.75,
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Progress slider — only shown while playing
            if (_isPlaying) ...[
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: AppColors.secondary,
                  inactiveTrackColor: AppColors.secondary.withOpacity(0.2),
                  thumbColor: AppColors.secondary,
                  overlayColor: AppColors.secondary.withOpacity(0.15),
                ),
                child: Slider(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds
                            .clamp(0, _duration.inMilliseconds)
                            .toDouble()
                      : 0.0,
                  min: 0.0,
                  max: _duration.inMilliseconds > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChangeStart: (_) => setState(() => _seeking = true),
                  onChanged: (value) {
                    setState(
                      () => _position = Duration(milliseconds: value.toInt()),
                    );
                  },
                  onChangeEnd: (value) async {
                    setState(() => _seeking = false);
                    await widget.sharedPlayer.seek(
                      Duration(milliseconds: value.toInt()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDurationObj(_position),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                    Text(
                      _duration > Duration.zero
                          ? _formatDurationObj(_duration)
                          : _formatDuration(recording.durationSeconds),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
