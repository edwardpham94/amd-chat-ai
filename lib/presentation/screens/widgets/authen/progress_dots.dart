import 'package:flutter/material.dart';

class ProgressDots extends StatelessWidget {
  final int total;
  final int current;

  const ProgressDots({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (index) => Container(
          width: 24,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color:
                index == current
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
