import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/comment_model.dart';
import '../services/firebase_service.dart';

class CommentRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final _uuid = const Uuid();

  // Obtener comentarios de un post
  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .where('isDeleted', isEqualTo: false)
        .where('replyToId', isNull: true) // Solo comentarios principales
        .orderBy('createdAt', descending: false) // Más antiguos primero
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CommentModel.fromFirestore(doc))
        .toList());
  }

  // Obtener respuestas a un comentario específico
  Stream<List<CommentModel>> getCommentReplies(String postId, String commentId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .where('replyToId', isEqualTo: commentId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CommentModel.fromFirestore(doc))
        .toList());
  }

  // Crear un nuevo comentario
  Future<String> createComment(CommentModel comment) async {
    try {
      final commentId = _uuid.v4();
      final commentWithId = CommentModel(
        id: commentId,
        postId: comment.postId,
        authorId: comment.authorId,
        content: comment.content,
        replyToId: comment.replyToId,
        createdAt: comment.createdAt,
        updatedAt: comment.updatedAt,
      );

      // Crear el comentario
      await _firestore
          .collection('posts')
          .doc(comment.postId)
          .collection('comments')
          .doc(commentId)
          .set(commentWithId.toFirestore());

      // Actualizar contador de comentarios del post
      await _updatePostCommentCount(comment.postId, 1);

      // Si es una respuesta, agregar al array de replies del comentario padre
      if (comment.replyToId != null) {
        await _addReplyToParentComment(comment.postId, comment.replyToId!, commentId);
      }

      return commentId;
    } catch (e) {
      throw Exception('Error creando comentario: $e');
    }
  }

  // Actualizar comentario
  Future<void> updateComment(String postId, String commentId, String newContent) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'content': newContent,
        'updatedAt': Timestamp.now(),
        'isEdited': true,
      });
    } catch (e) {
      throw Exception('Error actualizando comentario: $e');
    }
  }

  // Eliminar comentario (soft delete)
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      // Marcar como eliminado
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'isDeleted': true,
        'content': '[Comentario eliminado]',
        'updatedAt': Timestamp.now(),
      });

      // Decrementar contador del post
      await _updatePostCommentCount(postId, -1);

      // Si tiene respuestas, también las marcamos como eliminadas en cascada
      await _deleteCommentReplies(postId, commentId);
    } catch (e) {
      throw Exception('Error eliminando comentario: $e');
    }
  }

  // Dar/quitar like a un comentario
  Future<void> toggleCommentLike(String postId, String commentId, String userId) async {
    try {
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);

        if (!commentDoc.exists) {
          throw Exception('Comentario no encontrado');
        }

        final comment = CommentModel.fromFirestore(commentDoc);
        List<String> newLikes = List.from(comment.likes);

        if (comment.isLikedBy(userId)) {
          newLikes.remove(userId);
        } else {
          newLikes.add(userId);
        }

        transaction.update(commentRef, {
          'likes': newLikes,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Error actualizando like del comentario: $e');
    }
  }

  // Obtener comentario por ID
  Future<CommentModel?> getCommentById(String postId, String commentId) async {
    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (doc.exists) {
        return CommentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo comentario: $e');
    }
  }

  // Reportar comentario
  Future<void> reportComment({
    required String postId,
    required String commentId,
    required String reason,
    required String reporterId,
  }) async {
    try {
      final reportId = _uuid.v4();
      await _firestore.collection('comment_reports').doc(reportId).set({
        'id': reportId,
        'postId': postId,
        'commentId': commentId,
        'reporterId': reporterId,
        'reason': reason,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error reportando comentario: $e');
    }
  }

  // Obtener estadísticas de comentarios para un usuario
  Future<Map<String, dynamic>> getUserCommentStats(String userId) async {
    try {
      // Esta consulta puede ser costosa, considera implementar contadores
      final commentsQuery = await _firestore
          .collectionGroup('comments')
          .where('authorId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();

      final totalComments = commentsQuery.docs.length;
      final totalLikes = commentsQuery.docs.fold<int>(
        0,
            (sum, doc) {
          final data = doc.data();
          final likes = List<String>.from(data['likes'] ?? []);
          return sum + likes.length;
        },
      );

      return {
        'totalComments': totalComments,
        'totalLikes': totalLikes,
      };
    } catch (e) {
      throw Exception('Error obteniendo estadísticas: $e');
    }
  }

  // Buscar comentarios por contenido
  Future<List<CommentModel>> searchComments({
    required String postId,
    required String query,
  }) async {
    try {
      // Firestore no tiene búsqueda de texto completo nativa
      // Esta es una implementación básica
      final snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final allComments = snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();

      // Filtrar por contenido en el cliente
      return allComments.where((comment) =>
          comment.content.toLowerCase().contains(query.toLowerCase())).toList();
    } catch (e) {
      throw Exception('Error buscando comentarios: $e');
    }
  }

  // Métodos helper privados
  Future<void> _updatePostCommentCount(String postId, int increment) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(increment),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error actualizando contador de comentarios: $e');
    }
  }

  Future<void> _addReplyToParentComment(
      String postId, String parentCommentId, String replyId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(parentCommentId)
          .update({
        'replies': FieldValue.arrayUnion([replyId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error agregando respuesta al comentario padre: $e');
    }
  }

  Future<void> _deleteCommentReplies(String postId, String commentId) async {
    try {
      final repliesSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('replyToId', isEqualTo: commentId)
          .get();

      final batch = _firestore.batch();

      for (var doc in repliesSnapshot.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'content': '[Comentario eliminado]',
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();

      // Actualizar contador por cada respuesta eliminada
      if (repliesSnapshot.docs.isNotEmpty) {
        await _updatePostCommentCount(postId, -repliesSnapshot.docs.length);
      }
    } catch (e) {
      print('Error eliminando respuestas del comentario: $e');
    }
  }

  // Limpiar comentarios antiguos (tarea de mantenimiento)
  Future<void> cleanupDeletedComments(String postId) async {
    try {
      final oldDeletedComments = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('isDeleted', isEqualTo: true)
          .where('updatedAt',
          isLessThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 30))))
          .get();

      final batch = _firestore.batch();

      for (var doc in oldDeletedComments.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error limpiando comentarios eliminados: $e');
    }
  }
}