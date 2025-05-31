// lib/presentation/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  File? _newProfileImage;
  bool _isEditing = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _shareLocation = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _fullNameController.text = user.fullName ?? '';
      _displayNameController.text = user.displayName;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _selectedDate = user.dateOfBirth;
      _selectedGender = user.gender;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A7AA7),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A7AA7)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF4A7AA7)),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
            );
          }

          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(child: Text('Error cargando perfil'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileHeader(user, authProvider),
                  const SizedBox(height: 32),
                  _buildPersonalInfo(),
                  const SizedBox(height: 24),
                  _buildContactInfo(),
                  const SizedBox(height: 24),
                  _buildPreferences(),
                  const SizedBox(height: 32),
                  if (_isEditing) _buildSaveButton(authProvider),
                  const SizedBox(height: 24),
                  _buildDangerZone(authProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Foto de perfil
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4A7AA7).withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _newProfileImage != null
                      ? FileImage(_newProfileImage!)
                      : (user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null) as ImageProvider?,
                  backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                  child: user.photoURL == null && _newProfileImage == null
                      ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF4A7AA7),
                  )
                      : null,
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A7AA7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A7AA7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Miembro desde ${_formatDate(user.createdAt)}',
              style: const TextStyle(
                color: Color(0xFF4A7AA7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      'Información Personal',
      [
        _buildTextField(
          controller: _fullNameController,
          label: 'Nombre Completo',
          icon: Icons.person,
          enabled: _isEditing,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'El nombre es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _displayNameController,
          label: 'Nombre de Usuario',
          icon: Icons.alternate_email,
          enabled: _isEditing,
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
        _buildDateField(),
        const SizedBox(height: 16),
        _buildGenderField(),
      ],
    );
  }

  Widget _buildContactInfo() {
    return _buildSection(
      'Información de Contacto',
      [
        _buildTextField(
          controller: _phoneController,
          label: 'Teléfono',
          icon: Icons.phone,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Dirección',
          icon: Icons.location_on,
          enabled: _isEditing,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPreferences() {
    return _buildSection(
      'Preferencias',
      [
        _buildSwitchTile(
          'Notificaciones Push',
          'Recibir notificaciones en el dispositivo',
          _pushNotifications,
          _isEditing ? (value) => setState(() => _pushNotifications = value) : null,
        ),
        _buildSwitchTile(
          'Notificaciones por Email',
          'Recibir notificaciones por correo',
          _emailNotifications,
          _isEditing ? (value) => setState(() => _emailNotifications = value) : null,
        ),
        _buildSwitchTile(
          'Compartir Ubicación',
          'Permitir compartir ubicación para mascotas perdidas',
          _shareLocation,
          _isEditing ? (value) => setState(() => _shareLocation = value) : null,
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4A7AA7)),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _isEditing ? () => _selectDate(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: _isEditing ? Colors.white : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF4A7AA7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? 'Fecha de Nacimiento: ${_formatDate(_selectedDate!)}'
                    : 'Fecha de Nacimiento',
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedDate != null ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
            if (_isEditing)
              const Icon(Icons.arrow_drop_down, color: Color(0xFF4A7AA7)),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: _isEditing ? Colors.white : Colors.grey.shade50,
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF4A7AA7)),
        ),
        hint: const Text('Selecciona tu género'),
        items: _isEditing
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
        onChanged: _isEditing
            ? (value) => setState(() => _selectedGender = value)
            : null,
      ),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      bool value,
      void Function(bool)? onChanged,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4A7AA7),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AuthProvider authProvider) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A7AA7).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : () => _saveProfile(authProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7AA7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: authProvider.isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 20),
                SizedBox(width: 8),
                Text(
                  'Guardar Cambios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() => _isEditing = false);
            _loadUserData(); // Recargar datos originales
          },
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zona de Peligro',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(authProvider),
              icon: Icon(Icons.logout, color: Colors.red.shade600),
              label: Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red.shade600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showDeleteAccountDialog(authProvider),
              icon: Icon(Icons.delete_forever, color: Colors.red.shade700),
              label: Text(
                'Eliminar Cuenta',
                style: TextStyle(color: Colors.red.shade700),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
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
              primary: Color(0xFF4A7AA7),
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

  Future<void> _saveProfile(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final currentUser = authProvider.currentUser!;
    final updatedUser = currentUser.copyWith(
      fullName: _fullNameController.text.trim(),
      displayName: _displayNameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      dateOfBirth: _selectedDate,
      gender: _selectedGender,
    );

    bool success = false;

    // Actualizar foto de perfil si se seleccionó una nueva
    if (_newProfileImage != null) {
      success = await authProvider.updateProfilePhoto(_newProfileImage!);
      if (!success) {
        _showSnackBar('Error al actualizar foto de perfil', isError: true);
        return;
      }
    }

    // Actualizar el resto de datos
    success = await authProvider.updateProfile(updatedUser);

    if (success) {
      setState(() {
        _isEditing = false;
        _newProfileImage = null;
      });
      _showSnackBar('Perfil actualizado correctamente');
    } else {
      _showSnackBar('Error al actualizar perfil', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
      ),
    );
  }

  Future<void> _showLogoutDialog(AuthProvider authProvider) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
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
        title: Text(
          'Eliminar Cuenta',
          style: TextStyle(color: Colors.red.shade700),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer y perderás todos tus datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}