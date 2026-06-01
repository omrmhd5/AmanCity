import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../shared/custom_text.dart';

class AiChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final String selectedLanguage;

  const AiChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    this.selectedLanguage = 'en_US',
  }) : super(key: key);

  @override
  State<AiChatInput> createState() => _AiChatInputState();
}

class _AiChatInputState extends State<AiChatInput> {
  final SpeechToText _speech = SpeechToText();
  final FocusNode _focusNode = FocusNode();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  Future<void> _initSpeech() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) setState(() => _speechAvailable = false);
        return;
      }

      final available = await _speech.initialize(
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {},
      );

      if (mounted) setState(() => _speechAvailable = available);
    } catch (e) {
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
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        final available = await _speech.initialize(
          onError: (error) {
            if (mounted) setState(() => _isListening = false);
          },
          onStatus: (status) {},
        );
        if (mounted) setState(() => _speechAvailable = available);
        if (!available) return;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger.withOpacity(0.92),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
              content: Row(
                children: [
                  Icon(Icons.mic_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'ai.mic_permission_required'.tr(),
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
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
      if ((status == 'done' || status == 'notListening') && mounted) {
        setState(() => _isListening = false);
      }
    };
  }

  @override
  void dispose() {
    _speech.stop();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;
    final isActive = _isFocused || _isListening;

    return Column(
      children: [
        // Glass morphism input bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? AppColors.secondary.withOpacity(0.08)
                      : Colors.black.withOpacity(isDark ? 0.28 : 0.08),
                  blurRadius: isActive ? 16 : 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Stack(
                  children: [
                    // Glass base + border + content
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.primary.withOpacity(0.58),
                                  AppColors.primary.withOpacity(0.44),
                                ]
                              : [
                                  Colors.white.withOpacity(0.72),
                                  Colors.white.withOpacity(0.55),
                                ],
                        ),
                        border: Border.all(
                          color: _isListening
                              ? AppColors.secondary.withOpacity(0.6)
                              : isActive
                              ? AppColors.secondary.withOpacity(0.45)
                              : isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.white.withOpacity(0.65),
                          width: isActive ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Input field
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              focusNode: _focusNode,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.getPrimaryTextColor(),
                              ),
                              decoration: InputDecoration(
                                hintText: _isListening
                                    ? 'ai.listening'.tr()
                                    : 'ai.ask_hint'.tr(),
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Specular highlight
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(isDark ? 0.30 : 0.75),
                                Colors.white.withOpacity(isDark ? 0.14 : 0.45),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.25, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
