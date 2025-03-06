import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:flutter/material.dart';

class RoundTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hitText; // Hint text
  final String icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? rigtIcon; // Right icon (typo in your code)
  final VoidCallback? onTap; // Add this

  const RoundTextField({
    super.key,
    required this.controller,
    required this.hitText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.rigtIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TColor.lightGray,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hitText,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Image.asset(icon, width: 20, height: 20, color: TColor.gray),
          ),
          suffixIcon: rigtIcon,
          border: InputBorder.none,
        ),
        onTap: onTap, // Pass the callback
      ),
    );
  }
}