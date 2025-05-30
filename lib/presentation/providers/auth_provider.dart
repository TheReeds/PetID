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

  // Registro de usuario
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setState(AuthState.loading);
      _clearError();

      final credential = await _authRepository.signUp(
        email: email,
        password: password,
        displayName: displayName,
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
}