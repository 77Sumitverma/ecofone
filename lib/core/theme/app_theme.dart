import 'package:flutter/material.dart';

/// EcoFone brand colors extracted from the official brand logo & banner:
/// - 'E' & 'Fone': Rich Forest Emerald Green (#13583C)
/// - 'F' & 'Eco': Vibrant Tech Orange (#EA580C -> #F58220)
/// - 'Luxury within reach': Warm Bronze / Terracotta (#A25527)
/// - Eco Certifications: Mint Green (#16A34A)
class EcoColors {
  // Primary Greens
  static const Color forestGreen = Color(0xFF13583C);
  static const Color darkEmerald = Color(0xFF0C3826);
  static const Color emeraldLight = Color(0xFF1E704E);

  // Vibrant Tech Oranges & Ambers
  static const Color vibrantOrange = Color(0xFFEA580C);
  static const Color brightAmber = Color(0xFFF58220);
  static const Color softOrange = Color(0xFFFFF7ED);
  static const Color orangeBorder = Color(0xFFFED7AA);

  // Luxury Tagline Bronze
  static const Color luxuryBronze = Color(0xFFA25527);
  static const Color bronzeLight = Color(0xFFC26E3A);

  // Trust & Verification Mint
  static const Color mintGreen = Color(0xFF16A34A);
  static const Color mintLight = Color(0xFFF0FDF4);
  static const Color mintBorder = Color(0xFFBBF7D0);

  // Surfaces & Neutrals
  static const Color background = Color(0xFFFBF9F5);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF0F2E22);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFF1F5F9);
}
