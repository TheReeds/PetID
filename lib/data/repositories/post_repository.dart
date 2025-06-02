// lib/data/repositories/post_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final _uuid = const Uuid();

  // Obtener feed de publicaciones (timeline principal)
  Future<List<PostModel>> getFeedPosts({
    int page = 0,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = FirebaseService.posts
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Para paginación con cursor
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo feed: $e');
      throw Exception('Error obteniendo feed: $e');
    }
  }

  // Obtener publicaciones del usuario
  Stream<List<PostModel>> getUserPosts(String userId) {
    return FirebaseService.posts
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList());
  }

  // Obtener publicaciones de una mascota específica
  Stream<List<PostModel>> getPetPosts(String petId) {
    return FirebaseService.posts
        .where('petId', isEqualTo: petId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList());
  }

  // Crear nueva publicación
  Future<String> createPost(PostModel post) async {
    try {
      final postId = _uuid.v4();

      // Crear el post con el ID generado
      final postData = {
        ...post.toFirestore(),
        'id': postId,
      };

      await FirebaseService.posts.doc(postId).set(postData);

      return postId;
    } catch (e) {
      print('Error creando publicación: $e');
      throw Exception('Error creando publicación: $e');
    }
  }

  // Actualizar publicación
  Future<void> updatePost(PostModel post) async {
    try {
      final updateData = post.toFirestore();
      updateData['updatedAt'] = Timestamp.now();

      await FirebaseService.posts.doc(post.id).update(updateData);
    } catch (e) {
      print('Error actualizando publicación: $e');
      throw Exception('Error actualizando publicación: $e');
    }
  }

  // Eliminar publicación
  Future<void> deletePost(String postId, String authorId) async {
    try {
      final doc = await FirebaseService.posts.doc(postId).get();
      if (!doc.exists) {
        throw Exception('Publicación no encontrada');
      }

      final post = PostModel.fromFirestore(doc);
      if (post.authorId != authorId) {
        throw Exception('No tienes permisos para eliminar esta publicación');
      }

      await FirebaseService.posts.doc(postId).delete();
    } catch (e) {
      print('Error eliminando publicación: $e');
      throw Exception('Error eliminando publicación: $e');
    }
  }

  // Toggle like en publicación
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final docRef = FirebaseService.posts.doc(postId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw Exception('Publicación no encontrada');
        }

        final post = PostModel.fromFirestore(doc);
        List<String> likes = List.from(post.likes);

        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }

        transaction.update(docRef, {
          'likes': likes,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      print('Error actualizando like: $e');
      throw Exception('Error actualizando like: $e');
    }
  }

  // Agregar comentario
  Future<void> addComment(String postId, String comment, String userId) async {
    try {
      final commentId = _uuid.v4();

      // Crear el comentario en la subcolección
      await FirebaseService.posts
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set({
        'id': commentId,
        'postId': postId,
        'authorId': userId,
        'content': comment,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Incrementar contador de comentarios
      await FirebaseService.posts.doc(postId).update({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error agregando comentario: $e');
      throw Exception('Error agregando comentario: $e');
    }
  }

  // Buscar publicaciones
  Future<List<PostModel>> searchPosts({
    String? query,
    List<String>? hashtags,
    PostType? type,
    String? location,
  }) async {
    try {
      Query baseQuery = FirebaseService.posts.where('isPublic', isEqualTo: true);

      // Filtrar por tipo si se especifica
      if (type != null) {
        baseQuery = baseQuery.where('type', isEqualTo: type.toString().split('.').last);
      }

      // Filtrar por hashtags si se especifican
      if (hashtags != null && hashtags.isNotEmpty) {
        baseQuery = baseQuery.where('hashtags', arrayContainsAny: hashtags);
      }

      final snapshot = await baseQuery
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      List<PostModel> posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      // Filtro de texto en cliente (Firestore no soporta full-text search nativo)
      if (query != null && query.isNotEmpty) {
        posts = posts.where((post) =>
            post.content.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }

      return posts;
    } catch (e) {
      print('Error buscando publicaciones: $e');
      throw Exception('Error buscando publicaciones: $e');
    }
  }

  // Obtener publicaciones por hashtag
  Future<List<PostModel>> getPostsByHashtag(String hashtag) async {
    try {
      final snapshot = await FirebaseService.posts
          .where('hashtags', arrayContains: hashtag)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo posts por hashtag: $e');
      throw Exception('Error obteniendo posts por hashtag: $e');
    }
  }

  // Reportar publicación
  Future<void> reportPost(String postId, String reason, String reporterId) async {
    try {
      final reportId = _uuid.v4();

      await _firestore.collection('reports').doc(reportId).set({
        'id': reportId,
        'postId': postId,
        'reporterId': reporterId,
        'reason': reason,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error reportando publicación: $e');
      throw Exception('Error reportando publicación: $e');
    }
  }

  // Obtener publicaciones de mascotas perdidas
  Future<List<PostModel>> getLostPetPosts() async {
    try {
      final snapshot = await FirebaseService.posts
          .where('type', isEqualTo: 'announcement')
          .where('hashtags', arrayContains: 'MascotaPerdida')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo mascotas perdidas: $e');
      throw Exception('Error obteniendo mascotas perdidas: $e');
    }
  }

  // Obtener comentarios de una publicación
  Stream<List<CommentModel>> getPostComments(String postId) {
    return FirebaseService.posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CommentModel.fromFirestore(doc))
        .toList());
  }

  // Obtener publicaciones populares (más likes)
  Future<List<PostModel>> getPopularPosts({int limit = 10}) async {
    try {
      // Como Firestore no permite orderBy en arrays, obtenemos posts recientes
      // y los ordenamos localmente por número de likes
      final snapshot = await FirebaseService.posts
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      List<PostModel> posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      // Ordenar por número de likes
      posts.sort((a, b) => b.likes.length.compareTo(a.likes.length));

      return posts.take(limit).toList();
    } catch (e) {
      print('Error obteniendo posts populares: $e');
      throw Exception('Error obteniendo posts populares: $e');
    }
  }

  // Obtener posts cercanos por ubicación
  Future<List<PostModel>> getNearbyPosts({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
  }) async {
    try {
      // Firestore no tiene consultas geoespaciales nativas eficientes
      // Para una implementación completa, considerarías usar GeoFlutterFire
      final snapshot = await FirebaseService.posts
          .where('isPublic', isEqualTo: true)
          .where('location', isNotEqualTo: null)
          .orderBy('location')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo posts cercanos: $e');
      throw Exception('Error obteniendo posts cercanos: $e');
    }
  }

  // Obtener un post específico por ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await FirebaseService.posts.doc(postId).get();
      if (doc.exists) {
        return PostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error obteniendo post por ID: $e');
      throw Exception('Error obteniendo post por ID: $e');
    }
  }

  // Verificar si existe un post
  Future<bool> postExists(String postId) async {
    try {
      final doc = await FirebaseService.posts.doc(postId).get();
      return doc.exists;
    } catch (e) {
      print('Error verificando existencia del post: $e');
      return false;
    }
  }
}

// Modelo para comentarios
class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}