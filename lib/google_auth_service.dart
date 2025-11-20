// google_auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithGoogle() async {
    // Use your web client ID (the one starting with numbers)
    const serverClientId = '884132780235-l2006bs6vgjkusinmu1f3mp0765so28q.apps.googleusercontent.com';

    // For Android, you don't need iOS client ID
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: serverClientId,
    );

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    return _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  bool isSignedIn() {
    return _supabase.auth.currentUser != null;
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  SupabaseClient get supabaseClient => _supabase;
}