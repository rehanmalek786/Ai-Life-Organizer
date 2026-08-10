import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUp(String email, String password, String displayName) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await cred.user?.updateDisplayName(displayName.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Error code: ${e.code}\nMessage: ${e.message}';
    } catch (e) {
      return 'Non-Firebase error: $e';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Error code: ${e.code}\nMessage: ${e.message}';
    } catch (e) {
      return 'Non-Firebase error: $e';
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Error code: ${e.code}\nMessage: ${e.message}';
    } catch (e) {
      return 'Non-Firebase error: $e';
    }
  }
}
