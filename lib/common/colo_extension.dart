
import 'package:flutter/material.dart';

class TColor {
  static Color get primaryColor1 => Color(0xFF98FF98); // Vibrant Sage Green
  static Color get primaryColor2 => Color(0xFFFFE4C4); // Vibrant Beige
  static Color get secondaryColor1 => Color(0xFFFFC0CB); // Vibrant Dusty Rose
  static Color get secondaryColor2 => Color(0xFF90CAF9); // Bright Light Blue (optional secondary)

  static List<Color> get primaryG => [primaryColor2, primaryColor1]; // Beige to Sage Green
  static List<Color> get secondaryG => [secondaryColor1, secondaryColor2]; // Dusty Rose to Light Blue

  static Color get black => const Color(0xff1D1617);
  static Color get gray => const Color(0xff786F72);
  static Color get white => Colors.white;
  static Color get lightGray => const Color(0xffF7F8F8);
  static Color get red => Colors.red;

  static Color grayWithOpacity(double opacity) => Color(0xff786F72).withOpacity(opacity);
   static Color blackWithOpacity(double opacity) => Colors.black.withOpacity(opacity);

}