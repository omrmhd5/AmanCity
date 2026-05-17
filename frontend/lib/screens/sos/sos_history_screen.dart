import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../models/sos/sos_recording.dart';
import '../../services/sos/sos_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/sos_screen/sos_recording_card.dart';

class SosHistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SosHistoryScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  final SosService _sosService = SosService();
  final AudioPlayer _player = AudioPlayer();

  List<SosRecording> _recordings = [];
  bool _loading = true;
  String? _currentlyPlayingId;
  late StreamSubscription _playerCompleteSubscription;
  late StreamSubscription _playerStateSubscription;
  late StreamSubscription _playerPositionSubscription;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      print('[SosHistory] onPlayerComplete fired — id=$_currentlyPlayingId');
      if (mounted) setState(() => _currentlyPlayingId = null);
    });
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      print('[SosHistory] playerState → $state');
    });
    _playerPositionSubscription = _player.onPositionChanged.listen((pos) {
      if (pos.inMilliseconds % 2000 < 200) {
        print('[SosHistory] position=${pos.inSeconds}s');
      }
    });
  }

  @override
  void dispose() {
    _playerCompleteSubscription.cancel();
    _playerStateSubscription.cancel();
    _playerPositionSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final recordings = await _sosService.getRecordings();
    if (mounted) {
      setState(() {
        _recordings = recordings;
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(SosRecording recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.currentMode == AppThemeMode.dark
                ? AppColors.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorderColor(), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete Recording',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryTextColor(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This recording will be permanently deleted.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      // Stop if currently playing this recording
      if (_currentlyPlayingId == recording.id) {
        await _player.stop();
        setState(() => _currentlyPlayingId = null);
      }
      await _sosService.deleteRecording(recording.id);
      await _loadRecordings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(),
        elevation: 0,
        title: Text(
          'SOS Recordings',
          style: TextStyle(
            color: AppTheme.getPrimaryTextColor(),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.getPrimaryTextColor(),
            size: 20,
          ),
          onPressed: () =>
              widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : _recordings.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: _recordings.length,
              itemBuilder: (context, index) {
                final rec = _recordings[index];
                return SosRecordingCard(
                  recording: rec,
                  sharedPlayer: _player,
                  currentlyPlayingId: _currentlyPlayingId,
                  onDelete: () => _confirmDelete(rec),
                  onPlayStateChange: (id) {
                    if (mounted) setState(() => _currentlyPlayingId = id);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_off_outlined,
            size: 64,
            color: AppTheme.getSecondaryTextColor().withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No recordings yet',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Audio is recorded automatically\nwhen you activate SOS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor().withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
