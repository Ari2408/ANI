import 'package:flutter/material.dart';

class ElderCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Border? border;
  final EdgeInsetsGeometry? padding;

  const ElderCard({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.border,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: border ?? Border.all(color: const Color(0xFF61C5B0).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF61C5B0).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
