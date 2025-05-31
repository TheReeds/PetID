import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthState _state = AuthState.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  User? _firebaseUser;

  // Getters
  AuthState get state => _state;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  AuthProvider() {
    _initializeAuth();
  }

  // Inicializar listener de autenticación
  void _initializeAuth() {
    _authRepository.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        await _loadUserData(user.uid);
        _setState(AuthState.authenticated);
      } else {
        _currentUser = null;
        _setState(AuthState.unauthenticated);
      }
    });
  }

  // Registro de usuario con datos completos
  Future<bool> signUp({
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
      _setState(AuthState.loading);
      _clearError();

      final credential = await _authRepository.signUp(
        email: email,
        password: password,
        displayName: displayName,
        fullName: fullName,
        phone: phone,
        address: address,
        dateOfBirth: dateOfBirth,
        gender: gender,
        profileImage: profileImage,
      );

      if (credential?.user != null) {
        await _loadUserData(credential!.user!.uid);
        _setState(AuthState.authenticated);
        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }

  // Inicio de sesión
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setState(AuthState.loading);
      _clearError();

      final credential = await _authRepository.signIn(
        email: email,
        password: password,
      );

      if (credential?.user != null) {
        await _loadUserData(credential!.user!.uid);
        _setState(AuthState.authenticated);
        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      _setState(AuthState.loading);
      await _authRepository.signOut();
      _currentUser = null;
      _firebaseUser = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
    }
  }

  // Actualizar perfil de usuario
  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      _setState(AuthState.loading);
      await _authRepository.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }

  // Actualizar foto de perfil
  Future<bool> updateProfilePhoto(File imageFile) async {
    try {
      _setState(AuthState.loading);
      await _authRepository.updateProfilePhoto(imageFile: imageFile);

      // Recargar datos del usuario para obtener la nueva URL
      await _loadUserData(_firebaseUser!.uid);
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }

  // Restablecer contraseña
  Future<bool> resetPassword(String email) async {
    try {
      _clearError();
      await _authRepository.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Enviar verificación de email
  Future<bool> sendEmailVerification() async {
    try {
      _clearError();
      await _authRepository.sendEmailVerification();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Actualizar email
  Future<bool> updateEmail(String newEmail) async {
    try {
      _setState(AuthState.loading);
      await _authRepository.updateEmail(newEmail);

      // Recargar datos del usuario
      await _loadUserData(_firebaseUser!.uid);
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }

  // Actualizar contraseña
  Future<bool> updatePassword(String newPassword) async {
    try {
      _clearError();
      await _authRepository.updatePassword(newPassword);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Eliminar cuenta
  Future<bool> deleteAccount() async {
    try {
      _setState(AuthState.loading);
      await _authRepository.deleteAccount();
      _currentUser = null;
      _firebaseUser = null;
      _setState(AuthState.unauthenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }
  Future<bool> signInWithGoogle() async {
    try {
      _setState(AuthState.loading);
      _clearError();

      final credential = await _authRepository.signInWithGoogle();

      if (credential?.user != null) {
        await _loadUserData(credential!.user!.uid);
        _setState(AuthState.authenticated);
        return true;
      }

      _setState(AuthState.unauthenticated);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }
  // Recargar datos del usuario
  Future<void> refreshUserData() async {
    if (_firebaseUser != null) {
      try {
        // Recargar usuario de Firebase Auth
        await _firebaseUser!.reload();
        _firebaseUser = FirebaseAuth.instance.currentUser;

        // Recargar datos de Firestore
        await _loadUserData(_firebaseUser!.uid);

        // Asegurar que el estado sea authenticated
        if (_currentUser != null) {
          _setState(AuthState.authenticated);
        }
      } catch (e) {
        print('Error refreshing user data: $e');
      }
    }
  }

  // Cargar datos del usuario desde Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final userData = await _authRepository.getCurrentUserData();
      _currentUser = userData;
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Métodos privados de estado
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() => _clearError();

  // Validaciones útiles
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  String? validateDisplayName(String displayName) {
    if (displayName.trim().isEmpty) {
      return 'El nombre de usuario es obligatorio';
    }
    if (displayName.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (displayName.trim().length > 20) {
      return 'El nombre no puede tener más de 20 caracteres';
    }
    return null;
  }

  String? validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    if (!isValidEmail(email)) {
      return 'Email inválido';
    }
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (!isValidPassword(password)) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? validatePhoneNumber(String phone) {
    if (phone.trim().isEmpty) return null; // Campo opcional
    if (phone.trim().length < 9) {
      return 'Número de teléfono inválido';
    }
    return null;
  }
}