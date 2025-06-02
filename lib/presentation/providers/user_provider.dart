// lib/presentation/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  // Estado de carga
  bool _isLoading = false;
  String? _errorMessage;

  // Cache de usuarios
  final Map<String, UserModel> _userCache = {};

  // Listas de usuarios
  List<UserModel> _suggestedUsers = [];
  List<UserModel> _searchResults = [];

  // Estadísticas de usuarios
  final Map<String, Map<String, int>> _userStatsCache = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get suggestedUsers => _suggestedUsers;
  List<UserModel> get searchResults => _searchResults;

  // NUEVO: Obtener usuario desde cache
  UserModel? getUserFromCache(String userId) {
    return _userCache[userId];
  }

  // MANTENER COMPATIBILIDAD: Método usado en posts y otros componentes
  UserModel? getUserForPost(String userId) {
    return getUserFromCache(userId);
  }

  // NUEVO: Obtener múltiples usuarios desde cache
  Map<String, UserModel> getUsersFromCache(List<String> userIds) {
    final Map<String, UserModel> result = {};
    for (String userId in userIds) {
      if (_userCache.containsKey(userId)) {
        result[userId] = _userCache[userId]!;
      }
    }
    return result;
  }

  // Obtener usuario por ID (con cache)
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Verificar cache primero
      if (_userCache.containsKey(userId)) {
        return _userCache[userId];
      }

      _setLoading(true);
      final user = await _userRepository.getUserById(userId);

      if (user != null) {
        _userCache[userId] = user;
      }

      _setLoading(false);
      return user;
    } catch (e) {
      _setError('Error cargando usuario: $e');
      _setLoading(false);
      return null;
    }
  }

  // NUEVO: Precargar usuarios para el feed
  Future<void> preloadUsersForFeed(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return;

      // Filtrar IDs que no están en cache
      final uncachedIds = userIds.where((id) => !_userCache.containsKey(id)).toList();

      if (uncachedIds.isEmpty) return;

      print('📥 Precargando ${uncachedIds.length} usuarios para el feed...');

      final users = await _userRepository.getUsersByIds(uncachedIds);

      // Agregar al cache
      _userCache.addAll(users);

      print('✅ ${users.length} usuarios precargados exitosamente');
      notifyListeners();
    } catch (e) {
      print('❌ Error precargando usuarios: $e');
    }
  }

  // Cargar usuarios sugeridos
  Future<void> loadSuggestedUsers({int limit = 10}) async {
    try {
      _setLoading(true);
      _clearError();

      final users = await _userRepository.getSuggestedUsers(limit: limit);
      _suggestedUsers = users;

      // Agregar al cache
      for (var user in users) {
        _userCache[user.id] = user;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error cargando usuarios sugeridos: $e');
      _setLoading(false);
    }
  }

  // Buscar usuarios
  Future<void> searchUsers(String query) async {
    try {
      if (query.trim().length < 2) {
        _searchResults = [];
        notifyListeners();
        return;
      }

      _setLoading(true);
      _clearError();

      final users = await _userRepository.searchUsers(query.trim());
      _searchResults = users;

      // Agregar al cache
      for (var user in users) {
        _userCache[user.id] = user;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error buscando usuarios: $e');
      _setLoading(false);
    }
  }

  // Seguir/dejar de seguir usuario
  Future<bool> toggleFollowUser(String currentUserId, String targetUserId) async {
    try {
      _setLoading(true);
      await _userRepository.toggleFollowUser(currentUserId, targetUserId);

      // Actualizar cache local
      _updateFollowInCache(currentUserId, targetUserId);

      // Invalidar estadísticas
      _userStatsCache.remove(currentUserId);
      _userStatsCache.remove(targetUserId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error actualizando seguimiento: $e');
      _setLoading(false);
      return false;
    }
  }

  // NUEVO: Actualizar seguimiento en cache local
  void _updateFollowInCache(String currentUserId, String targetUserId) {
    final currentUser = _userCache[currentUserId];
    final targetUser = _userCache[targetUserId];

    if (currentUser != null && targetUser != null) {
      List<String> currentFollowing = List.from(currentUser.following);
      List<String> targetFollowers = List.from(targetUser.followers);

      if (currentFollowing.contains(targetUserId)) {
        // Dejar de seguir
        currentFollowing.remove(targetUserId);
        targetFollowers.remove(currentUserId);
      } else {
        // Seguir
        currentFollowing.add(targetUserId);
        targetFollowers.add(currentUserId);
      }

      // Actualizar usuarios en cache
      _userCache[currentUserId] = currentUser.copyWith(following: currentFollowing);
      _userCache[targetUserId] = targetUser.copyWith(followers: targetFollowers);
    }
  }

  // Verificar si un usuario sigue a otro
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      // Verificar cache primero
      final currentUser = _userCache[currentUserId];
      if (currentUser != null) {
        return currentUser.following.contains(targetUserId);
      }

      // Si no está en cache, consultar repositorio
      return await _userRepository.isFollowing(currentUserId, targetUserId);
    } catch (e) {
      print('❌ Error verificando seguimiento: $e');
      return false;
    }
  }

  // NUEVO: Obtener estadísticas del usuario
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Verificar cache de estadísticas
      if (_userStatsCache.containsKey(userId)) {
        return _userStatsCache[userId]!;
      }

      final stats = await _userRepository.getUserStats(userId);
      _userStatsCache[userId] = stats;

      return stats;
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {'followers': 0, 'following': 0, 'posts': 0};
    }
  }

  // NUEVO: Actualizar usuario en cache
  void updateUserInCache(UserModel user) {
    _userCache[user.id] = user;

    // Actualizar en listas si existe
    final suggestedIndex = _suggestedUsers.indexWhere((u) => u.id == user.id);
    if (suggestedIndex != -1) {
      _suggestedUsers[suggestedIndex] = user;
    }

    final searchIndex = _searchResults.indexWhere((u) => u.id == user.id);
    if (searchIndex != -1) {
      _searchResults[searchIndex] = user;
    }

    notifyListeners();
  }

  // NUEVO: Invalidar cache de usuario específico
  void invalidateUserCache(String userId) {
    _userCache.remove(userId);
    _userStatsCache.remove(userId);
    notifyListeners();
  }

  // Obtener seguidores de un usuario
  Future<List<UserModel>> getUserFollowers(String userId) async {
    try {
      _setLoading(true);
      final followers = await _userRepository.getUserFollowers(userId);

      // Agregar al cache
      for (var user in followers) {
        _userCache[user.id] = user;
      }

      _setLoading(false);
      return followers;
    } catch (e) {
      _setError('Error cargando seguidores: $e');
      _setLoading(false);
      return [];
    }
  }

  // Obtener usuarios que sigue
  Future<List<UserModel>> getUserFollowing(String userId) async {
    try {
      _setLoading(true);
      final following = await _userRepository.getUserFollowing(userId);

      // Agregar al cache
      for (var user in following) {
        _userCache[user.id] = user;
      }

      _setLoading(false);
      return following;
    } catch (e) {
      _setError('Error cargando siguiendo: $e');
      _setLoading(false);
      return [];
    }
  }

  // NUEVO: Limpiar búsqueda
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // NUEVO: Refrescar usuarios sugeridos
  Future<void> refreshSuggestedUsers() async {
    _suggestedUsers = [];
    await loadSuggestedUsers();
  }

  // Limpiar cache (útil para logout)
  void clearCache() {
    _userCache.clear();
    _userStatsCache.clear();
    _suggestedUsers = [];
    _searchResults = [];
    _userRepository.clearCache();
    notifyListeners();
    print('🧹 Cache de UserProvider limpiado');
  }

  // NUEVO: Obtener usuarios compatibles basado en intereses
  Future<List<UserModel>> getCompatibleUsers(String userId, {int limit = 10}) async {
    try {
      final currentUser = await getUserById(userId);
      if (currentUser == null || currentUser.interests.isEmpty) {
        return await _userRepository.getSuggestedUsers(limit: limit);
      }

      // Por ahora, usar usuarios sugeridos y filtrar por compatibilidad
      // En el futuro se podría implementar una consulta más específica
      final allUsers = await _userRepository.getSuggestedUsers(limit: limit * 2);

      // Calcular compatibilidad y ordenar
      final compatibleUsers = allUsers
          .where((user) => user.id != userId)
          .map((user) => {
        'user': user,
        'score': currentUser.calculateCompatibilityScore(user)
      })
          .where((entry) => (entry['score'] as double) > 0.3) // Mínimo 30% compatibilidad
          .toList()
        ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      return compatibleUsers
          .take(limit)
          .map((entry) => entry['user'] as UserModel)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo usuarios compatibles: $e');
      return [];
    }
  }

  // NUEVO: Batch update de usuarios (útil para actualizaciones masivas)
  void batchUpdateUsers(Map<String, UserModel> users) {
    _userCache.addAll(users);

    // Actualizar listas si es necesario
    for (var user in users.values) {
      final suggestedIndex = _suggestedUsers.indexWhere((u) => u.id == user.id);
      if (suggestedIndex != -1) {
        _suggestedUsers[suggestedIndex] = user;
      }

      final searchIndex = _searchResults.indexWhere((u) => u.id == user.id);
      if (searchIndex != -1) {
        _searchResults[searchIndex] = user;
      }
    }

    notifyListeners();
  }

  // NUEVO: Obtener información de cache
  Map<String, dynamic> getCacheInfo() {
    return {
      'usersCached': _userCache.length,
      'statsCached': _userStatsCache.length,
      'suggestedUsers': _suggestedUsers.length,
      'searchResults': _searchResults.length,
    };
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
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

  // NUEVO: Dispose override para limpiar recursos
  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}