import 'package:flutter/material.dart';

class OnboardingContent extends StatelessWidget {
  final String image, text;

  const OnboardingContent({
    Key? key,
    required this.image,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          image,
          fit: BoxFit.cover,
        ),
        Container(
          color: Colors.black.withOpacity(0.4),
        ),
        Positioned(
          bottom: 100,
          left: 20,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
