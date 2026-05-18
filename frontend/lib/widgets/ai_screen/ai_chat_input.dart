import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../shared/custom_text.dart';

class AiChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final VoidCallback? onMicPress;
  final String selectedLanguage;

  const AiChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    this.onMicPress,
    this.selectedLanguage = 'en_US',
  }) : super(key: key);

  @override
  State<AiChatInput> createState() => _AiChatInputState();
}

class _AiChatInputState extends State<AiChatInput> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      // Request microphone permission first
      final status = await Permission.microphone.request();
      print('[AiChatInput] Microphone permission: $status');
      
      if (!status.isGranted) {
        print('[AiChatInput] Microphone permission denied');
        if (mounted) setState(() => _speechAvailable = false);
        return;
      }

      final available = await _speech.initialize(
        onError: (error) {
          print('[AiChatInput] Speech init error: $error');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          print('[AiChatInput] Speech status: $status');
        },
      );
      
      print('[AiChatInput] Speech available: $available');
      if (mounted) setState(() => _speechAvailable = available);
    } catch (e) {
      print('[AiChatInput] Init error: $e');
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      print('[AiChatInput] Speech not available, requesting permission...');
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        final available = await _speech.initialize(
          onError: (error) => print('[AiChatInput] Init error: $error'),
          onStatus: (status) => print('[AiChatInput] Speech status: $status'),
        );
        if (mounted) setState(() => _speechAvailable = available);
        if (!available) return;
      } else {
        print('[AiChatInput] Permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone permission required'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() => _isListening = true);
      widget.controller.clear();
    }

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          widget.controller.text = result.recognizedWords;
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: true,
      localeId: widget.selectedLanguage,
    );

    _speech.statusListener = (status) {
      print('[AiChatInput] Listen status: $status');
      if ((status == 'done' || status == 'notListening') && mounted) {
        setState(() => _isListening = false);
      }
    };
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackgroundColor(),
            border: Border.all(
              color: _isListening
                  ? AppColors.secondary
                  : AppTheme.getBorderColor(),
              width: _isListening ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Input field
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? 'Listening...'
                        : 'Ask about safety...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: _isListening
                          ? AppColors.secondary
                          : AppTheme.getSecondaryTextColor(),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (text) {
                    if (text.isNotEmpty) {
                      widget.onSend(text);
                      widget.controller.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Mic button
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.secondary.withOpacity(0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? AppColors.secondary
                        : AppTheme.getSecondaryTextColor(),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              GestureDetector(
                onTap: () {
                  if (widget.controller.text.isNotEmpty) {
                    widget.onSend(widget.controller.text);
                    widget.controller.clear();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        CustomText(
          text: 'Not a replacement for emergency services. Call 122.',
          size: 9,
          weight: FontWeight.w500,
          color: AppTheme.getSecondaryTextColor(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
