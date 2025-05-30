import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Registro con email y contraseña
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Crear perfil de usuario en Firestore
        await _createUserProfile(
          user: credential.user!,
          displayName: displayName,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Login con email y contraseña
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener datos del usuario actual
  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseService.users.doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Actualizar perfil de usuario
  Future<void> updateUserProfile(UserModel userModel) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      await FirebaseService.users.doc(user.uid).update(userModel.toFirestore());
    } catch (e) {
      throw Exception('Error actualizando perfil: $e');
    }
  }

  // Crear perfil inicial del usuario
  Future<void> _createUserProfile({
    required User user,
    required String displayName,
  }) async {
    final userModel = UserModel(
      id: user.uid,
      email: user.email!,
      displayName: displayName,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await FirebaseService.users.doc(user.uid).set(userModel.toFirestore());
  }

  // Manejar excepciones de autenticación
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'Email inválido';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
}