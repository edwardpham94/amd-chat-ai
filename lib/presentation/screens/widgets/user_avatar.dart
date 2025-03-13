import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final String? imageUrl;
  final Color backgroundColor;

  const UserAvatar({
    super.key,
    this.size = 100,
    this.imageUrl,
    this.backgroundColor = const Color(0xFFFCE4EC),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Center(
          child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
        ),
      ),
    );
  }
}
