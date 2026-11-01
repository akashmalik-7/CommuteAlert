import 'package:flutter/material.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading({required this.title, this.action, super.key});

  final String title;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        if (action != null)
          TextButton(onPressed: action, child: const Text('See All')),
      ],
    );
  }
}
