import 'package:flutter/material.dart';

class AppColors {
  // Main Color (Primary)
  // Navy Blue — #0B1D3A
  // Represents trust, security, authority
  // Strong foundation for headers, app bars, buttons, map overlays
  // Works perfectly for dark mode base
  static const Color primary = Color(0xFF0B1D3A);
  static const Color primaryHover = Color(0xFF152D52);

  // Secondary Color (Accent)
  // Teal — #00B3A4
  // Represents AI, technology, intelligence
  // Use for highlights, active states, icons, radar waves, links
  // Keeps it modern without looking flashy
  static const Color secondary = Color(0xFF00B3A4);

  // Supporting Neutrals
  // Light Background — #F4F8FF
  static const Color lightBackground = Color(0xFFF4F8FF);

  // White — #FFFFFF
  static const Color white = Color(0xFFFFFFFF);

  // Soft Gray — #E5EAF2
  static const Color softGray = Color(0xFFE5EAF2);

  // Dark Text — #1A1A1A
  static const Color darkText = Color(0xFF1A1A1A);

  // Additional neutral colors for UI
  static const Color lightGray = Color(0xFFF6F7F8);
  static const Color mediumGray = Color(0xFFE5EAF2);
  static const Color darkGray = Color(0xFF64748B);
  static const Color slateGray = Color(0xFF94A3B8);

  // Registration screen specific neutrals
  // Neutral-800 — slightly lighter than primary for inputs
  static const Color neutral800 = Color(0xFF162A4D);

  // Neutral-700 — border color
  static const Color neutral700 = Color(0xFF1E3A66);

  // Neutral-400 — placeholder text
  static const Color neutral400 = Color(0xFF94A3B8);

  // Neutral-300 — secondary text
  static const Color neutral300 = Color(0xFFCBD5E1);

  // Alert Status Colors
  // Danger/Error — Red
  static const Color danger = Color(0xFFEF4444);

  // Warning — Amber
  static const Color warning = Color(0xFFFBBF24);

  // Success — Green
  static const Color success = Color(0xFF10B981);
}
