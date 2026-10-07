import '../entities/guest_phone.dart';
import '../entities/guest_profile.dart';
import '../entities/otp_challenge.dart';

/// Contract the presentation layer depends on for guest entry + authentication
/// (architecture.md §4). Implemented by `AuthRepositoryImpl` over either the
/// dummy or the API data source — callers never know which.
///
/// Every method throws a `Failure` (via `ErrorMapper`) for infrastructure
/// errors. Expected authentication branch points (wrong code, lock-out) are
/// returned as [OtpVerification] values, not thrown.
abstract interface class AuthRepository {
  /// Returns the session persisted from a previous run, or `null` if the guest
  /// is not signed in. The stored token is re-validated against the backend
  /// (`me`); a rejected token is cleared and `null` returned.
  Future<AuthSession?> restoreSession();

  /// Asks the backend to send a verification code to [phone].
  Future<OtpChallenge> requestOtp(GuestPhone phone);

  /// Requests a fresh code for an existing challenge, resetting its attempts.
  Future<OtpChallenge> resendOtp(OtpChallenge challenge);

  /// Submits [code] for [challenge].
  Future<OtpVerification> verifyOtp({
    required OtpChallenge challenge,
    required String code,
  });

  /// Saves the first-time guest's name and email, returning the completed
  /// session.
  Future<AuthSession> completeProfile({
    required AuthSession session,
    required String fullName,
    required String email,
  });

  /// Guest-initiated sign-out: revokes the token on the backend, then clears
  /// the stored token and any in-memory session. The local session is cleared
  /// even when the revoke call fails (offline) — the guest asked to leave.
  Future<void> signOut();

  /// Clears the stored token and in-memory session without calling the
  /// backend — for a token the backend has already rejected (session expiry).
  Future<void> clearLocalSession();
}
