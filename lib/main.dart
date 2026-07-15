import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(const WildlifeTransportApp());
}

class WildlifeTransportApp extends StatelessWidget {
  const WildlifeTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wildlife Transport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}
