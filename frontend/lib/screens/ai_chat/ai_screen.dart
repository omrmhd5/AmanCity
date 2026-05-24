import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/app_theme.dart';
import '../../services/ai_chat/gemini_chat_service.dart';
import '../../services/map/hotspot_api_service.dart';
import '../../services/map/safe_route_home_service.dart';
import '../../widgets/ai_screen/ai_chat_header.dart';
import '../../widgets/ai_screen/ai_message_bubble.dart';
import '../../widgets/ai_screen/ai_quick_prompts.dart';
import '../../widgets/ai_screen/ai_chat_input.dart';
import '../../widgets/ai_screen/ai_route_home_button.dart';
import '../../models/map/hotspot_zone.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? citationText;
  final SafeRouteHomeData? routeHomeData;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citationText,
    this.routeHomeData,
  });
}

class AiScreen extends StatefulWidget {
  const AiScreen({Key? key}) : super(key: key);

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> with TickerProviderStateMixin {
  late List<ChatMessage> _messages;
  late TextEditingController _inputController;
  late ScrollController _scrollController;
  late AnimationController _entryController;
  late AnimationController _dot1;
  late AnimationController _dot2;
  late AnimationController _dot3;
  bool _isTyping = false;
  double? _userLat;
  double? _userLng;
  List<HotspotZone>? _cachedHotspots;
  String _selectedLanguage = 'en_US';

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _scrollController = ScrollController();

    // Entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    // Typing indicator dot controllers
    _dot1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _dot2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _dot3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _dot1.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _dot2.repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _dot3.repeat(reverse: true);
    });

    _messages = [
      ChatMessage(
        text:
            'Hello! I\'m your Safety Assistant. I can help you learn about area safety, incident information, and emergency contacts. What would you like to know?',
        isUser: false,
        timestamp: _getCurrentTime(),
      ),
    ];

    _getUserLocation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _entryController.dispose();
    _dot1.dispose();
    _dot2.dispose();
    _dot3.dispose();
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
    }
  }

  /// Lazy load hotspots (cache them for session)
  Future<List<HotspotZone>> _getHotspots() async {
    if (_cachedHotspots != null) return _cachedHotspots!;
    try {
      _cachedHotspots = await HotspotApiService.getHotspots();
      return _cachedHotspots!;
    } catch (e) {
      return [];
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
      // Check if this is a route home request and calculate it
      SafeRouteHomeData? routeHomeData;
      String messageForGemini = text; // May be modified if route home detected

      if (_userLat != null && _userLng != null) {
        final hotspots = await _getHotspots();
        final routeResult =
            await SafeRouteHomeService.detectAndCalculateRouteHome(
              text,
              LatLng(_userLat!, _userLng!),
              hotspots,
            );

        if (routeResult.routeFound) {
          routeHomeData = SafeRouteHomeData(
            googleMapsUrl: routeResult.googleMapsUrl!,
            dangerScore: routeResult.dangerScore!,
            distance: routeResult.distance,
            duration: routeResult.duration,
            homeAddress: routeResult.homeAddress!,
          );

          // Modify message for Gemini to know route was calculated
          final riskLevel = routeResult.dangerScore! < 0.2
              ? "safe"
              : routeResult.dangerScore! < 0.3
              ? "moderately risky"
              : "high danger";
          messageForGemini =
              'I have calculated the safest route home: ${routeResult.distance} away (${routeResult.duration}). The route passes through a $riskLevel area. Please provide safety tips for traveling this route to ${routeResult.homeAddress}.';
        }
      }

      // Call Gemini service with location context
      final reply = await GeminiChatService.sendMessage(
        messageForGemini,
        latitude: _userLat,
        longitude: _userLng,
      );

      setState(() {
        _messages.add(
          ChatMessage(
            text: reply,
            isUser: false,
            timestamp: _getCurrentTime(),
            routeHomeData: routeHomeData,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _animated(
          AiChatHeader(
            onLanguageChanged: (language) {
              setState(() => _selectedLanguage = language);
            },
          ),
          start: 0.0,
          end: 0.5,
        ),
        // Messages area
        Expanded(
          child: _animated(
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
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
                              _buildDot(_dot1),
                              const SizedBox(width: 4),
                              _buildDot(_dot2),
                              const SizedBox(width: 4),
                              _buildDot(_dot3),
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
                  routeHomeData: message.routeHomeData,
                );
              },
            ),
            start: 0.1,
            end: 0.7,
          ),
        ),
        // Quick prompts
        _animated(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AiQuickPrompts(
              onPromptSelected: (prompt) {
                _inputController.text = prompt;
              },
            ),
          ),
          start: 0.2,
          end: 0.8,
        ),
        // Input area
        _animated(
          AiChatInput(
            controller: _inputController,
            onSend: _sendMessage,
            selectedLanguage: _selectedLanguage,
          ),
          start: 0.3,
          end: 0.9,
        ),
      ],
    );
  }

  Widget _buildDot(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.getSecondaryTextColor().withOpacity(
              (0.35 + controller.value * 0.65).clamp(0.35, 1.0),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
