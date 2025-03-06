import 'package:flutter/material.dart';
import '../common/colo_extension.dart';

enum RoundButtonType { bgGradient, bgSGradient, textGradient }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType? type;
  final VoidCallback onPressed;
  final double fontSize;
  final double elevation;
  final FontWeight fontWeight;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;

  const RoundButton({
    super.key,
    required this.title,
    this.type,
    this.fontSize = 16,
    this.elevation = 1,
    this.fontWeight = FontWeight.w700,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Define gradients using the provided color scheme
    final Gradient primaryGradient = LinearGradient(
      colors: [TColor.primary, TColor.primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final Gradient secondaryGradient = LinearGradient(
      colors: [TColor.secondary, TColor.secondaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final Gradient? effectiveGradient = gradient ??
        (type == RoundButtonType.bgSGradient
            ? secondaryGradient
            : primaryGradient);

    final Color effectiveBackgroundColor = backgroundColor ??
        (type == RoundButtonType.textGradient ? Colors.transparent : TColor.primary);

    final Color effectiveTextColor = textColor ??
        (type == RoundButtonType.textGradient ? TColor.textPrimary : Colors.white);

    return SizedBox(
      width: 150,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          color: effectiveGradient == null ? effectiveBackgroundColor : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: type == RoundButtonType.bgGradient || type == RoundButtonType.bgSGradient
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: MaterialButton(
          onPressed: onPressed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          textColor: effectiveTextColor,
          minWidth: double.maxFinite,
          elevation: 0,
          color: Colors.transparent,
          child: Text(
            title,
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}