import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

enum UserState { idle, loading, loaded, error }

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  UserState _state = UserState.idle;
  Map<String, UserModel> _users = {}; // Cache local de usuarios
  List<UserModel> _suggestedUsers = [];
  Map<String, int> _userStats = {};
  String? _errorMessage;

  // Getters
  UserState get state => _state;
  Map<String, UserModel> get users => _users;
  List<UserModel> get suggestedUsers => _suggestedUsers;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == UserState.loading;

  // Obtener usuario por ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Verificar cache local primero
      if (_users.containsKey(userId)) {
        return _users[userId];
      }

      print('🔍 UserProvider: Obteniendo usuario $userId');

      final user = await _userRepository.getUserById(userId);
      if (user != null) {
        _users[userId] = user;
        notifyListeners();
      }

      return user;
    } catch (e) {
      print('❌ Error en UserProvider.getUserById: $e');
      return null;
    }
  }

  // Obtener múltiples usuarios (para feed de posts)
  Future<void> loadUsersForPosts(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return;

      // Filtrar IDs que ya tenemos en cache
      final uncachedIds = userIds
          .where((id) => !_users.containsKey(id))
          .toList();

      if (uncachedIds.isEmpty) return;

      print('🔍 UserProvider: Cargando ${uncachedIds.length} usuarios para posts');

      _setState(UserState.loading);

      final usersMap = await _userRepository.getUsersByIds(uncachedIds);

      // Agregar usuarios al cache local
      _users.addAll(usersMap);

      _setState(UserState.loaded);

      print('✅ UserProvider: ${usersMap.length} usuarios cargados');
    } catch (e) {
      print('❌ Error cargando usuarios para posts: $e');
      _setError('Error cargando información de usuarios');
    }
  }

  // Obtener información del usuario para un post específico
  UserModel? getUserForPost(String authorId) {
    return _users[authorId];
  }

  // Actualizar usuario
  Future<bool> updateUser(UserModel user) async {
    try {
      _setState(UserState.loading);

      await _userRepository.updateUser(user);

      // Actualizar cache local
      _users[user.id] = user;

      _setState(UserState.loaded);
      return true;
    } catch (e) {
      _setError('Error actualizando usuario: $e');
      return false;
    }
  }

  // Buscar usuarios
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.length < 2) return [];

      return await _userRepository.searchUsers(query);
    } catch (e) {
      print('❌ Error buscando usuarios: $e');
      return [];
    }
  }

  // Cargar usuarios sugeridos
  Future<void> loadSuggestedUsers() async {
    try {
      _setState(UserState.loading);

      _suggestedUsers = await _userRepository.getSuggestedUsers(limit: 10);

      // Agregar usuarios sugeridos al cache
      for (var user in _suggestedUsers) {
        _users[user.id] = user;
      }

      _setState(UserState.loaded);
    } catch (e) {
      _setError('Error cargando usuarios sugeridos: $e');
    }
  }

  // Seguir/dejar de seguir usuario
  Future<bool> toggleFollowUser(String currentUserId, String targetUserId) async {
    try {
      await _userRepository.toggleFollowUser(currentUserId, targetUserId);

      // Actualizar cache local si tenemos los usuarios
      if (_users.containsKey(currentUserId) && _users.containsKey(targetUserId)) {
        final currentUser = _users[currentUserId]!;
        final targetUser = _users[targetUserId]!;

        List<String> currentFollowing = List.from(currentUser.following);
        List<String> targetFollowers = List.from(targetUser.followers);

        if (currentFollowing.contains(targetUserId)) {
          currentFollowing.remove(targetUserId);
          targetFollowers.remove(currentUserId);
        } else {
          currentFollowing.add(targetUserId);
          targetFollowers.add(currentUserId);
        }

        _users[currentUserId] = currentUser.copyWith(following: currentFollowing);
        _users[targetUserId] = targetUser.copyWith(followers: targetFollowers);

        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Error actualizando seguimiento: $e');
      return false;
    }
  }

  // Verificar si un usuario sigue a otro
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      // Verificar cache primero
      if (_users.containsKey(currentUserId)) {
        return _users[currentUserId]!.following.contains(targetUserId);
      }

      return await _userRepository.isFollowing(currentUserId, targetUserId);
    } catch (e) {
      print('❌ Error verificando seguimiento: $e');
      return false;
    }
  }

  // Obtener estadísticas del usuario
  Future<Object> getUserStats(String userId) async {
    try {
      if (_userStats.containsKey(userId)) {
        return _userStats[userId]!;
      }

      final stats = await _userRepository.getUserStats(userId);
      _userStats[userId] = stats as int;

      return stats;
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {'followers': 0, 'following': 0, 'posts': 0};
    }
  }

  // Obtener seguidores
  Future<List<UserModel>> getUserFollowers(String userId) async {
    try {
      final followers = await _userRepository.getUserFollowers(userId);

      // Agregar seguidores al cache
      for (var user in followers) {
        _users[user.id] = user;
      }

      return followers;
    } catch (e) {
      print('❌ Error obteniendo seguidores: $e');
      return [];
    }
  }

  // Obtener siguiendo
  Future<List<UserModel>> getUserFollowing(String userId) async {
    try {
      final following = await _userRepository.getUserFollowing(userId);

      // Agregar siguiendo al cache
      for (var user in following) {
        _users[user.id] = user;
      }

      return following;
    } catch (e) {
      print('❌ Error obteniendo siguiendo: $e');
      return [];
    }
  }

  // Stream de usuario específico
  Stream<UserModel?> getUserStream(String userId) {
    return _userRepository.getUserStream(userId);
  }

  // Crear perfil de usuario
  Future<bool> createUserProfile(UserModel user) async {
    try {
      _setState(UserState.loading);

      await _userRepository.createUserProfile(user);

      // Agregar al cache local
      _users[user.id] = user;

      _setState(UserState.loaded);
      return true;
    } catch (e) {
      _setError('Error creando perfil: $e');
      return false;
    }
  }

  // Verificar si existe el usuario
  Future<bool> userExists(String userId) async {
    try {
      return await _userRepository.userExists(userId);
    } catch (e) {
      print('❌ Error verificando usuario: $e');
      return false;
    }
  }

  // Precargar usuarios para feed (llamar al cargar posts)
  Future<void> preloadUsersForFeed(List<String> authorIds) async {
    final uniqueIds = authorIds.toSet().toList();
    await loadUsersForPosts(uniqueIds);
  }

  // Obtener nombre para mostrar
  String getDisplayName(String userId) {
    final user = _users[userId];
    if (user != null) {
      return user.displayName.isNotEmpty ? user.displayName : user.fullName ?? 'Usuario';
    }
    return 'Usuario ${userId.substring(0, 8)}';
  }

  // Obtener foto de perfil
  String? getProfilePhoto(String userId) {
    return _users[userId]?.photoURL;
  }

  // Métodos de estado
  void _setState(UserState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = UserState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Limpiar datos (útil para logout)
  void clear() {
    _users.clear();
    _suggestedUsers.clear();
    _userStats.clear();
    _state = UserState.idle;
    _errorMessage = null;
    _userRepository.clearCache();
    notifyListeners();
    print('🧹 UserProvider: Cache limpiado');
  }

  // Actualizar un usuario específico en cache
  void updateUserInCache(UserModel user) {
    _users[user.id] = user;
    notifyListeners();
  }

  // Obtener todos los usuarios cacheados
  List<UserModel> getAllCachedUsers() {
    return _users.values.toList();
  }

  // Verificar si un usuario está en cache
  bool hasUser(String userId) {
    return _users.containsKey(userId);
  }
}