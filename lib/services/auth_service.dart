import '../core/utils/helpers.dart';

class MockUser {
  final String uid;
  MockUser(this.uid);
}

class MockUserCredential {
  final MockUser? user;
  MockUserCredential(this.user);
}

class AuthService {
  AuthService();

  MockUser? get currentUser => null;

  Stream<MockUser?> get authStateChanges => Stream.value(null);

  Future<void> signOut() async {
    Helpers.log('AuthService', 'Signing out user');
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(dynamic) verificationCompleted,
    required Function(Exception) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    Helpers.log('AuthService', 'Initiating local mock phone verification for: $phoneNumber');
    // Simulate instant code sent
    await Future.delayed(const Duration(seconds: 1));
    codeSent('mock-verification-id', 123456);
  }

  Future<MockUserCredential?> signInWithCredential(dynamic credential) async {
    Helpers.log('AuthService', 'Verifying credential...');
    await Future.delayed(const Duration(seconds: 1));
    return MockUserCredential(MockUser('local-user-id'));
  }

  Future<MockUserCredential?> signInAnonymously() async {
    Helpers.log('AuthService', 'Anonymous auth successful!');
    return MockUserCredential(MockUser('local-anonymous-id'));
  }
}
