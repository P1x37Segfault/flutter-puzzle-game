import 'package:flutter/material.dart';

/// A widget that displays a circular icon with a specified color and an optional tap handler.
class CircularIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const CircularIcon({
    required this.icon,
    required this.color,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 60, color: Colors.white),
      ),
    );
  }
}
