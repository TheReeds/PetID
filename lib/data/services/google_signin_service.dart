import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  static final FirebaseAuth _auth = FirebaseService.auth;

  // Iniciar sesión con Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Activar el flujo de autenticación
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el sign-in
        return null;
      }

      // Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear credenciales para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con las credenciales de Google
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      return userCredential;
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  // Cerrar sesión de Google
  static Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error al cerrar sesión de Google: $e');
    }
  }

  // Verificar si el usuario está conectado con Google
  static Future<bool> isSignedInWithGoogle() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  // Obtener información del usuario de Google actualmente conectado
  static GoogleSignInAccount? get currentGoogleUser => _googleSignIn.currentUser;

  // Desconectar completamente la cuenta de Google
  static Future<void> disconnectGoogle() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      print('Error al desconectar Google: $e');
    }
  }
}