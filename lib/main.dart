import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/session_gate.dart';

void main() {
  runApp(const WildlifeTransportApp());
}

class WildlifeTransportApp extends StatelessWidget {
  const WildlifeTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWA Transport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SessionGate(),
    );
  }
}
