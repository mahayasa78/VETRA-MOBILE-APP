import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw "User tidak ditemukan";
      } else if (e.code == 'wrong-password') {
        throw "Password salah";
      } else {
        throw e.message ?? "Login gagal";
      }
    } catch (e) {
      throw "Terjadi kesalahan";
    }
  }

  Future<User?> register(String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': 'user',
          'created_at': Timestamp.now(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Register gagal";
    }
  }

  /// Google Sign-In — login atau registrasi otomatis jika belum ada akun
  Future<User?> signInWithGoogle() async {
    try {
      // Selalu lakukan signOut terlebih dahulu untuk menghapus cache login Google
      // sehingga dialog pemilihan akun (account picker) selalu muncul.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Trigger Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      // Ambil credential dari Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in ke Firebase
      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        // Cek apakah dokumen user sudah ada di Firestore
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          // Pengguna baru — buat dokumen Firestore dengan role 'user'
          await docRef.set({
            'name': user.displayName ?? 'Pengguna Google',
            'email': user.email ?? '',
            'profilePic': user.photoURL ?? '',
            'role': 'user',
            'created_at': Timestamp.now(),
          });
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Login dengan Google gagal";
    } catch (e) {
      throw "Terjadi kesalahan saat login dengan Google: $e";
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}