sealed class Failure implements Exception {
  final String message;

  const Failure(this.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'The request timed out. Please try again.',
  ]);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Invalid phone number or password',
  ]);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class DeliveryNotFoundFailure extends Failure {
  const DeliveryNotFoundFailure([super.message = 'Delivery not found']);
}

final class InactiveTripFailure extends Failure {
  const InactiveTripFailure([
    super.message = 'Delivery is not in an active trip state',
  ]);
}

final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Server error. Please try again later.',
  ]);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
