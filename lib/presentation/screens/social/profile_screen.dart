// lib/presentation/screens/profile_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/user_provider.dart';
import '../pets/pet_detail_screen.dart'; // NUEVO: Para estadísticas

class ProfileScreen extends StatefulWidget {
  final String? userId; // NUEVO: Permitir ver perfil de otros usuarios
  final bool isEditable; // NUEVO: Controlar si se puede editar

  const ProfileScreen({
    super.key,
    this.userId,
    this.isEditable = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  DateTime? _selectedDate;
  String? _selectedGender;
  List<String> _selectedInterests = [];
  List<String> _selectedLanguages = [];
  String? _selectedLifestyle;
  File? _newProfileImage;
  bool _isEditing = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _shareLocation = false;
  bool _isOpenToMeetPetOwners = false;

  // NUEVO: Para estadísticas del usuario
  Map<String, int> _userStats = {'followers': 0, 'following': 0, 'posts': 0};

  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late AnimationController _profileAnimationController;

  // NUEVO: Opciones predefinidas
  final List<String> _availableInterests = [
    'Perros', 'Gatos', 'Aves', 'Peces', 'Reptiles', 'Conejos',
    'Veterinaria', 'Entrenamiento', 'Grooming', 'Adopción',
    'Caminatas', 'Parques', 'Fotografía', 'Viajes con mascotas'
  ];

  final List<String> _availableLanguages = [
    'Español', 'Inglés', 'Portugués', 'Francés', 'Italiano', 'Alemán'
  ];

  final List<String> _lifestyleOptions = [
    'Activo', 'Relajado', 'Aventurero', 'Casero', 'Social', 'Independiente'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
    _loadUserStats(); // NUEVO: Cargar estadísticas
  }

  void _initializeControllers() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _profileAnimationController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    _profileAnimationController.dispose();
    super.dispose();
  }

  // NUEVO: Determinar si es el perfil del usuario actual
  bool get _isOwnProfile {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return widget.userId == null || widget.userId == authProvider.currentUser?.id;
  }

  // NUEVO: Obtener el usuario a mostrar
  UserModel? get _targetUser {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_isOwnProfile) {
      return authProvider.currentUser;
    } else {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      return userProvider.getUserFromCache(widget.userId!);
    }
  }

  void _loadUserData() {
    final user = _targetUser;
    if (user != null) {
      _fullNameController.text = user.fullName ?? '';
      _displayNameController.text = user.displayName;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _selectedDate = user.dateOfBirth;
      _selectedGender = user.gender;
      _selectedInterests = List.from(user.interests);
      _selectedLanguages = List.from(user.languages);
      _selectedLifestyle = user.lifestyle;
      _isOpenToMeetPetOwners = user.isOpenToMeetPetOwners;
    }
  }

  Future<void> _loadFollowStatus() async {
    if (_isOwnProfile) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.currentUser != null && widget.userId != null) {
      final isFollowing = await userProvider.isFollowing(
        authProvider.currentUser!.id,
        widget.userId!,
      );

      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    }
  }
  Future<void> _loadUserStats() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final targetUserId = widget.userId ?? Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    if (targetUserId != null) {
      final stats = await userProvider.getUserStats(targetUserId);
      if (mounted) {
        setState(() {
          _userStats = stats;
        });
      }
    }

    // NUEVO: Cargar estado de seguimiento si no es perfil propio
    await _loadFollowStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return _buildLoadingScreen();
          }

          final user = _targetUser;
          if (user == null) {
            return _buildErrorScreen();
          }

          return RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildGradientHeader(user, authProvider),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildStatsSection(), // NUEVO: Estadísticas
                          const SizedBox(height: 20),
                          _buildFollowButton(),
                          const SizedBox(height: 20),
                          _buildPersonalInfo(),
                          const SizedBox(height: 20),
                          _buildContactInfo(),
                          const SizedBox(height: 20),
                          _buildInterestsSection(), // NUEVO: Intereses
                          if (!_isOwnProfile) ...[
                            const SizedBox(height: 20),
                            _buildUserPetsSection(),
                          ],
                          const SizedBox(height: 20),
                          if (_isOwnProfile) _buildPreferences(),
                          if (_isOwnProfile) const SizedBox(height: 20),
                          if (_isEditing && _isOwnProfile) _buildSaveButton(authProvider),
                          if (_isEditing && _isOwnProfile) const SizedBox(height: 20),
                          if (_isOwnProfile) _buildDangerZone(authProvider),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // NUEVO: Refresh del perfil
  Future<void> _refreshProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isOwnProfile) {
        // Refrescar datos del usuario actual
        await authProvider.refreshUserData();
      } else {
        // Cargar datos del usuario específico
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.getUserById(widget.userId!);
      }

      // Recargar estadísticas
      await _loadUserStats();

      // Recargar datos en los controladores
      _loadUserData();

      if (mounted) {
        _showSnackBar('Perfil actualizado');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al actualizar perfil', isError: true);
      }
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        _isOwnProfile ? 'Mi Perfil' : _targetUser?.displayName ?? 'Perfil',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      actions: [
        if (!_isEditing && _isOwnProfile && widget.isEditable)
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              onPressed: () {
                setState(() => _isEditing = true);
                _animationController.forward();
              },
            ),
          ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF4A7AA7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Error cargando perfil',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // NUEVO: Sección de estadísticas
  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Posts', _userStats['posts'] ?? 0, onTap: null),
            _buildStatDivider(),
            _buildStatItem('Seguidores', _userStats['followers'] ?? 0, onTap: () => _showFollowers()),
            _buildStatDivider(),
            _buildStatItem('Siguiendo', _userStats['following'] ?? 0, onTap: () => _showFollowing()),
          ],
        ),
      ),
    );
  }
  Widget _buildFollowButton() {
    if (_isOwnProfile) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton(
        onPressed: _isFollowLoading ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? Colors.grey.shade100 : const Color(0xFF4A7AA7),
          foregroundColor: _isFollowing ? Colors.grey.shade700 : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: _isFollowing ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
          ),
          elevation: _isFollowing ? 0 : 2,
        ),
        child: _isFollowLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF4A7AA7),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isFollowing ? Icons.person_remove : Icons.person_add,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isFollowing ? 'Dejar de seguir' : 'Seguir',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _toggleFollow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.currentUser == null || widget.userId == null) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      final success = await userProvider.toggleFollowUser(
        authProvider.currentUser!.id,
        widget.userId!,
      );

      if (success) {
        setState(() {
          _isFollowing = !_isFollowing;
          // Actualizar estadísticas localmente
          if (_isFollowing) {
            _userStats['followers'] = (_userStats['followers'] ?? 0) + 1;
          } else {
            _userStats['followers'] = (_userStats['followers'] ?? 1) - 1;
          }
        });

        _showSnackBar(
          _isFollowing ? 'Ahora sigues a este usuario' : 'Dejaste de seguir a este usuario',
        );

        // Recargar estadísticas del servidor para estar seguros
        await _loadUserStats();
      } else {
        _showSnackBar('Error al actualizar el seguimiento', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  Widget _buildStatItem(String label, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: onTap != null ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12) : null,
        decoration: onTap != null ? BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
        ) : null,
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: onTap != null ? const Color(0xFF4A7AA7) : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildGradientHeader(UserModel user, AuthProvider authProvider) {
    return AnimatedBuilder(
      animation: _profileAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _profileAnimationController.value)),
          child: Opacity(
            opacity: _profileAnimationController.value,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                    Color(0xFF4A7AA7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    // Foto de perfil con efecto glassmorphism
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: _newProfileImage != null
                                    ? FileImage(_newProfileImage!)
                                    : (user.photoURL != null
                                    ? NetworkImage(user.photoURL!)
                                    : null) as ImageProvider?,
                                backgroundColor: Colors.grey.shade100,
                                child: user.photoURL == null && _newProfileImage == null
                                    ? Icon(
                                  Icons.person_outline,
                                  size: 50,
                                  color: Colors.grey.shade400,
                                )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        if (_isEditing && _isOwnProfile)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: _pickProfileImage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                    // NUEVO: Mostrar edad si está disponible
                    if (user.age != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          user.displayAge,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Miembro desde ${_formatDate(user.createdAt)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfo() {
    return _buildGlassSection(
      'Información Personal',
      Icons.person_outline,
      [
        _buildModernTextField(
          controller: _fullNameController,
          label: 'Nombre Completo',
          icon: Icons.badge_outlined,
          enabled: _isEditing && _isOwnProfile,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'El nombre es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _displayNameController,
          label: 'Nombre de Usuario',
          icon: Icons.alternate_email_outlined,
          enabled: _isEditing && _isOwnProfile,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'El nombre de usuario es obligatorio';
            }
            if ((value?.length ?? 0) < 3) {
              return 'Mínimo 3 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildModernDateField(),
        const SizedBox(height: 16),
        _buildModernGenderField(),
      ],
    );
  }

  Widget _buildContactInfo() {
    return _buildGlassSection(
      'Información de Contacto',
      Icons.contact_page_outlined,
      [
        _buildModernTextField(
          controller: _phoneController,
          label: 'Teléfono',
          icon: Icons.phone_outlined,
          enabled: _isEditing && _isOwnProfile,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _addressController,
          label: 'Dirección',
          icon: Icons.location_on_outlined,
          enabled: _isEditing && _isOwnProfile,
          maxLines: 2,
        ),
      ],
    );
  }

  // NUEVO: Sección de intereses y preferencias
  Widget _buildInterestsSection() {
    final user = _targetUser;
    if (user == null) return const SizedBox.shrink();



    return _buildGlassSection(

      'Intereses y Preferencias',
      Icons.favorite_outline,
      [
        // Intereses
        _buildChipSection(
          'Intereses',
          _selectedInterests,
          _availableInterests,
          enabled: _isEditing && _isOwnProfile,
          onChanged: (interests) => setState(() => _selectedInterests = interests),
        ),
        const SizedBox(height: 16),

        // Idiomas
        _buildChipSection(
          'Idiomas',
          _selectedLanguages,
          _availableLanguages,
          enabled: _isEditing && _isOwnProfile,
          onChanged: (languages) => setState(() => _selectedLanguages = languages),
        ),
        const SizedBox(height: 16),

        // Estilo de vida
        _buildLifestyleDropdown(),
        const SizedBox(height: 16),

        // Disponibilidad para conocer dueños de mascotas
        _buildModernSwitchTile(
          'Conocer Dueños de Mascotas',
          'Disponible para conocer otros dueños de mascotas',
          Icons.people_outline,
          _isOpenToMeetPetOwners,
          (_isEditing && _isOwnProfile) ? (value) => setState(() => _isOpenToMeetPetOwners = value) : null,
        ),
      ],
    );
  }



  Widget _buildChipSection(
      String title,
      List<String> selectedItems,
      List<String> availableItems,
      {required bool enabled, required Function(List<String>) onChanged}
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableItems.map((item) {
            final isSelected = selectedItems.contains(item);
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: enabled ? (selected) {
                final newList = List<String>.from(selectedItems);
                if (selected) {
                  newList.add(item);
                } else {
                  newList.remove(item);
                }
                onChanged(newList);
              } : null,
              selectedColor: const Color(0xFF667eea).withOpacity(0.2),
              checkmarkColor: const Color(0xFF667eea),
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF667eea) : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLifestyleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLifestyle,
      decoration: InputDecoration(
        labelText: 'Estilo de Vida',
        labelStyle: TextStyle(
          color: (_isEditing && _isOwnProfile) ? const Color(0xFF4A7AA7) : Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: (_isEditing && _isOwnProfile)
                ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: (_isEditing && _isOwnProfile) ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      items: (_isEditing && _isOwnProfile) ? _lifestyleOptions.map((lifestyle) =>
          DropdownMenuItem(value: lifestyle, child: Text(lifestyle))
      ).toList() : null,
      onChanged: (_isEditing && _isOwnProfile) ? (value) => setState(() => _selectedLifestyle = value) : null,
    );
  }

  Widget _buildPreferences() {
    return _buildGlassSection(
      'Preferencias',
      Icons.tune_outlined,
      [
        _buildModernSwitchTile(
          'Notificaciones Push',
          'Recibir notificaciones en el dispositivo',
          Icons.notifications_outlined,
          _pushNotifications,
          _isEditing ? (value) => setState(() => _pushNotifications = value) : null,
        ),
        const SizedBox(height: 12),
        _buildModernSwitchTile(
          'Notificaciones por Email',
          'Recibir notificaciones por correo',
          Icons.email_outlined,
          _emailNotifications,
          _isEditing ? (value) => setState(() => _emailNotifications = value) : null,
        ),
        const SizedBox(height: 12),
        _buildModernSwitchTile(
          'Compartir Ubicación',
          'Permitir compartir ubicación para mascotas perdidas',
          Icons.location_searching_outlined,
          _shareLocation,
          _isEditing ? (value) => setState(() => _shareLocation = value) : null,
        ),
      ],
    );
  }

  Widget _buildGlassSection(String title, IconData titleIcon, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(titleIcon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (enabled)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? const Color(0xFF4A7AA7) : Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                  : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildModernDateField() {
    final enabled = _isEditing && _isOwnProfile;
    return GestureDetector(
      onTap: enabled ? () => _selectDate(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (enabled)
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
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                    : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 18),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha de Nacimiento',
                    style: TextStyle(
                      color: enabled ? const Color(0xFF4A7AA7) : Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDate != null ? _formatDate(_selectedDate!) : 'Seleccionar fecha',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _selectedDate != null ? const Color(0xFF2D3748) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGenderField() {
    final enabled = _isEditing && _isOwnProfile;
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (enabled)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: 'Género',
          labelStyle: TextStyle(
            color: enabled ? const Color(0xFF4A7AA7) : Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                  : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wc_outlined, color: Colors.white, size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
        items: enabled
            ? [
          'Masculino',
          'Femenino',
          'Otro',
          'Prefiero no decirlo',
        ].map((gender) => DropdownMenuItem(
          value: gender,
          child: Text(gender),
        )).toList()
            : null,
        onChanged: enabled
            ? (value) => setState(() => _selectedGender = value)
            : null,
      ),
    );
  }

  Widget _buildModernSwitchTile(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      void Function(bool)? onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: value
                    ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
                    : [Colors.grey.shade300, Colors.grey.shade400],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF667eea),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AuthProvider authProvider) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _animationController.value),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : () => _saveProfile(authProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _newProfileImage = null;
                  });
                  _animationController.reverse();
                  _loadUserData(); // MEJORADO: Recargar datos originales
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDangerZone(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade50,
            Colors.red.shade100.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Zona de Peligro',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDangerButton(
            icon: Icons.logout_outlined,
            label: 'Cerrar Sesión',
            color: Colors.orange.shade600,
            onPressed: () => _showLogoutDialog(authProvider),
          ),
          const SizedBox(height: 12),
          _buildDangerButton(
            icon: Icons.delete_forever_outlined,
            label: 'Eliminar Cuenta',
            color: Colors.red.shade700,
            onPressed: () => _showDeleteAccountDialog(authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: color.withOpacity(0.05),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e', isError: true);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // MEJORADO: Función de guardado con mejor manejo de errores y actualización
  Future<void> _saveProfile(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    try {
      final currentUser = authProvider.currentUser!;

      // Crear usuario actualizado con todos los nuevos campos
      final updatedUser = currentUser.copyWith(
        fullName: _fullNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        dateOfBirth: _selectedDate,
        gender: _selectedGender,
        interests: _selectedInterests,
        languages: _selectedLanguages,
        lifestyle: _selectedLifestyle,
        isOpenToMeetPetOwners: _isOpenToMeetPetOwners,
      );

      // Actualizar foto de perfil si se seleccionó una nueva
      if (_newProfileImage != null) {
        final photoSuccess = await authProvider.updateProfilePhoto(_newProfileImage!);
        if (!photoSuccess) {
          _showSnackBar('Error al actualizar foto de perfil', isError: true);
          return;
        }
      }

      // Actualizar el resto de datos
      final success = await authProvider.updateProfile(updatedUser);

      if (success) {
        setState(() {
          _isEditing = false;
          _newProfileImage = null;
        });
        _animationController.reverse();

        // NUEVO: Recargar estadísticas después de actualizar
        await _loadUserStats();

        // NUEVO: Recargar datos frescos del servidor
        await _refreshProfile();

        _showSnackBar('Perfil actualizado correctamente');
      } else {
        _showSnackBar('Error al actualizar perfil', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error inesperado: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showLogoutDialog(AuthProvider authProvider) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.logout_outlined, color: Colors.orange.shade600),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cerrar Sesión',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.orange.shade500, Colors.orange.shade600],
              ),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _showDeleteAccountDialog(AuthProvider authProvider) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_outlined, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            Text(
              'Eliminar Cuenta',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer y perderás todos tus datos.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade700],
              ),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final success = await authProvider.deleteAccount();
      if (success && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (!success) {
        _showSnackBar('Error al eliminar cuenta', isError: true);
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
  Future<void> _showFollowers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final targetUserId = widget.userId ?? Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    if (targetUserId == null) return;

    // Mostrar loading
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
      ),
    );

    try {
      final followers = await userProvider.getUserFollowers(targetUserId);

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        _showUserListBottomSheet(
          title: 'Seguidores',
          users: followers,
          emptyMessage: 'No tiene seguidores aún',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        _showSnackBar('Error cargando seguidores: $e', isError: true);
      }
    }
  }
  Widget _buildPetsLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pets, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mascotas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4A7AA7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Cargando mascotas...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

// 4. Card de error para mascotas
  Widget _buildPetsErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mascotas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Error cargando mascotas',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 5. Card principal de mascotas
  Widget _buildPetsCard(List<PetModel> userPets) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pets, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Mascotas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7AA7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${userPets.length}',
                  style: const TextStyle(
                    color: Color(0xFF4A7AA7),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Contenido de mascotas
          if (userPets.isEmpty)
            _buildEmptyPetsState()
          else
            _buildPetsGrid(userPets),
        ],
      ),
    );
  }
  Widget _buildEmptyPetsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin mascotas registradas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este usuario aún no ha registrado ninguna mascota',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// 7. Grid de mascotas
  Widget _buildPetsGrid(List<PetModel> pets) {
    // Mostrar máximo 6 mascotas inicialmente
    final displayPets = pets.take(6).toList();
    final hasMore = pets.length > 6;

    return Column(
      children: [
        // Estadísticas rápidas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPetStat(
                'En Casa',
                pets.where((p) => !p.isLost).length,
                Icons.home,
                Colors.green,
              ),
              _buildPetStat(
                'Perdidas',
                pets.where((p) => p.isLost).length,
                Icons.warning_amber,
                Colors.red,
              ),
              _buildPetStat(
                'Adopción',
                pets.where((p) => p.isForAdoption).length,
                Icons.favorite,
                Colors.purple,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Grid de mascotas
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: displayPets.length,
          itemBuilder: (context, index) => _buildPetPreviewCard(displayPets[index]),
        ),

        // Botón "Ver todas" si hay más mascotas
        if (hasMore) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAllUserPets(pets),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4A7AA7),
                side: const BorderSide(color: Color(0xFF4A7AA7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.grid_view),
              label: Text('Ver todas las mascotas (${pets.length})'),
            ),
          ),
        ],
      ],
    );
  }

// 8. Widget para estadísticas de mascotas
  Widget _buildPetStat(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // 9. Card de vista previa de mascota
  Widget _buildPetPreviewCard(PetModel pet) {
    return GestureDetector(
      onTap: () => _showPetDetail(pet),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(  // CAMBIO: Removido const y agregado ClipRRect
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      pet.profilePhoto != null
                          ? Image.network(
                        pet.profilePhoto!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPetPlaceholder(),
                      )
                          : _buildPetPlaceholder(),

                      // Estado de la mascota
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: pet.isLost ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                pet.isLost ? Icons.warning : Icons.home,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                pet.isLost ? 'Perdida' : 'Casa',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tipo de mascota
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getPetTypeIcon(pet.type),
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Información
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pet.breed,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pet.displayAge,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              pet.sex == PetSex.male ? Icons.male : Icons.female,
                              size: 12,
                              color: pet.sex == PetSex.male ? Colors.blue : Colors.pink,
                            ),
                            const SizedBox(width: 2),
                            if (pet.isVaccinated)
                              Icon(
                                Icons.medical_services,
                                size: 10,
                                color: Colors.green.shade600,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPetsSection() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        return FutureBuilder<List<PetModel>>(
          future: _loadUserPets(widget.userId!, petProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildPetsLoadingCard();
            }

            if (snapshot.hasError) {
              return _buildPetsErrorCard();
            }

            final userPets = snapshot.data ?? [];
            return _buildPetsCard(userPets);
          },
        );
      },
    );
  }
  Widget _buildPetPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            'Sin foto',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

// 11. Función para cargar mascotas del usuario
  Future<List<PetModel>> _loadUserPets(String userId, PetProvider petProvider) async {
    try {
      return await petProvider.loadOtherUserPets(userId);
    } catch (e) {
      print('Error cargando mascotas del usuario: $e');
      return [];
    }
  }

// 12. Mostrar detalle de mascota
  void _showPetDetail(PetModel pet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(
          pet: pet,
          isOwner: false, // Modo solo lectura
        ),
      ),
    );
  }

// 13. Mostrar todas las mascotas en modal
  void _showAllUserPets(List<PetModel> pets) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.pets, color: Color(0xFF4A7AA7)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Todas las mascotas (${pets.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Grid de mascotas
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: pets.length,
                    itemBuilder: (context, index) => _buildPetPreviewCard(pets[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

// 14. Helper para obtener iconos de tipos de mascota
  IconData _getPetTypeIcon(PetType type) {
    switch (type) {
      case PetType.dog:
        return Icons.pets;
      case PetType.cat:
        return Icons.pets;
      case PetType.bird:
        return Icons.flutter_dash;
      case PetType.rabbit:
        return Icons.cruelty_free;
      case PetType.hamster:
        return Icons.cruelty_free;
      case PetType.fish:
        return Icons.set_meal;
      case PetType.reptile:
        return Icons.pest_control;
      case PetType.other:
        return Icons.pets;
    }
  }


  Future<void> _showFollowing() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final targetUserId = widget.userId ?? Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    if (targetUserId == null) return;

    // Mostrar loading
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
      ),
    );

    try {
      final following = await userProvider.getUserFollowing(targetUserId);

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        _showUserListBottomSheet(
          title: 'Siguiendo',
          users: following,
          emptyMessage: 'No sigue a nadie aún',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        _showSnackBar('Error cargando siguiendo: $e', isError: true);
      }
    }
  }

  void _showUserListBottomSheet({
    required String title,
    required List<UserModel> users,
    required String emptyMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${users.length}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Lista de usuarios
                Expanded(
                  child: users.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                          child: user.photoURL == null
                              ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF4A7AA7),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: Color(0xFF4A7AA7),
                              ),
                            ],
                          ],
                        ),
                        subtitle: user.fullName != null && user.fullName != user.displayName
                            ? Text(
                          user.fullName!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          // Navegar al perfil del usuario
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                userId: user.id,
                                isEditable: false,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}