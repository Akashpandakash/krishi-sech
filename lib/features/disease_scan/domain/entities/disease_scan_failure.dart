sealed class DiseaseScanFailure implements Exception {
  const DiseaseScanFailure();
}

class DiseaseScanOfflineFailure extends DiseaseScanFailure {
  const DiseaseScanOfflineFailure();
}

class DiseaseScanTimeoutFailure extends DiseaseScanFailure {
  const DiseaseScanTimeoutFailure([this.message]);
  final String? message;
}

class DiseaseScanInvalidResponseFailure extends DiseaseScanFailure {
  const DiseaseScanInvalidResponseFailure();
}

class DiseaseScanInvalidImageFailure extends DiseaseScanFailure {
  const DiseaseScanInvalidImageFailure([this.message]);
  final String? message;
}

class DiseaseScanAuthenticationFailure extends DiseaseScanFailure {
  const DiseaseScanAuthenticationFailure([this.message]);
  final String? message;
}

class DiseaseScanQuotaFailure extends DiseaseScanFailure {
  const DiseaseScanQuotaFailure([this.message]);
  final String? message;
}

class DiseaseScanServerFailure extends DiseaseScanFailure {
  const DiseaseScanServerFailure(this.statusCode, [this.message]);

  final int statusCode;
  final String? message;
}
