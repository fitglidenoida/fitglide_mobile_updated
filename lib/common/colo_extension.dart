
import 'package:flutter/material.dart';

class TColor {
  static Color get primaryColor1 => Color(0xFF8B4B4B); // Primary Accent (Darker Dusty Rose)
  static Color get primaryColor2 => Color(0xFF3C3C3C); // Tertiary Accent (Darker Beige, optional)
  static Color get secondaryColor1 => Color(0xFF3C3C6E); // Secondary Accent (Darker Indigo, replacing green)
  static Color get secondaryColor2 => Color(0xFF2C2C2C); // Dark background 
 


  static List<Color> get primaryG => [lightGray, darkRose]; 
  static List<Color> get secondaryG => [lightIndigo, darkSlate]; 
  static Color get red => Colors.red;

  static Color grayWithOpacity(double opacity) => Color(0xff786F72).withOpacity(opacity);
   static Color blackWithOpacity(double opacity) => Colors.black.withOpacity(opacity);
  // Light mode colors
  static const Color black = Color(0xff1D1617); // Primary text for light mode

  // Dark mode colors
  static const Color darkSlate = Color(0xFF2C2C2C); // Background for dark mode
  static const Color darkCharcoal = Color(0xFF3C3C3C); // Cards/buttons for dark mode
  static const Color darkIndigo = Color(0xFF3F3F7F); // Darker indigo for gradients in dark mode


  // Optional: Add a method to get theme-specific colors
  static Color getBackground(bool isDarkMode) => isDarkMode ? darkSlate : white;
  static Color getCardColor(bool isDarkMode) => isDarkMode ? darkCharcoal : lightGray;
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
  
  // New FitOn-inspired colors
  static const Color primaryRed = Color(0xFFFF4040); // Vibrant red for buttons, CTAs (FitOn-inspired)
  static const Color secondaryOrange = Color(0xFFFF8C00); // Energetic orange for highlights (FitOn-inspired)
  static const Color accentPurple = Color(0xFF9370DB); // Lavender for gradients (FitOn-inspired)
}