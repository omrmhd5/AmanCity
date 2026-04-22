import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
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

  Future<void> _sendMessage(String text) async {
    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: _getCurrentTime()),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate typing delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Generate AI response based on keywords
    String aiResponse = _generateAiResponse(text);
    String? citation;

    if (text.toLowerCase().contains('safe') ||
        text.toLowerCase().contains('area')) {
      citation =
          'Based on 3 verified reports in the last hour regarding low lighting.';
    } else if (text.toLowerCase().contains('route') ||
        text.toLowerCase().contains('way')) {
      citation =
          'Safe route analysis using real-time incident data and street lighting information.';
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: _getCurrentTime(),
          citationText: citation,
        ),
      );
      _isTyping = false;
    });

    _scrollToBottom();
  }

  String _generateAiResponse(String userText) {
    final text = userText.toLowerCase();

    if (text.contains('safe') || text.contains('danger')) {
      return 'Current analysis suggests caution is required in your area. Based on recent reports, there have been several incidents. I recommend staying alert and avoiding isolated areas, especially during late hours. Would you like specific safety recommendations?';
    } else if (text.contains('route') ||
        text.contains('way') ||
        text.contains('path')) {
      return 'The Ring Road is currently the safest option due to high traffic flow and active street lighting. Estimated time: 24 minutes. Main streets are well-lit and monitored. Would you like directions or more alternatives?';
    } else if (text.contains('emergency') ||
        text.contains('help') ||
        text.contains('danger')) {
      return 'In case of emergency, call 122 (Emergency Services) or 126 (Tourist Police). If you need immediate assistance, your location has been noted. Stay safe and keep emergency contacts saved.';
    } else if (text.contains('incident') || text.contains('report')) {
      return 'You can report incidents through the app\'s Report feature. Provide details, location, and any evidence (photos/videos). Your reports help improve community safety. Would you like to file a report?';
    } else if (text.contains('alert') || text.contains('notification')) {
      return 'I can send you safety alerts for your area. Enable notifications in settings to receive real-time updates about incidents and recommended safe routes. This helps you stay informed and avoid dangerous areas.';
    } else {
      return 'I\'m here to help with safety information. You can ask me about area safety, safest routes, emergency contacts, or how to report incidents. What would you like to know?';
    }
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
