import 'package:flutter/material.dart';

class ElderButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutline;

  const ElderButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isOutline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = backgroundColor ?? const Color(0xFF98DACB);
    final defaultTextColor = textColor ?? const Color(0xFF1B2824);

    if (isOutline) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.arrow_forward, color: const Color(0xFF1B2824)),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2824),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primaryColor, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.play_arrow, color: defaultTextColor, size: 24),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: defaultTextColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }
}
