import 'package:flutter_test/flutter_test.dart';

import 'package:wildlife_transport/core/error/failure.dart';

void main() {
  test('unauthorized failures expose a UI-safe message', () {
    const failure = UnauthorizedFailure(
      'Driver not found with this phone number',
    );

    expect(failure.message, 'Driver not found with this phone number');
  });
}
