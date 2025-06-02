import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/notification_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthState _state = AuthState.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  User? _firebaseUser;

  // NUEVO: Cache de datos del usuario para evitar consultas innecesarias
  DateTime? _lastUserDataRefresh;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Getters
  AuthState get state => _state;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  // NUEVO: Verificar si los datos están actualizados
  bool get isUserDataStale {
    if (_lastUserDataRefresh == null) return true;
    return DateTime.now().difference(_lastUserDataRefresh!) > _cacheValidDuration;
  }

  AuthProvider() {
    _initializeAuth();
  }

  // Inicializar listener de autenticación
  void _initializeAuth() {
    _authRepository.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        await _loadUserData(user.uid);

        if (_currentUser != null) {
          await _setupNotifications();
        }

        _setState(AuthState.authenticated);
      } else {
        _currentUser = null;
        _lastUserDataRefresh = null;
        _setState(AuthState.unauthenticated);
      }
    });
  }

  // MEJORADO: Registro de usuario con datos completos
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
    List<String>? interests,
    List<String>? languages,
    String? lifestyle,
    bool isOpenToMeetPetOwners = false,
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
        interests: interests,
        languages: languages,
        lifestyle: lifestyle,
        isOpenToMeetPetOwners: isOpenToMeetPetOwners,
      );

      if (credential?.user != null) {
        await _loadUserData(credential!.user!.uid);
        await _setupNotifications();
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
        await _setupNotifications();
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

  // Login con Google
  Future<bool> signInWithGoogle() async {
    try {
      _setState(AuthState.loading);
      _clearError();

      final credential = await _authRepository.signInWithGoogle();

      if (credential?.user != null) {
        await _loadUserData(credential!.user!.uid);
        await _setupNotifications();
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

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      _setState(AuthState.loading);

      await _teardownNotifications();
      await _authRepository.signOut();

      _currentUser = null;
      _firebaseUser = null;
      _lastUserDataRefresh = null;

      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
    }
  }

  // MEJORADO: Actualizar perfil de usuario con validación
  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      _setState(AuthState.loading);

      // Validar datos antes de enviar
      final validationError = _validateProfileData(updatedUser);
      if (validationError != null) {
        _setError(validationError);
        _setState(AuthState.error);
        return false;
      }

      await _authRepository.updateUserProfile(updatedUser);

      // Actualizar usuario local y cache
      _currentUser = updatedUser;
      _lastUserDataRefresh = DateTime.now();

      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }

  // NUEVO: Validar datos del perfil
  String? _validateProfileData(UserModel user) {
    if (user.displayName.trim().isEmpty) {
      return 'El nombre de usuario es obligatorio';
    }

    if (user.displayName.trim().length < 3) {
      return 'El nombre de usuario debe tener al menos 3 caracteres';
    }

    if (user.displayName.trim().length > 20) {
      return 'El nombre de usuario no puede tener más de 20 caracteres';
    }

    if (user.phone != null && user.phone!.isNotEmpty && user.phone!.length < 9) {
      return 'Número de teléfono inválido';
    }

    if (user.dateOfBirth != null) {
      final age = DateTime.now().year - user.dateOfBirth!.year;
      if (age < 13) {
        return 'Debes tener al menos 13 años para usar la aplicación';
      }
      if (age > 120) {
        return 'Fecha de nacimiento inválida';
      }
    }

    return null;
  }

  // MEJORADO: Actualizar foto de perfil con mejor manejo
  Future<bool> updateProfilePhoto(File imageFile) async {
    try {
      _setState(AuthState.loading);

      await _authRepository.updateProfilePhoto(imageFile: imageFile);

      // Recargar datos del usuario para obtener la nueva URL
      await _forceRefreshUserData();

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

      // Verificar si necesita reautenticación
      if (_authRepository.needsReauthentication()) {
        _setError('Por seguridad, debes iniciar sesión nuevamente para cambiar tu email');
        _setState(AuthState.error);
        return false;
      }

      await _authRepository.updateEmail(newEmail);
      await _forceRefreshUserData();

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

      // Verificar si necesita reautenticación
      if (_authRepository.needsReauthentication()) {
        _setError('Por seguridad, debes iniciar sesión nuevamente para cambiar tu contraseña');
        return false;
      }

      await _authRepository.updatePassword(newPassword);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // NUEVO: Reautenticar usuario
  Future<bool> reauthenticateUser(String password) async {
    try {
      _setState(AuthState.loading);
      await _authRepository.reauthenticateUser(password);
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }

  // Eliminar cuenta
  Future<bool> deleteAccount() async {
    try {
      _setState(AuthState.loading);

      await _teardownNotifications();
      await _authRepository.deleteAccount();

      _currentUser = null;
      _firebaseUser = null;
      _lastUserDataRefresh = null;

      _setState(AuthState.unauthenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setState(AuthState.error);
      return false;
    }
  }

  // MEJORADO: Recargar datos del usuario con cache inteligente
  Future<void> refreshUserData() async {
    if (_firebaseUser != null) {
      try {
        // Solo recargar si los datos están obsoletos o se fuerza
        if (isUserDataStale) {
          await _forceRefreshUserData();
        }
      } catch (e) {
        print('❌ Error refreshing user data: $e');
      }
    }
  }

  // NUEVO: Forzar recarga de datos del usuario
  Future<void> _forceRefreshUserData() async {
    if (_firebaseUser == null) return;

    try {
      // Recargar usuario de Firebase Auth
      await _firebaseUser!.reload();
      _firebaseUser = FirebaseAuth.instance.currentUser;

      // Recargar datos de Firestore
      final userData = await _authRepository.refreshCurrentUserData();
      if (userData != null) {
        _currentUser = userData;
        _lastUserDataRefresh = DateTime.now();

        if (_state == AuthState.authenticated) {
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error force refreshing user data: $e');
    }
  }

  // Configurar notificaciones para usuario autenticado
  Future<void> _setupNotifications() async {
    if (_currentUser == null) return;

    try {
      if (kDebugMode) {
        print('🔔 Configurando notificaciones para: ${_currentUser!.displayName}');
      }

      await NotificationService.subscribeToAllNotifications();
      await NotificationService.subscribeToEventNotifications();
      await NotificationService.saveDeviceToken(_currentUser!.id);

      if (kDebugMode) {
        print('✅ Notificaciones configuradas correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error configurando notificaciones: $e');
      }
    }
  }

  // Desconfigurar notificaciones para logout
  Future<void> _teardownNotifications() async {
    try {
      if (kDebugMode) {
        print('🔕 Desonfigurando notificaciones...');
      }

      await NotificationService.unsubscribeFromAllNotifications();
      await NotificationService.unsubscribeFromEventNotifications();
      await NotificationService.clearAllNotifications();

      if (kDebugMode) {
        print('✅ Notificaciones desconfiguradas');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error desonfigurando notificaciones: $e');
      }
    }
  }

  // MEJORADO: Cargar datos del usuario desde Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final userData = await _authRepository.getCurrentUserData();
      if (userData != null) {
        _currentUser = userData;
        _lastUserDataRefresh = DateTime.now();
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  // NUEVO: Obtener información del cache
  Map<String, dynamic> getCacheInfo() {
    return {
      'hasCurrentUser': _currentUser != null,
      'lastRefresh': _lastUserDataRefresh?.toIso8601String(),
      'isStale': isUserDataStale,
      'cacheValidUntil': _lastUserDataRefresh?.add(_cacheValidDuration).toIso8601String(),
    };
  }

  // NUEVO: Invalidar cache de usuario
  void invalidateUserCache() {
    _lastUserDataRefresh = null;
    notifyListeners();
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

  // NUEVO: Validar intereses
  String? validateInterests(List<String> interests) {
    if (interests.length > 10) {
      return 'Máximo 10 intereses permitidos';
    }
    return null;
  }

  // NUEVO: Validar idiomas
  String? validateLanguages(List<String> languages) {
    if (languages.length > 5) {
      return 'Máximo 5 idiomas permitidos';
    }
    return null;
  }
}