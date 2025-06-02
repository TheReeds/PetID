import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/comment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class CommentsScreen extends StatefulWidget {
  final PostModel post;

  const CommentsScreen({
    super.key,
    required this.post,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final commentProvider = Provider.of<CommentProvider>(context, listen: false);
    await commentProvider.loadPostComments(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Comentarios',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A7AA7),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A7AA7)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF4A7AA7)),
            onPressed: _showCommentsOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header del post
          _buildPostHeader(),

          // Lista de comentarios
          Expanded(
            child: Consumer<CommentProvider>(
              builder: (context, commentProvider, child) {
                if (commentProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
                  );
                }

                if (commentProvider.errorMessage != null) {
                  return _buildErrorState(commentProvider.errorMessage!);
                }

                final comments = commentProvider.getPostComments(widget.post.id);

                if (comments.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => commentProvider.refreshPostComments(widget.post.id),
                  color: const Color(0xFF4A7AA7),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentCard(comments[index]);
                    },
                  ),
                );
              },
            ),
          ),

          // Input para comentar
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final author = userProvider.getUserForPost(widget.post.authorId);

          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: author?.photoURL != null
                    ? NetworkImage(author!.photoURL!)
                    : null,
                backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                child: author?.photoURL == null
                    ? Text(
                  author?.displayName.isNotEmpty == true
                      ? author!.displayName.substring(0, 1).toUpperCase()
                      : widget.post.authorId.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF4A7AA7),
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author?.displayName ?? author?.fullName ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.post.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCommentContent(comment),
          _buildCommentReplies(comment),
        ],
      ),
    );
  }

  Widget _buildCommentContent(CommentModel comment) {
    return Consumer2<UserProvider, AuthProvider>(
      builder: (context, userProvider, authProvider, child) {
        final author = userProvider.getUserForPost(comment.authorId);
        final currentUserId = authProvider.currentUser?.id ?? '';
        final isOwnComment = comment.authorId == currentUserId;
        final isLiked = comment.isLikedBy(currentUserId);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del comentario
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: author?.photoURL != null
                        ? NetworkImage(author!.photoURL!)
                        : null,
                    backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                    child: author?.photoURL == null
                        ? Text(
                      author?.displayName.isNotEmpty == true
                          ? author!.displayName.substring(0, 1).toUpperCase()
                          : comment.authorId.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4A7AA7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                author?.displayName ?? author?.fullName ?? 'Usuario',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (author?.isVerified == true) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 14,
                                color: Color(0xFF4A7AA7),
                              ),
                            ],
                            if (comment.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(editado)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _formatCommentTime(comment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onPressed: () => _showCommentOptions(comment, isOwnComment),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Contenido del comentario
              if (!comment.isDeleted)
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                  ),
                )
              else
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500,
                  ),
                ),

              const SizedBox(height: 12),

              // Acciones del comentario
              if (!comment.isDeleted)
                Row(
                  children: [
                    // Like
                    InkWell(
                      onTap: () => _toggleCommentLike(comment),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isLiked ? Colors.red : Colors.grey.shade600,
                            ),
                            if (comment.likes.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likes.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Responder
                    InkWell(
                      onTap: () => _startReply(comment),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reply,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Responder',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (comment.hasReplies) ...[
                      const Spacer(),
                      InkWell(
                        onTap: () => _toggleRepliesVisibility(comment),
                        child: Text(
                          'Ver ${comment.repliesCount} respuesta${comment.repliesCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF4A7AA7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentReplies(CommentModel comment) {
    return Consumer<CommentProvider>(
      builder: (context, commentProvider, child) {
        final replies = commentProvider.getCommentReplies(comment.id);

        if (replies.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(left: 32, right: 16, bottom: 16),
          child: Column(
            children: replies.map((reply) => _buildReplyCard(reply)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildReplyCard(CommentModel reply) {
    return Consumer2<UserProvider, AuthProvider>(
      builder: (context, userProvider, authProvider, child) {
        final author = userProvider.getUserForPost(reply.authorId);
        final currentUserId = authProvider.currentUser?.id ?? '';
        final isOwnReply = reply.authorId == currentUserId;
        final isLiked = reply.isLikedBy(currentUserId);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: author?.photoURL != null
                        ? NetworkImage(author!.photoURL!)
                        : null,
                    backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                    child: author?.photoURL == null
                        ? Text(
                      author?.displayName.isNotEmpty == true
                          ? author!.displayName.substring(0, 1).toUpperCase()
                          : reply.authorId.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4A7AA7),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author?.displayName ?? author?.fullName ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatCommentTime(reply.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 14),
                    onPressed: () => _showCommentOptions(reply, isOwnReply),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!reply.isDeleted)
                Text(
                  reply.content,
                  style: const TextStyle(fontSize: 14),
                )
              else
                Text(
                  reply.content,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500,
                  ),
                ),
              const SizedBox(height: 8),
              if (!reply.isDeleted)
                Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleCommentLike(reply),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: isLiked ? Colors.red : Colors.grey.shade600,
                          ),
                          if (reply.likes.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${reply.likes.length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Consumer2<CommentProvider, AuthProvider>(
      builder: (context, commentProvider, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Indicador de respuesta
                if (_replyingToCommentId != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A7AA7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: 16,
                          color: const Color(0xFF4A7AA7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Respondiendo a $_replyingToUsername',
                            style: TextStyle(
                              color: const Color(0xFF4A7AA7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: _cancelReply,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                // Input de comentario
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: authProvider.currentUser?.photoURL != null
                          ? NetworkImage(authProvider.currentUser!.photoURL!)
                          : null,
                      backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                      child: authProvider.currentUser?.photoURL == null
                          ? const Icon(Icons.person, color: Color(0xFF4A7AA7), size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null
                              ? 'Escribe una respuesta...'
                              : 'Escribe un comentario...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: Color(0xFF4A7AA7)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: commentProvider.isSubmitting
                            ? Colors.grey.shade400
                            : const Color(0xFF4A7AA7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: commentProvider.isSubmitting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: commentProvider.isSubmitting ? null : _submitComment,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin comentarios aún',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sé el primero en comentar esta publicación',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al cargar comentarios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComments,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos de acción
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final commentProvider = Provider.of<CommentProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comentar')),
      );
      return;
    }

    final success = await commentProvider.addComment(
      postId: widget.post.id,
      authorId: authProvider.currentUser!.id,
      content: content,
      replyToId: _replyingToCommentId,
    );

    if (success) {
      _commentController.clear();
      _cancelReply();
      HapticFeedback.lightImpact();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commentProvider.errorMessage ?? 'Error al enviar comentario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleCommentLike(CommentModel comment) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final commentProvider = Provider.of<CommentProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    commentProvider.toggleCommentLike(
      postId: widget.post.id,
      commentId: comment.id,
      userId: authProvider.currentUser!.id,
    );

    HapticFeedback.lightImpact();
  }

  void _startReply(CommentModel comment) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final author = userProvider.getUserForPost(comment.authorId);

    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUsername = author?.displayName ?? author?.fullName ?? 'Usuario';
    });

    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
  }

  void _toggleRepliesVisibility(CommentModel comment) {
    // Implementar lógica para mostrar/ocultar respuestas si es necesario
    // Por ahora las respuestas siempre se muestran
  }

  void _showCommentOptions(CommentModel comment, bool isOwnComment) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnComment) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _editComment(comment);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteComment(comment);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Responder'),
                onTap: () {
                  Navigator.pop(context);
                  _startReply(comment);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Reportar'),
                onTap: () {
                  Navigator.pop(context);
                  _reportComment(comment);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editComment(CommentModel comment) {
    final controller = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar comentario'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Escribe tu comentario...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final commentProvider = Provider.of<CommentProvider>(context, listen: false);

              final success = await commentProvider.editComment(
                postId: widget.post.id,
                commentId: comment.id,
                newContent: controller.text.trim(),
              );

              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(commentProvider.errorMessage ?? 'Error al editar comentario'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteComment(CommentModel comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Estás seguro de que quieres eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final commentProvider = Provider.of<CommentProvider>(context, listen: false);

              final success = await commentProvider.deleteComment(
                widget.post.id,
                comment.id,
              );

              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(commentProvider.errorMessage ?? 'Error al eliminar comentario'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _reportComment(CommentModel comment) {
    final reasons = [
      'Spam',
      'Contenido ofensivo',
      'Acoso',
      'Información falsa',
      'Otro',
    ];

    String selectedReason = reasons.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar comentario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Por qué reportas este comentario?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: reasons.map((reason) => DropdownMenuItem(
                value: reason,
                child: Text(reason),
              )).toList(),
              onChanged: (value) => selectedReason = value!,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final commentProvider = Provider.of<CommentProvider>(context, listen: false);

              if (authProvider.currentUser != null) {
                final success = await commentProvider.reportComment(
                  postId: widget.post.id,
                  commentId: comment.id,
                  reason: selectedReason,
                  reporterId: authProvider.currentUser!.id,
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reporte enviado exitosamente')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  void _showCommentsOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Actualizar comentarios'),
              onTap: () {
                Navigator.pop(context);
                _loadComments();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Buscar en comentarios'),
              onTap: () {
                Navigator.pop(context);
                _showSearchComments();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchComments() {
    showDialog(
      context: context,
      builder: (context) => _SearchCommentsDialog(post: widget.post),
    );
  }

  String _formatCommentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Widget auxiliar para búsqueda de comentarios
class _SearchCommentsDialog extends StatefulWidget {
  final PostModel post;

  const _SearchCommentsDialog({required this.post});

  @override
  State<_SearchCommentsDialog> createState() => _SearchCommentsDialogState();
}

class _SearchCommentsDialogState extends State<_SearchCommentsDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<CommentModel> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Buscar comentarios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en comentarios...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                suffixIcon: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : null,
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                child: Text(
                  _searchController.text.isEmpty
                      ? 'Escribe para buscar comentarios'
                      : 'No se encontraron comentarios',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return _buildSearchResultItem(_searchResults[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(CommentModel comment) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final author = userProvider.getUserForPost(comment.authorId);

        return ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundImage: author?.photoURL != null
                ? NetworkImage(author!.photoURL!)
                : null,
            backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
            child: author?.photoURL == null
                ? Text(
              author?.displayName.isNotEmpty == true
                  ? author!.displayName.substring(0, 1).toUpperCase()
                  : comment.authorId.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF4A7AA7),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
                : null,
          ),
          title: Text(
            author?.displayName ?? author?.fullName ?? 'Usuario',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            comment.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          trailing: Text(
            _formatCommentTime(comment.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            // Aquí podrías implementar navegación al comentario específico
          },
        );
      },
    );
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final commentProvider = Provider.of<CommentProvider>(context, listen: false);
      final results = await commentProvider.searchComments(
        postId: widget.post.id,
        query: query.trim(),
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  String _formatCommentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}