import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// User-facing release version. Keep synchronized with `pubspec.yaml`.
const appVersion = '1.5.1';

class AppVersionLabel extends StatelessWidget {
  final Color? color;

  const AppVersionLabel({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Version $appVersion',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, color: color ?? AppTheme.textSecondary),
    );
  }
}
