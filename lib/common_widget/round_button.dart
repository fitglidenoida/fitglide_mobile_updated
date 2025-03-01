import 'package:flutter/material.dart';

import '../common/colo_extension.dart';

enum RoundButtonType { bgGradient, bgSGradient, textGradient }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback onPressed;
  final double fontSize;
  final double elevation;
  final FontWeight fontWeight;

  const RoundButton({
    super.key,
    required this.title,
    this.type = RoundButtonType.bgGradient,
    this.fontSize = 16,
    this.elevation = 1,
    this.fontWeight = FontWeight.w700,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150, // Fixed width to prevent infinite size
      height: 50, // Fixed height
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: type == RoundButtonType.bgSGradient
                ? TColor.secondaryG // [lightIndigo, white]
                : TColor.primaryG, // [lightGray, darkRose]
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: type == RoundButtonType.bgGradient || type == RoundButtonType.bgSGradient
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Subtle shadow for light mode
                    blurRadius: 0.5,
                    offset: Offset(0, 0.5),
                  ),
                ]
              : null,
        ),
        child: MaterialButton(
          onPressed: onPressed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          textColor: type == RoundButtonType.bgGradient || type == RoundButtonType.bgSGradient
              ? TColor.white // White text for gradient buttons
              : TColor.black, // Black text for textGradient
          minWidth: double.maxFinite,
          elevation: type == RoundButtonType.bgGradient || type == RoundButtonType.bgSGradient ? 0 : elevation,
          color: type == RoundButtonType.bgGradient || type == RoundButtonType.bgSGradient
              ? Colors.transparent
              : TColor.lightGray, // Light gray for textGradient
          child: type == RoundButtonType.bgGradient || type == RoundButtonType.bgSGradient
              ? Text(
                  title,
                  style: TextStyle(
                    color: TColor.white, // White text
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                )
              : ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: TColor.primaryG, // [lightGray, darkRose]
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(Rect.fromLTRB(0, 0, bounds.width, bounds.height));
                  },
                  child: Text(
                    title,
                    style: TextStyle(
                      color: TColor.black, // Black text for gradient effect
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}