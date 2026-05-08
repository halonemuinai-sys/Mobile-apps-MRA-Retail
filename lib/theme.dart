import 'package:flutter/material.dart';

// MPI Advisor Design System — Modern Casual
class AppTheme {
  static const primary    = Color(0xFF6366F1); // indigo
  static const secondary  = Color(0xFF8B5CF6); // violet
  static const success    = Color(0xFF10B981); // emerald
  static const warning    = Color(0xFFF59E0B); // amber
  static const danger     = Color(0xFFEF4444); // red
  static const dark       = Color(0xFF0F172A);
  static const textSub    = Color(0xFF64748B);
  static const border     = Color(0xFFE2E8F0);
  static const bg         = Color(0xFFF1F5F9);
  static const card       = Colors.white;

  static const gradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static BoxDecoration cardDecor({Color? borderColor, double radius = 16}) => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? border),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
  );

  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: card,
      foregroundColor: dark,
      elevation: 0,
      surfaceTintColor: card,
      centerTitle: false,
    ),
  );
}
