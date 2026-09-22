import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/auth/screens/login_screen.dart';

void main() {
  test('accepts ten-digit mobile numbers beginning with zero', () {
    expect(validateMobileNumber('0824168888'), isNull);
    expect(validateMobileNumber(' 0824168888 '), isNull);
  });

  test('rejects missing or malformed mobile numbers', () {
    expect(validateMobileNumber(''), 'Mobile number is required');
    expect(
      validateMobileNumber('082416888'),
      'Enter a valid 10-digit mobile number',
    );
    expect(
      validateMobileNumber('082416888x'),
      'Enter a valid 10-digit mobile number',
    );
  });
}
