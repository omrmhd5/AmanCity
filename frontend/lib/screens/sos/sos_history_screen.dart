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
      if (mounted) setState(() => _currentlyPlayingId = null);
    });
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {});
    _playerPositionSubscription = _player.onPositionChanged.listen((pos) {});
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
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => widget.onBack != null
                        ? widget.onBack!()
                        : Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.getPrimaryTextColor(),
                      size: 25,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'SOS Recordings',
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Teal gradient divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.0),
                      AppColors.secondary.withOpacity(0.3),
                      AppColors.secondary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Section label
            if (!_loading && _recordings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mic_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RECORDINGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getSecondaryTextColor(),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                      ),
                    )
                  : _recordings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: _recordings.length,
                      itemBuilder: (context, index) {
                        final rec = _recordings[index];
                        return SosRecordingCard(
                          recording: rec,
                          sharedPlayer: _player,
                          currentlyPlayingId: _currentlyPlayingId,
                          onDelete: () => _confirmDelete(rec),
                          onPlayStateChange: (id) {
                            if (mounted)
                              setState(() => _currentlyPlayingId = id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.danger.withOpacity(0.18),
                width: 0.75,
              ),
            ),
            child: Icon(
              Icons.mic_off_rounded,
              size: 36,
              color: AppColors.danger.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No recordings yet',
            style: TextStyle(
              color: AppTheme.getPrimaryTextColor(),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Audio is recorded automatically\nwhen you activate SOS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
