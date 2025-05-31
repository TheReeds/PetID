import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Registro con email y contraseña + datos adicionales
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
    String? fullName,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    File? profileImage,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Actualizar displayName en Firebase Auth
        await credential.user!.updateDisplayName(displayName);

        // Subir imagen de perfil si existe
        String? photoURL;
        if (profileImage != null) {
          photoURL = await StorageService.uploadUserProfilePhoto(
            userId: credential.user!.uid,
            imageFile: profileImage,
          );
        }

        // Crear perfil completo de usuario en Firestore
        await _createUserProfile(
          user: credential.user!,
          displayName: displayName,
          fullName: fullName ?? displayName, // Si no hay fullName, usar displayName
          phone: phone,
          address: address,
          dateOfBirth: dateOfBirth,
          gender: gender,
          photoURL: photoURL,
        );

        // Recargar el usuario para obtener los cambios
        await credential.user!.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error durante el registro: $e');
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

  // Actualizar foto de perfil
  Future<void> updateProfilePhoto({
    required File imageFile,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Subir nueva imagen
      final photoURL = await StorageService.uploadUserProfilePhoto(
        userId: user.uid,
        imageFile: imageFile,
      );

      // Actualizar en Firestore
      await FirebaseService.users.doc(user.uid).update({
        'photoURL': photoURL,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Error actualizando foto de perfil: $e');
    }
  }

  // Crear perfil inicial del usuario con todos los datos
  Future<void> _createUserProfile({
    required User user,
    required String displayName,
    String? fullName,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    String? photoURL,
  }) async {
    final userModel = UserModel(
      id: user.uid,
      email: user.email!,
      displayName: displayName,
      fullName: fullName,
      photoURL: photoURL,
      phone: phone,
      address: address,
      dateOfBirth: dateOfBirth,
      gender: gender,
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
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
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

  // Verificar email
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
    }
  }

  // Actualizar email
  Future<void> updateEmail(String newEmail) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      await user.updateEmail(newEmail);
      await FirebaseService.users.doc(user.uid).update({
        'email': newEmail,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Actualizar contraseña
  Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Eliminar cuenta
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Eliminar datos de Firestore
      await FirebaseService.users.doc(user.uid).delete();

      // Eliminar cuenta de Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
}