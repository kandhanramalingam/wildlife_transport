import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/app_version.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
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
    _controller = AppDependencies.sessionController
      ..addListener(_onSessionChanged)
      ..initialize();
    unawaited(AppDependencies.offloadingSyncService.start());
  }

  void _onSessionChanged() {
    if (_controller.status == SessionStatus.unauthenticated) {
      unawaited(AppDependencies.tripLocationTracker.stop());
    } else if (_controller.status == SessionStatus.authenticated) {
      unawaited(AppDependencies.offloadingSyncService.flushPending());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return switch (_controller.status) {
          SessionStatus.checking => const _SplashScreen(),
          SessionStatus.authenticated => const HomeScreen(),
          SessionStatus.unauthenticated => const LoginScreen(),
        };
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Spacer(),
              Image(
                image: AssetImage('assets/branding/awa_transport_logo.png'),
                width: 280,
                height: 190,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppTheme.primary),
              Spacer(),
              AppVersionLabel(),
            ],
          ),
        ),
      ),
    );
  }
}
