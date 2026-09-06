import 'package:flutter/material.dart';
import 'package:shadow/core/theme.dart';
import 'package:shadow/features/onboarding/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shadow',
      debugShowCheckedModeBanner: false,
      theme: ShadowTheme.onboardingTheme,
      home: const OnboardingScreen(),
    );
  }
}
