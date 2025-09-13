import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Register or add role to an existing user
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception('Email Sign-In failed: $e');
    }
  }

  Future<User?> registerUser(String email, String password, String role) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // User is already signed in, try to link email/password if not already linked
        try {
          await user.linkWithCredential(
            EmailAuthProvider.credential(email: email, password: password),
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            // If email/password is already linked, sign in with it
            UserCredential userCredential = await _auth
                .signInWithEmailAndPassword(email: email, password: password);
            user = userCredential.user;
          } else {
            rethrow;
          }
        }
      } else {
        // No user signed in, try to sign up
        try {
          UserCredential userCredential = await _auth
              .createUserWithEmailAndPassword(email: email, password: password);
          user = userCredential.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // If email is already in use, sign in the user
            UserCredential userCredential = await _auth
                .signInWithEmailAndPassword(email: email, password: password);
            user = userCredential.user;
          } else {
            rethrow;
          }
        }
      }

      if (user != null) {
        // Add role in Firestore
        await _firestoreService.addUserRole(user.uid, role);
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception('Authentication failed: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Check if user is registered as labor or customer
  Future<bool> isUserRegistered(String uid, bool isLabor) async {
    final roles = await _firestoreService.getUserRoles(uid);
    return roles.contains(isLabor ? 'labor' : 'customer');
  }

  // Link Google Sign-In with email/password credential
  Future<void> linkGoogleWithEmail(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.linkWithCredential(credential);
      }
    } catch (e) {
      throw Exception('Failed to link email credential: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
