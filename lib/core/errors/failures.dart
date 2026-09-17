abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class RouteFailure extends Failure {
  const RouteFailure(super.message);
}

class TrackingFailure extends Failure {
  const TrackingFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class LocationServicesFailure extends Failure {
  const LocationServicesFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
