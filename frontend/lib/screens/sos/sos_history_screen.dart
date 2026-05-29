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

class _SosHistoryScreenState extends State<SosHistoryScreen>
    with SingleTickerProviderStateMixin {
  final SosService _sosService = SosService();
  final AudioPlayer _player = AudioPlayer();
  late AnimationController _entryController;

  List<SosRecording> _recordings = [];
  bool _loading = true;
  String? _currentlyPlayingId;
  late StreamSubscription _playerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _loadRecordings();
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _currentlyPlayingId = null);
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _playerCompleteSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
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

  Future<void> _confirmDeleteAll() async {
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
                'Delete All Recordings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryTextColor(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All ${_recordings.length} recordings will be permanently deleted.',
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
                      'Delete All',
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
      if (_currentlyPlayingId != null) {
        await _player.stop();
        setState(() => _currentlyPlayingId = null);
      }
      for (final rec in List.from(_recordings)) {
        await _sosService.deleteRecording(rec.id);
      }
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
            _animated(
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
                    if (_recordings.isNotEmpty)
                      IconButton(
                        onPressed: _confirmDeleteAll,
                        icon: Icon(
                          Icons.delete_sweep_rounded,
                          color: AppColors.danger,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Delete all',
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
              ),
              start: 0.0,
              end: 0.5,
            ),
            // Teal gradient divider
            _animated(
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
              start: 0.05,
              end: 0.5,
            ),
            // Section label
            if (!_loading && _recordings.isNotEmpty)
              _animated(
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
                start: 0.1,
                end: 0.6,
              ),
            Expanded(
              child: _animated(
                _loading
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
                start: 0.2,
                end: 0.75,
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
