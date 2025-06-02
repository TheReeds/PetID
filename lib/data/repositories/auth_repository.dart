import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/google_signin_service.dart';
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
    List<String>? interests,
    List<String>? languages,
    String? lifestyle,
    bool isOpenToMeetPetOwners = false,
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
          fullName: fullName ?? displayName,
          phone: phone,
          address: address,
          dateOfBirth: dateOfBirth,
          gender: gender,
          photoURL: photoURL,
          interests: interests ?? [],
          languages: languages ?? [],
          lifestyle: lifestyle,
          isOpenToMeetPetOwners: isOpenToMeetPetOwners,
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
    try {
      // Cerrar sesión de Google si está conectado
      if (await GoogleSignInService.isSignedInWithGoogle()) {
        await GoogleSignInService.signOutGoogle();
      }

      // Cerrar sesión de Firebase
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // MEJORADO: Obtener datos del usuario actual con retry y mejor manejo de errores
  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseService.users.doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }

      // Si el documento no existe, crear uno básico
      print('⚠️ Documento de usuario no encontrado, creando perfil básico...');
      await _createBasicUserProfile(user);

      // Intentar obtener de nuevo
      final newDoc = await FirebaseService.users.doc(user.uid).get();
      if (newDoc.exists) {
        return UserModel.fromFirestore(newDoc);
      }

      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // NUEVO: Crear perfil básico para usuarios existentes sin documento
  Future<void> _createBasicUserProfile(User user) async {
    final userModel = UserModel(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName ?? 'Usuario',
      fullName: user.displayName,
      photoURL: user.photoURL,
      phone: null,
      address: null,
      dateOfBirth: null,
      gender: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      interests: [],
      languages: [],
      lifestyle: null,
      isOpenToMeetPetOwners: false,
    );

    await FirebaseService.users.doc(user.uid).set(userModel.toFirestore());
  }

  // MEJORADO: Actualizar perfil de usuario con validación mejorada
  Future<void> updateUserProfile(UserModel userModel) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Validar datos antes de actualizar
      _validateUserModel(userModel);

      // Actualizar en Firestore con timestamp
      final updateData = userModel.toFirestore();
      updateData['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await FirebaseService.users.doc(user.uid).update(updateData);

      // Actualizar displayName en Firebase Auth si cambió
      if (user.displayName != userModel.displayName) {
        await user.updateDisplayName(userModel.displayName);
      }

      print('✅ Perfil actualizado exitosamente');
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
      throw Exception('Error actualizando perfil: $e');
    }
  }

  // NUEVO: Validar modelo de usuario
  void _validateUserModel(UserModel userModel) {
    if (userModel.displayName.trim().isEmpty) {
      throw Exception('El nombre de usuario no puede estar vacío');
    }

    if (userModel.displayName.trim().length < 3) {
      throw Exception('El nombre de usuario debe tener al menos 3 caracteres');
    }

    if (userModel.displayName.trim().length > 20) {
      throw Exception('El nombre de usuario no puede tener más de 20 caracteres');
    }

    if (userModel.email.trim().isEmpty) {
      throw Exception('El email no puede estar vacío');
    }

    // Validar teléfono si se proporciona
    if (userModel.phone != null && userModel.phone!.isNotEmpty) {
      if (userModel.phone!.length < 9) {
        throw Exception('Número de teléfono inválido');
      }
    }

    // Validar fecha de nacimiento
    if (userModel.dateOfBirth != null) {
      final now = DateTime.now();
      final age = now.year - userModel.dateOfBirth!.year;
      if (age < 13 || age > 120) {
        throw Exception('Fecha de nacimiento inválida');
      }
    }
  }

  // MEJORADO: Actualizar foto de perfil con mejor manejo de errores
  Future<void> updateProfilePhoto({
    required File imageFile,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      print('📷 Iniciando actualización de foto de perfil...');

      // Subir nueva imagen
      final photoURL = await StorageService.uploadUserProfilePhoto(
        userId: user.uid,
        imageFile: imageFile,
      );

      print('✅ Imagen subida exitosamente: $photoURL');

      // Actualizar en Firebase Auth
      await user.updatePhotoURL(photoURL);

      // Actualizar en Firestore
      await FirebaseService.users.doc(user.uid).update({
        'photoURL': photoURL,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Recargar usuario para obtener cambios
      await user.reload();

      print('✅ Foto de perfil actualizada exitosamente');
    } catch (e) {
      print('❌ Error actualizando foto de perfil: $e');
      throw Exception('Error actualizando foto de perfil: $e');
    }
  }

  // MEJORADO: Crear perfil inicial del usuario con todos los datos
  Future<void> _createUserProfile({
    required User user,
    required String displayName,
    String? fullName,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    String? photoURL,
    List<String>? interests,
    List<String>? languages,
    String? lifestyle,
    bool isOpenToMeetPetOwners = false,
  }) async {
    try {
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
        interests: interests ?? [],
        languages: languages ?? [],
        lifestyle: lifestyle,
        isOpenToMeetPetOwners: isOpenToMeetPetOwners,
      );

      await FirebaseService.users.doc(user.uid).set(userModel.toFirestore());
      print('✅ Perfil de usuario creado exitosamente');
    } catch (e) {
      print('❌ Error creando perfil: $e');
      throw Exception('Error creando perfil de usuario: $e');
    }
  }

  // Login con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final credential = await GoogleSignInService.signInWithGoogle();

      if (credential?.user != null) {
        // Verificar si es la primera vez que el usuario inicia sesión
        final userDoc = await FirebaseService.users.doc(credential!.user!.uid).get();

        if (!userDoc.exists) {
          // Crear perfil básico para nuevos usuarios de Google
          await _createUserProfileFromGoogle(credential.user!);
        } else {
          // Actualizar la información si es necesario
          await _updateUserFromGoogle(credential.user!);
        }
      }

      return credential;
    } catch (e) {
      throw Exception('Error en Google Sign In: $e');
    }
  }

  // Crear perfil para usuarios que se registran con Google
  Future<void> _createUserProfileFromGoogle(User user) async {
    final userModel = UserModel(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName ?? 'Usuario',
      fullName: user.displayName,
      photoURL: user.photoURL,
      phone: null,
      address: null,
      dateOfBirth: null,
      gender: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      interests: [],
      languages: [],
      lifestyle: null,
      isOpenToMeetPetOwners: false,
    );

    await FirebaseService.users.doc(user.uid).set(userModel.toFirestore());
  }

  // Actualizar información de usuarios existentes de Google
  Future<void> _updateUserFromGoogle(User user) async {
    await FirebaseService.users.doc(user.uid).update({
      'photoURL': user.photoURL,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // NUEVO: Refrescar datos del usuario actual
  Future<UserModel?> refreshCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      // Recargar usuario de Firebase Auth
      await user.reload();

      // Obtener datos actualizados de Firestore
      final doc = await FirebaseService.users.doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('❌ Error refreshing user data: $e');
      return null;
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

  // MEJORADO: Eliminar cuenta con mejor limpieza
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      print('🗑️ Iniciando eliminación de cuenta...');

      // Desconectar de Google si está conectado
      if (await GoogleSignInService.isSignedInWithGoogle()) {
        await GoogleSignInService.disconnectGoogle();
      }

      // TODO: Eliminar datos relacionados (posts, mascotas, chats, etc.)
      // Esto se implementará cuando tengamos los otros repositorios

      // Eliminar foto de perfil si existe
      final userData = await getCurrentUserData();
      if (userData?.photoURL != null) {
        try {
          await StorageService.deletePhoto(userData!.photoURL!);
        } catch (e) {
          print('⚠️ Error eliminando foto de perfil: $e');
        }
      }

      // Eliminar datos de Firestore
      await FirebaseService.users.doc(user.uid).delete();
      print('✅ Datos de Firestore eliminados');

      // Eliminar cuenta de Auth
      await user.delete();
      print('✅ Cuenta eliminada exitosamente');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error eliminando cuenta: $e');
    }
  }

  // NUEVO: Verificar si el usuario necesita reautenticación
  bool needsReauthentication() {
    final user = currentUser;
    if (user == null) return false;

    // Verificar si el último login fue hace más de 5 minutos
    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastSignIn);

    return difference.inMinutes > 5;
  }

  // NUEVO: Reautenticar usuario
  Future<void> reauthenticateUser(String password) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
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
      case 'requires-recent-login':
        return 'Por seguridad, debes iniciar sesión nuevamente';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}