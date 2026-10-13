import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/core/config/app_version.dart';

void main() {
  testWidgets('version label displays the current release version', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppVersionLabel())),
    );

    expect(find.text('Version 1.5.0'), findsOneWidget);
  });
}
