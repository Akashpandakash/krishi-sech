import 'package:google_sign_in/google_sign_in.dart';
import 'package:krishi_sech/core/config/app_environment.dart';

/// Raised when the farmer dismisses the Google account chooser.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// Raised when Google sign-in is unusable — misconfigured, or unsupported on
/// this platform.
class GoogleSignInUnavailable implements Exception {
  const GoogleSignInUnavailable([this.message]);
  final String? message;
}

/// Thin wrapper over `google_sign_in` that yields the ID token the backend
/// verifies. No trust is placed in the client-side account details.
class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  bool get isConfigured => AppEnvironment.googleServerClientId.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // serverClientId is the WEB OAuth client. Android only mints an idToken
    // with the right audience when it is supplied.
    await _googleSignIn.initialize(
      serverClientId: AppEnvironment.googleServerClientId,
    );
    _initialized = true;
  }

  /// Returns a Google ID token to exchange with the backend.
  Future<String> authenticate() async {
    if (!isConfigured) {
      throw const GoogleSignInUnavailable('GOOGLE_SERVER_CLIENT_ID is not set');
    }
    await _ensureInitialized();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleSignInUnavailable(
        'Google sign-in is not supported on this platform',
      );
    }
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        // Almost always a missing/incorrect serverClientId, or a SHA-1 that is
        // not registered for this build's signing key.
        throw const GoogleSignInUnavailable('Google did not return an ID token');
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelled();
      }
      throw GoogleSignInUnavailable(error.description ?? error.code.name);
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await _googleSignIn.signOut();
    } on GoogleSignInException {
      // Signing out of Google must never block signing out of the app.
    }
  }
}
