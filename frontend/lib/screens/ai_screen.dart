import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_theme.dart';
import '../services/backend_api/gemini_chat_service.dart';
import '../widgets/ai_screen/ai_chat_header.dart';
import '../widgets/ai_screen/ai_message_bubble.dart';
import '../widgets/ai_screen/ai_quick_prompts.dart';
import '../widgets/ai_screen/ai_chat_input.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? citationText;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citationText,
  });
}

class AiScreen extends StatefulWidget {
  const AiScreen({Key? key}) : super(key: key);

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  late List<ChatMessage> _messages;
  late TextEditingController _inputController;
  late ScrollController _scrollController;
  bool _isTyping = false;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _scrollController = ScrollController();

    // Initialize with greeting message
    _messages = [
      ChatMessage(
        text:
            'Hello! I\'m your Safety Assistant. I can help you learn about area safety, incident information, and emergency contacts. What would you like to know?',
        isUser: false,
        timestamp: _getCurrentTime(),
      ),
    ];

    // Get user location for chat context
    _getUserLocation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    } catch (e) {
      // Location permission denied or error; continue without location context
      print('Location error: $e');
    }
  }

  Future<void> _sendMessage(String text) async {
    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: _getCurrentTime()),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Call Gemini service with location context
      final reply = await GeminiChatService.sendMessage(
        text,
        latitude: _userLat,
        longitude: _userLng,
      );

      setState(() {
        _messages.add(
          ChatMessage(text: reply, isUser: false, timestamp: _getCurrentTime()),
        );
        _isTyping = false;
      });
    } catch (error) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Sorry, I encountered an error: ${error.toString()}',
            isUser: false,
            timestamp: _getCurrentTime(),
          ),
        );
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        AiChatHeader(),
        // Messages area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isTyping) {
                // Typing indicator
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.getCardBackgroundColor(),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _buildDot(0),
                            const SizedBox(width: 4),
                            _buildDot(100),
                            const SizedBox(width: 4),
                            _buildDot(200),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final message = _messages[index];
              return AiMessageBubble(
                text: message.text,
                isUser: message.isUser,
                timestamp: message.timestamp,
                citationText: message.citationText,
                onCitationTap: () {
                  // TODO: Navigate to map with incident location
                },
              );
            },
          ),
        ),
        // Quick prompts
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AiQuickPrompts(
            onPromptSelected: (prompt) {
              _inputController.text = prompt;
            },
          ),
        ),
        // Input area
        AiChatInput(
          controller: _inputController,
          onSend: _sendMessage,
          onMicPress: () {
            // TODO: Implement voice input
          },
        ),
      ],
    );
  }

  Widget _buildDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.getSecondaryTextColor().withOpacity(
              value.clamp(0.5, 1.0),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
