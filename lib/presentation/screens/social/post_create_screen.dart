// lib/presentation/screens/post_create_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/post_provider.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<File> _selectedImages = [];
  PostType _selectedType = PostType.photo;
  PetModel? _selectedPet;
  bool _isPublic = true;
  bool _isLoading = false;

  final List<String> _hashtags = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Nueva Publicación',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A7AA7),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF4A7AA7)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _publishPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7AA7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Publicar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(),
            const SizedBox(height: 20),
            _buildPostTypeSelector(),
            const SizedBox(height: 20),
            _buildPetSelector(),
            const SizedBox(height: 20),
            _buildContentField(),
            const SizedBox(height: 20),
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildHashtagSection(),
            const SizedBox(height: 20),
            _buildPrivacySelector(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                child: user?.photoURL == null
                    ? const Icon(Icons.person, color: Color(0xFF4A7AA7))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPostTypeText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTypeIcon(),
                      size: 16,
                      color: _getTypeColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTypeLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getTypeColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de publicación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona el tipo de contenido que quieres compartir',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  PostType.photo,
                  'Foto',
                  Icons.photo_camera,
                  Colors.blue,
                  'Comparte fotos de tu mascota',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption(
                  PostType.story,
                  'Historia',
                  Icons.auto_stories,
                  Colors.purple,
                  'Cuenta una anécdota',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTypeOption(
            PostType.announcement,
            'Anuncio',
            Icons.campaign,
            Colors.red,
            'Mascota perdida, adopción, etc.',
            isWide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
      PostType type,
      String label,
      IconData icon,
      Color color,
      String description,
      {bool isWide = false}
      ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedType = type;
          if (type == PostType.announcement) {
            _selectedImages.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isWide
            ? Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? color.withOpacity(0.8) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? color.withOpacity(0.8) : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetSelector() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        final pets = petProvider.userPets;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Mascota relacionada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Opcional',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Vincula tu publicación con una de tus mascotas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              if (pets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pets, color: Colors.grey.shade400, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No tienes mascotas registradas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Agrega tu primera mascota para vincularla a tus publicaciones',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<PetModel>(
                    value: _selectedPet,
                    decoration: const InputDecoration(
                      hintText: 'Seleccionar mascota',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem<PetModel>(
                        value: null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // AGREGADO
                          children: [
                            Icon(Icons.not_interested, color: Colors.grey),
                            SizedBox(width: 12),
                            Text('Ninguna mascota'),
                          ],
                        ),
                      ),
                      ...pets.map((pet) => DropdownMenuItem<PetModel>(
                        value: pet,
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // AGREGADO
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: pet.profilePhoto != null
                                  ? NetworkImage(pet.profilePhoto!)
                                  : null,
                              backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                              child: pet.profilePhoto == null
                                  ? const Icon(Icons.pets, size: 16, color: Color(0xFF4A7AA7))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // CAMBIO: Usar Flexible en lugar de Expanded
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // AGREGADO
                                children: [
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis, // AGREGADO
                                  ),
                                  Text(
                                    '${pet.breed} • ${pet.displayAge}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis, // AGREGADO
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (pet) {
                      setState(() {
                        _selectedPet = pet;
                      });
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contenido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escribe el contenido de tu publicación',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 6,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: _getContentHint(),
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4A7AA7), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (text) {
              _extractHashtags(text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (_selectedType == PostType.announcement) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Fotos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (_selectedType == PostType.photo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Requerido',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7AA7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(
                    Icons.add_photo_alternate,
                    size: 18,
                    color: Color(0xFF4A7AA7),
                  ),
                  label: const Text(
                    'Agregar',
                    style: TextStyle(
                      color: Color(0xFF4A7AA7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Máximo 5 fotos por publicación',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedImages.isEmpty)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Toca para agregar fotos',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Comparte momentos especiales de tu mascota',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length && _selectedImages.length < 5) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.grey, size: 24),
                              SizedBox(height: 4),
                              Text(
                                'Agregar',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A7AA7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Principal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  '${_selectedImages.length}/5 fotos seleccionadas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHashtagSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Hashtags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.tag,
                color: _hashtags.isNotEmpty ? const Color(0xFF4A7AA7) : Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Los hashtags se detectan automáticamente cuando escribes #',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          if (_hashtags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hashtags.map((hashtag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7AA7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4A7AA7).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$hashtag',
                      style: const TextStyle(
                        color: Color(0xFF4A7AA7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.tag, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No hay hashtags detectados',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Usa # en tu texto para agregar hashtags',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_isPublic ? Colors.green : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPublic ? Icons.public : Icons.lock,
              color: _isPublic ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Público' : 'Privado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPublic
                      ? 'Cualquier persona puede ver esta publicación'
                      : 'Solo tus seguidores pueden ver esta publicación',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _isPublic = value;
              });
            },
            activeColor: Colors.green,
            inactiveThumbColor: Colors.orange,
            inactiveTrackColor: Colors.orange.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  String _getPostTypeText() {
    switch (_selectedType) {
      case PostType.photo:
        return 'Compartiendo una foto';
      case PostType.story:
        return 'Contando una historia';
      case PostType.announcement:
        return 'Haciendo un anuncio';
      case PostType.video:
        return 'Compartiendo un video';
    }
  }

  String _getTypeLabel() {
    switch (_selectedType) {
      case PostType.photo:
        return 'Foto';
      case PostType.story:
        return 'Historia';
      case PostType.announcement:
        return 'Anuncio';
      case PostType.video:
        return 'Video';
    }
  }

  IconData _getTypeIcon() {
    switch (_selectedType) {
      case PostType.photo:
        return Icons.photo_camera;
      case PostType.story:
        return Icons.auto_stories;
      case PostType.announcement:
        return Icons.campaign;
      case PostType.video:
        return Icons.videocam;
    }
  }

  Color _getTypeColor() {
    switch (_selectedType) {
      case PostType.photo:
        return Colors.blue;
      case PostType.story:
        return Colors.purple;
      case PostType.announcement:
        return Colors.red;
      case PostType.video:
        return Colors.green;
    }
  }

  String _getContentHint() {
    switch (_selectedType) {
      case PostType.photo:
        return '¿Qué está pasando con tu mascota? Comparte una foto especial...\n\nEjemplo: "¡Firulais disfrutando del parque! 🐕 #VivaLosDogs #ParqueDiversión"';
      case PostType.story:
        return 'Cuenta una historia sobre tu mascota...\n\nEjemplo: "Hoy Michi hizo algo increíble... #GatoTravieso #HistoriasDeMascotas"';
      case PostType.announcement:
        return 'Escribe tu anuncio aquí...\n\nEjemplo: "🚨 MASCOTA PERDIDA 🚨\nSe perdió Max, un Golden Retriever de 3 años en Miraflores. #MascotaPerdida #Lima"';
      case PostType.video:
        return 'Describe tu video...\n\nEjemplo: "¡Mira este truco que aprendió mi perro! #TrucosPerrunos #Entrenamiento"';
    }
  }

  void _extractHashtags(String text) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);

    setState(() {
      _hashtags.clear();
      for (final match in matches) {
        final hashtag = match.group(1);
        if (hashtag != null && !_hashtags.contains(hashtag)) {
          _hashtags.add(hashtag);
        }
      }
    });
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      _showSnackBar('Máximo 5 fotos por publicación', isError: true);
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });

        HapticFeedback.lightImpact();
        _showSnackBar('Foto agregada (${_selectedImages.length}/5)');
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _publishPost() async {
    // Validaciones existentes...
    if (_contentController.text.trim().isEmpty) {
      _showSnackBar('Por favor escribe algo antes de publicar', isError: true);
      return;
    }

    if (_selectedType == PostType.photo && _selectedImages.isEmpty) {
      _showSnackBar('Agrega al menos una foto para este tipo de publicación', isError: true);
      return;
    }

    if (_contentController.text.trim().length < 10) {
      _showSnackBar('El contenido debe tener al menos 10 caracteres', isError: true);
      return;
    }

    if (_selectedType == PostType.announcement) {
      final confirm = await _showConfirmDialog();
      if (!confirm) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      HapticFeedback.mediumImpact();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final postProvider = Provider.of<PostProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Crear el post
      final newPost = PostModel(
        id: '', // Se generará en el repository
        authorId: authProvider.currentUser!.id,
        petId: _selectedPet?.id,
        type: _selectedType,
        content: _contentController.text.trim(),
        hashtags: _hashtags,
        isPublic: _isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Crear la publicación
      final success = await postProvider.createPost(
        post: newPost,
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      if (success) {
        _showSnackBar('¡Publicación creada exitosamente! 🎉');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Error al crear la publicación');
      }

    } catch (e) {
      _showSnackBar('Error al crear publicación: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.campaign, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Confirmar Anuncio'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres publicar este anuncio? Los anuncios tienen mayor visibilidad en la comunidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Publicar Anuncio'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(milliseconds: isError ? 4000 : 2000),
      ),
    );
  }
}