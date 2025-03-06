
import 'package:flutter/material.dart';

class TColor {
  static Color get primaryColor1 => Color(0xFF8B4B4B); // Primary Accent (Darker Dusty Rose)
  static Color get primaryColor2 => Color(0xFF3C3C3C); // Tertiary Accent (Darker Beige, optional)
  static Color get secondaryColor1 => Color(0xFF3C3C6E); // Secondary Accent (Darker Indigo, replacing green)
  static Color get secondaryColor2 => Color(0xFF2C2C2C); // Dark background 
 

  static List<Color> get primaryG => [lightGray, darkRose]; 
  static List<Color> get secondaryG => [lightIndigo, darkSlate]; 
  static Color get red => Colors.red;
  // Light mode colors
  static const Color black = Color(0xff1D1617); // Primary text for light mode

  // Dark mode colors
  static const Color darkSlate = Color(0xFF2C2C2C); // Background for dark mode
  static const Color darkCharcoal = Color(0xFF3C3C3C); // Cards/buttons for dark mode
  static const Color darkIndigo = Color(0xFF3F3F7F); // Darker indigo for gradients in dark mode


  // Optional: Add a method to get theme-specific colors
  static Color getPrimaryTextColor(bool isDarkMode) => isDarkMode ? white : black;
  static Color getSecondaryTextColor(bool isDarkMode) => isDarkMode ? gray.withOpacity(0.7) : gray; // Use white70 for dark mode if needed
  static Color getPrimaryAccentColor(bool isDarkMode) => darkRose; // Consistent across both modes
  static Color getSecondaryAccentColor(bool isDarkMode) => isDarkMode ? darkIndigo : lightIndigo;


  static const Color white = Color(0xFFFFFFFF); // White background (FitOn’s light mode or neutral)
  static const Color lightGray = Color(0xFFF5F5F5); // Light gray for cards (soft neutral, inspired by FitOn’s minimalism)
  static const Color darkRose = Color(0xFFE91C4C); // Red from FitOn for energy, buttons, CTAs
  static const Color lightIndigo = Color(0xFF025D93); // Blue from FitOn for trust, navigation, subtle accents
  static const Color freshCyan = Color(0xFF86F4EE); // Cyan from FitOn for vibrancy, highlights
  static const Color darkBeige = Color(0xFFF5E7C9); // Darker beige for subtle gradients (custom for FitGlide, inspired by earthy tones)
  static const Color gray = Color(0xFF757575); // Gray for text or disabled states (neutral from FitOn’s minimalism)

  // Optional: Add FitOn’s purple for depth or accents if needed
  static const Color deepPurple = Color(0xFF481865);

  //new colors 
  
  // New FitOn-inspired colors
  static const Color primaryRed = Color(0xFFFF4040); // Vibrant red for buttons, CTAs (FitOn-inspired)
  static const Color secondaryOrange = Color(0xFFFF8C00); // Energetic orange for highlights (FitOn-inspired)
  static const Color accentPurple = Color(0xFF9370DB); 
  
  // Primary Colors (Bold, Energetic, Fitness-Focused)
  static Color get primary => const Color(0xFFFF3D5A); // Vibrant Coral Red (CTA buttons, key actions)
  static Color get primaryLight => const Color(0xFFFF6B80); // Lighter Coral for gradients/hover states
  static Color get primaryDark => const Color(0xFFD92E47); // Darker Coral for depth or dark mode

  // Secondary Colors (Complementary, Modern Accents)
  static Color get secondary => const Color(0xFF7B61FF); // Electric Purple (navigation, highlights)
  static Color get secondaryLight => const Color(0xFFA48CFF); // Lighter Purple for subtle accents
  static Color get secondaryDark => const Color(0xFF5E49CC); // Darker Purple for contrast

  // Accent Colors (Pop and Motivation)
  static Color get accent1 => const Color(0xFFFF8C38); // Bright Orange (progress bars, alerts)
  static Color get accent2 => const Color(0xFF00A8E8); // Fresh Cyan Blue (trust, secondary CTAs)

  // Neutral Colors (Base for Light/Dark Modes)
  static Color get backgroundLight => const Color(0xFFF8F9FA); // Off-White (clean, modern light mode)
  static Color get backgroundDark => const Color(0xFF212529); // Dark Gray (sleek dark mode)
  static Color get cardLight => const Color(0xFFFFFFFF); // Pure White (cards in light mode)
  static Color get cardDark => const Color(0xFF343A40); // Darker Gray (cards in dark mode)

  // Text Colors
  static Color get textPrimary => const Color(0xFF1A1E22); // Near-Black for readability (light mode)
  static Color get textSecondary => const Color(0xFF6C757D); // Mid-Gray for subtitles (light mode)
  static Color get textPrimaryDark => const Color(0xFFFFFFFF); // White for dark mode text
  static Color get textSecondaryDark => const Color(0xFFB0B5BA); // Light Gray for dark mode subtitles

  // Opacity Helpers
  static Color grayWithOpacity(double opacity) => textSecondary.withOpacity(opacity);
  static Color blackWithOpacity(double opacity) => textPrimary.withOpacity(opacity);

  // Theme-Specific Methods
  static Color getBackground(bool isDarkMode) => isDarkMode ? backgroundDark : backgroundLight;
  static Color getCardColor(bool isDarkMode) => isDarkMode ? cardDark : cardLight;
  static Color getPrimaryText(bool isDarkMode) => isDarkMode ? textPrimaryDark : textPrimary;
  static Color getSecondaryText(bool isDarkMode) => isDarkMode ? textSecondaryDark : textSecondary;
  static Color getPrimaryAccent(bool isDarkMode) => primary; // Consistent across modes
  static Color getSecondaryAccent(bool isDarkMode) => secondary; // Consistent across modes
}// Lavender for gradients (FitOn-inspired)
