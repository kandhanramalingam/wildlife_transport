import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../home/home_screen.dart';
import '../presentation/session_controller.dart';
import 'login_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final SessionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppDependencies.sessionController..initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return switch (_controller.status) {
          SessionStatus.checking => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          SessionStatus.authenticated => const HomeScreen(),
          SessionStatus.unauthenticated => const LoginScreen(),
        };
      },
    );
  }
}
