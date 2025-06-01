// lib/data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Cache para usuarios (evitar consultas repetidas)
  final Map<String, UserModel> _userCache = {};

  // Obtener usuario por ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Verificar cache primero
      if (_userCache.containsKey(userId)) {
        return _userCache[userId];
      }

      print('🔍 Obteniendo usuario: $userId');

      final doc = await FirebaseService.users.doc(userId).get();

      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        // Guardar en cache
        _userCache[userId] = user;
        print('✅ Usuario encontrado: ${user.displayName}');
        return user;
      } else {
        print('❌ Usuario no encontrado: $userId');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo usuario $userId: $e');
      return null;
    }
  }

  // Obtener múltiples usuarios por IDs
  Future<Map<String, UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      final Map<String, UserModel> users = {};
      final List<String> uncachedIds = [];

      // Verificar cache primero
      for (String userId in userIds) {
        if (_userCache.containsKey(userId)) {
          users[userId] = _userCache[userId]!;
        } else {
          uncachedIds.add(userId);
        }
      }

      // Obtener usuarios no cacheados en lotes
      if (uncachedIds.isNotEmpty) {
        print('🔍 Obteniendo ${uncachedIds.length} usuarios de Firebase...');

        // Firestore permite máximo 10 elementos en whereIn
        final chunks = _chunkList(uncachedIds, 10);

        for (List<String> chunk in chunks) {
          final snapshot = await FirebaseService.users
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          for (var doc in snapshot.docs) {
            final user = UserModel.fromFirestore(doc);
            users[doc.id] = user;
            _userCache[doc.id] = user; // Guardar en cache
          }
        }
      }

      print('✅ Usuarios obtenidos: ${users.length}/${userIds.length}');
      return users;
    } catch (e) {
      print('❌ Error obteniendo usuarios múltiples: $e');
      return {};
    }
  }

  // Stream de usuario específico
  Stream<UserModel?> getUserStream(String userId) {
    return FirebaseService.users
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        _userCache[userId] = user; // Actualizar cache
        return user;
      }
      return null;
    });
  }

  // Actualizar usuario
  Future<void> updateUser(UserModel user) async {
    try {
      await FirebaseService.users.doc(user.id).update(user.toFirestore());
      _userCache[user.id] = user; // Actualizar cache
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      throw Exception('Error actualizando usuario: $e');
    }
  }

  // Buscar usuarios por nombre
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.length < 2) return [];

      final snapshot = await FirebaseService.users
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error buscando usuarios: $e');
      return [];
    }
  }

  // Obtener seguidores de un usuario
  Future<List<UserModel>> getUserFollowers(String userId) async {
    try {
      final userDoc = await FirebaseService.users.doc(userId).get();
      if (!userDoc.exists) return [];

      final user = UserModel.fromFirestore(userDoc);
      if (user.followers.isEmpty) return [];

      final followersMap = await getUsersByIds(user.followers);
      return followersMap.values.toList();
    } catch (e) {
      print('❌ Error obteniendo seguidores: $e');
      return [];
    }
  }

  // Obtener usuarios que sigue
  Future<List<UserModel>> getUserFollowing(String userId) async {
    try {
      final userDoc = await FirebaseService.users.doc(userId).get();
      if (!userDoc.exists) return [];

      final user = UserModel.fromFirestore(userDoc);
      if (user.following.isEmpty) return [];

      final followingMap = await getUsersByIds(user.following);
      return followingMap.values.toList();
    } catch (e) {
      print('❌ Error obteniendo siguiendo: $e');
      return [];
    }
  }

  // Seguir/dejar de seguir usuario
  Future<void> toggleFollowUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final currentUserRef = FirebaseService.users.doc(currentUserId);
        final targetUserRef = FirebaseService.users.doc(targetUserId);

        final currentUserDoc = await transaction.get(currentUserRef);
        final targetUserDoc = await transaction.get(targetUserRef);

        if (!currentUserDoc.exists || !targetUserDoc.exists) {
          throw Exception('Usuario no encontrado');
        }

        final currentUser = UserModel.fromFirestore(currentUserDoc);
        final targetUser = UserModel.fromFirestore(targetUserDoc);

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

        transaction.update(currentUserRef, {'following': currentFollowing});
        transaction.update(targetUserRef, {'followers': targetFollowers});
      });

      // Limpiar cache para que se actualice
      _userCache.remove(currentUserId);
      _userCache.remove(targetUserId);

    } catch (e) {
      print('❌ Error en follow/unfollow: $e');
      throw Exception('Error actualizando seguimiento: $e');
    }
  }

  // Verificar si un usuario sigue a otro
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final user = await getUserById(currentUserId);
      return user?.following.contains(targetUserId) ?? false;
    } catch (e) {
      print('❌ Error verificando seguimiento: $e');
      return false;
    }
  }

  // Limpiar cache (útil para logout)
  void clearCache() {
    _userCache.clear();
    print('🧹 Cache de usuarios limpiado');
  }

  // Obtener estadísticas del usuario
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        return {'followers': 0, 'following': 0, 'posts': 0};
      }

      // Obtener número de posts
      final postsSnapshot = await FirebaseService.posts
          .where('authorId', isEqualTo: userId)
          .get();

      return {
        'followers': user.followers.length,
        'following': user.following.length,
        'posts': postsSnapshot.docs.length,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {'followers': 0, 'following': 0, 'posts': 0};
    }
  }

  // Crear perfil de usuario
  Future<void> createUserProfile(UserModel user) async {
    try {
      await FirebaseService.users.doc(user.id).set(user.toFirestore());
      _userCache[user.id] = user;
      print('✅ Perfil de usuario creado: ${user.displayName}');
    } catch (e) {
      print('❌ Error creando perfil: $e');
      throw Exception('Error creando perfil de usuario: $e');
    }
  }

  // Verificar si existe el perfil del usuario
  Future<bool> userExists(String userId) async {
    try {
      final doc = await FirebaseService.users.doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error verificando usuario: $e');
      return false;
    }
  }

  // Funciones helper
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  // Obtener usuarios populares/sugeridos
  Future<List<UserModel>> getSuggestedUsers({int limit = 10}) async {
    try {
      final snapshot = await FirebaseService.users
          .orderBy('followers', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo usuarios sugeridos: $e');

      // Fallback: obtener usuarios recientes
      try {
        final fallbackSnapshot = await FirebaseService.users
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        return fallbackSnapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();
      } catch (fallbackError) {
        print('❌ Error en fallback: $fallbackError');
        return [];
      }
    }
  }
}