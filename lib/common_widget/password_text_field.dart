import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:flutter/material.dart';

class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hitText;
  final String icon;
  final bool obscureText;
  final ValueChanged<bool>? onToggleVisibility;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.hitText,
    required this.icon,
    this.obscureText = true,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    bool isVisible = !obscureText;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: TColor.primary, // Red border for focus
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: 50,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Image.asset(
              icon,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              color: TColor.primary, // Red icon
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: hitText,
                hintStyle: TextStyle(color: TColor.textSecondary, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: TColor.accent1, // Orange for toggle
            ),
            onPressed: () {
              if (onToggleVisibility != null) {
                onToggleVisibility!(!isVisible);
              }
            },
          ),
        ],
      ),
    );
  }
}