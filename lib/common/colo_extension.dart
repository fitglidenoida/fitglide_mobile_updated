
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
  static const Color white = Colors.white; // Background for light mode
  static const Color black = Color(0xff1D1617); // Primary text for light mode
  static const Color gray = Color(0xff786F72); // Secondary text for light mode
  static const Color lightGray = Color(0xFFF5F5F5); // Cards/buttons for light mode
  static const Color darkRose = Color(0xFF8B4B4B); // Primary accent (darker dusty rose)
  static const Color lightIndigo = Color(0xFFB3B3E6); // Lighter indigo for gradients in light mode
  static const Color darkBeige = Color(0xFFA68C6E); // Tertiary accent (darker beige)

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
}