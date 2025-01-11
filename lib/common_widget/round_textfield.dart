import 'package:flutter/material.dart';
import '../common/colo_extension.dart';

class RoundTextField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String hitText;
  final String icon;
  final VoidCallback? onTap;
  final Widget? rigtIcon;
  final bool obscureText;
  final EdgeInsets? margin;

  const RoundTextField({
    super.key,
    required this.hitText,
    required this.icon,
    this.controller,
    this.margin,
    this.keyboardType,
    this.obscureText = false,
    this.rigtIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Trigger the onTap callback passed to this widget
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: TColor.lightGray,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // Icon in the text field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Image.asset(
                icon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                color: TColor.gray,
              ),
            ),
            // TextField inside the row
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscureText,
                readOnly: onTap != null, // Disable keyboard if onTap is passed
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: hitText,
                  suffixIcon: rigtIcon,
                  hintStyle: TextStyle(color: TColor.gray, fontSize: 12),
                ),
                onTap: onTap, // Trigger onTap when text field is tapped
              ),
            ),
          ],
        ),
      ),
    );
  }
}
