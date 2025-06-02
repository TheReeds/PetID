import 'package:flutter/foundation.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/comment_repository.dart';

enum CommentState { idle, loading, loaded, error }

class CommentProvider extends ChangeNotifier {
  final CommentRepository _commentRepository = CommentRepository();

  CommentState _state = CommentState.idle;
  Map<String, List<CommentModel>> _postComments = {}; // postId -> comments
  Map<String, List<CommentModel>> _commentReplies = {}; // commentId -> replies
  String? _errorMessage;
  bool _isSubmitting = false;

  // Getters
  CommentState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == CommentState.loading;
  bool get isSubmitting => _isSubmitting;

  // Obtener comentarios de un post
  List<CommentModel> getPostComments(String postId) {
    return _postComments[postId] ?? [];
  }

  // Obtener respuestas de un comentario
  List<CommentModel> getCommentReplies(String commentId) {
    return _commentReplies[commentId] ?? [];
  }

  // Cargar comentarios de un post
  Future<void> loadPostComments(String postId) async {
    try {
      _setState(CommentState.loading);
      _clearError();

      _commentRepository.getPostComments(postId).listen((comments) {
        _postComments[postId] = comments;
        _setState(CommentState.loaded);

        // Cargar respuestas para comentarios que las tienen
        for (final comment in comments) {
          if (comment.hasReplies) {
            _loadCommentReplies(postId, comment.id);
          }
        }
      }, onError: (error) {
        _setError('Error cargando comentarios: $error');
      });
    } catch (e) {
      _setError('Error: $e');
    }
  }

  // Cargar respuestas de un comentario específico
  Future<void> _loadCommentReplies(String postId, String commentId) async {
    try {
      _commentRepository.getCommentReplies(postId, commentId).listen((replies) {
        _commentReplies[commentId] = replies;
        notifyListeners();
      });
    } catch (e) {
      print('Error cargando respuestas del comentario: $e');
    }
  }

  // Agregar nuevo comentario
  Future<bool> addComment({
    required String postId,
    required String authorId,
    required String content,
    String? replyToId,
  }) async {
    if (content.trim().isEmpty) {
      _setError('El comentario no puede estar vacío');
      return false;
    }

    try {
      _isSubmitting = true;
      notifyListeners();
      _clearError();

      final comment = CommentModel.create(
        postId: postId,
        authorId: authorId,
        content: content.trim(),
        replyToId: replyToId,
      );

      final commentId = await _commentRepository.createComment(comment);

      // Actualizar comentario con el ID real
      final createdComment = comment.copyWith().copyWith();
      final finalComment = CommentModel(
        id: commentId,
        postId: createdComment.postId,
        authorId: createdComment.authorId,
        content: createdComment.content,
        replyToId: createdComment.replyToId,
        createdAt: createdComment.createdAt,
        updatedAt: createdComment.updatedAt,
      );

      // Agregar a la lista local
      if (replyToId != null) {
        // Es una respuesta
        _commentReplies[replyToId] = [...(_commentReplies[replyToId] ?? []), finalComment];
      } else {
        // Es un comentario principal
        _postComments[postId] = [...(_postComments[postId] ?? []), finalComment];
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _setError('Error agregando comentario: $e');
      return false;
    }
  }

  // Editar comentario
  Future<bool> editComment({
    required String postId,
    required String commentId,
    required String newContent,
  }) async {
    if (newContent.trim().isEmpty) {
      _setError('El comentario no puede estar vacío');
      return false;
    }

    try {
      _isSubmitting = true;
      notifyListeners();
      _clearError();

      await _commentRepository.updateComment(postId, commentId, newContent.trim());

      // Actualizar en las listas locales
      _updateCommentInLists(postId, commentId, (comment) =>
          comment.copyWith(content: newContent.trim(), isEdited: true));

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _setError('Error editando comentario: $e');
      return false;
    }
  }

  // Eliminar comentario
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      _isSubmitting = true;
      notifyListeners();
      _clearError();

      await _commentRepository.deleteComment(postId, commentId);

      // Marcar como eliminado en las listas locales
      _updateCommentInLists(postId, commentId, (comment) =>
          comment.copyWith(content: '[Comentario eliminado]', isDeleted: true));

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _setError('Error eliminando comentario: $e');
      return false;
    }
  }

  // Dar/quitar like a comentario
  Future<bool> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    try {
      // Actualización optimista
      _updateCommentInLists(postId, commentId, (comment) {
        List<String> newLikes = List.from(comment.likes);
        if (comment.isLikedBy(userId)) {
          newLikes.remove(userId);
        } else {
          newLikes.add(userId);
        }
        return comment.copyWith(likes: newLikes);
      });

      notifyListeners();

      // Actualizar en el servidor
      await _commentRepository.toggleCommentLike(postId, commentId, userId);
      return true;
    } catch (e) {
      // Revertir cambio optimista en caso de error
      _updateCommentInLists(postId, commentId, (comment) {
        List<String> newLikes = List.from(comment.likes);
        if (comment.isLikedBy(userId)) {
          newLikes.add(userId);
        } else {
          newLikes.remove(userId);
        }
        return comment.copyWith(likes: newLikes);
      });

      notifyListeners();
      _setError('Error actualizando like: $e');
      return false;
    }
  }

  // Reportar comentario
  Future<bool> reportComment({
    required String postId,
    required String commentId,
    required String reason,
    required String reporterId,
  }) async {
    try {
      await _commentRepository.reportComment(
        postId: postId,
        commentId: commentId,
        reason: reason,
        reporterId: reporterId,
      );
      return true;
    } catch (e) {
      _setError('Error reportando comentario: $e');
      return false;
    }
  }

  // Buscar comentarios
  Future<List<CommentModel>> searchComments({
    required String postId,
    required String query,
  }) async {
    try {
      if (query.trim().isEmpty) return [];
      return await _commentRepository.searchComments(
        postId: postId,
        query: query.trim(),
      );
    } catch (e) {
      _setError('Error buscando comentarios: $e');
      return [];
    }
  }

  // Obtener estadísticas de comentarios de un usuario
  Future<Map<String, dynamic>> getUserCommentStats(String userId) async {
    try {
      return await _commentRepository.getUserCommentStats(userId);
    } catch (e) {
      _setError('Error obteniendo estadísticas: $e');
      return {'totalComments': 0, 'totalLikes': 0};
    }
  }

  // Obtener conteo de comentarios para un post
  int getCommentsCount(String postId) {
    final comments = _postComments[postId] ?? [];
    int totalCount = comments.length;

    // Agregar respuestas
    for (final comment in comments) {
      totalCount += _commentReplies[comment.id]?.length ?? 0;
    }

    return totalCount;
  }

  // Verificar si hay comentarios cargados para un post
  bool hasCommentsLoaded(String postId) {
    return _postComments.containsKey(postId);
  }

  // Limpiar comentarios de un post específico
  void clearPostComments(String postId) {
    _postComments.remove(postId);

    // Limpiar respuestas relacionadas
    final comments = _postComments[postId] ?? [];
    for (final comment in comments) {
      _commentReplies.remove(comment.id);
    }

    notifyListeners();
  }

  // Refrescar comentarios de un post
  Future<void> refreshPostComments(String postId) async {
    clearPostComments(postId);
    await loadPostComments(postId);
  }

  // Métodos helper privados
  void _updateCommentInLists(
      String postId,
      String commentId,
      CommentModel Function(CommentModel) updater,
      ) {
    // Buscar en comentarios principales
    final postCommentsList = _postComments[postId];
    if (postCommentsList != null) {
      final index = postCommentsList.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _postComments[postId]![index] = updater(postCommentsList[index]);
        return;
      }
    }

    // Buscar en respuestas
    for (final replyList in _commentReplies.values) {
      final index = replyList.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        final parentCommentId = replyList[index].replyToId;
        if (parentCommentId != null) {
          _commentReplies[parentCommentId]![index] = updater(replyList[index]);
        }
        return;
      }
    }
  }

  // Métodos de estado
  void _setState(CommentState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = CommentState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Limpiar todos los datos (útil para logout)
  void clear() {
    _postComments.clear();
    _commentReplies.clear();
    _state = CommentState.idle;
    _errorMessage = null;
    _isSubmitting = false;
    notifyListeners();
  }
}