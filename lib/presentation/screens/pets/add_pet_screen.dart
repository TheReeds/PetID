// lib/presentation/screens/add_pet_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/models/pet_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Estado del formulario
  PetType? _selectedType;
  PetSex? _selectedSex;
  PetSize? _selectedSize;
  DateTime? _selectedBirthDate;
  List<File> _selectedImages = [];
  bool _isForAdoption = false;
  bool _isForMating = false;

  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Agregar Mascota',
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
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoSection(),
                const SizedBox(height: 24),
                _buildBasicInfo(),
                const SizedBox(height: 24),
                _buildPhysicalInfo(),
                const SizedBox(height: 24),
                _buildAdditionalInfo(),
                const SizedBox(height: 24),
                _buildOptionsSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
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
            'Fotos de tu mascota',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega hasta 5 fotos para que sea más fácil identificar a tu mascota',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Grid de fotos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              if (index < _selectedImages.length) {
                return _buildImageTile(_selectedImages[index], index);
              } else if (index == _selectedImages.length && _selectedImages.length < 5) {
                return _buildAddImageTile();
              } else {
                return _buildEmptyImageTile();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(File image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4A7AA7), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
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
      ],
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4A7AA7).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4A7AA7).withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: Color(0xFF4A7AA7),
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Agregar',
              style: TextStyle(
                color: Color(0xFF4A7AA7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyImageTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return _buildSection(
      'Información Básica',
      [
        _buildTextField(
          controller: _nameController,
          label: 'Nombre de la mascota',
          icon: Icons.pets,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'El nombre es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField<PetType>(
          label: 'Tipo de mascota',
          icon: Icons.category,
          value: _selectedType,
          items: PetType.values,
          itemBuilder: (type) => _getPetTypeName(type),
          onChanged: (value) => setState(() => _selectedType = value),
          validator: (value) => value == null ? 'Selecciona el tipo' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _breedController,
          label: 'Raza',
          icon: Icons.label,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'La raza es obligatoria';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField<PetSex>(
          label: 'Sexo',
          icon: Icons.pets,
          value: _selectedSex,
          items: PetSex.values,
          itemBuilder: (sex) => sex == PetSex.male ? 'Macho' : 'Hembra',
          onChanged: (value) => setState(() => _selectedSex = value),
          validator: (value) => value == null ? 'Selecciona el sexo' : null,
        ),
      ],
    );
  }

  Widget _buildPhysicalInfo() {
    return _buildSection(
      'Información Física',
      [
        _buildDateField(),
        const SizedBox(height: 16),
        _buildDropdownField<PetSize>(
          label: 'Tamaño',
          icon: Icons.straighten,
          value: _selectedSize,
          items: PetSize.values,
          itemBuilder: (size) => _getPetSizeName(size),
          onChanged: (value) => setState(() => _selectedSize = value),
          validator: (value) => value == null ? 'Selecciona el tamaño' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _weightController,
          label: 'Peso (kg)',
          icon: Icons.monitor_weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'El peso es obligatorio';
            }
            final weight = double.tryParse(value!);
            if (weight == null || weight <= 0) {
              return 'Ingresa un peso válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return _buildSection(
      'Información Adicional',
      [
        _buildTextField(
          controller: _descriptionController,
          label: 'Descripción',
          icon: Icons.description,
          maxLines: 3,
          hint: 'Describe el comportamiento, características especiales, etc.',
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return _buildSection(
      'Opciones',
      [
        _buildSwitchTile(
          'Disponible para adopción',
          'Permitir que otros usuarios vean esta mascota para adopción',
          _isForAdoption,
              (value) => setState(() => _isForAdoption = value),
        ),
        _buildSwitchTile(
          'Disponible para reproducción',
          'Permitir que otros usuarios vean esta mascota para apareamiento',
          _isForMating,
              (value) => setState(() => _isForMating = value),
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
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemBuilder,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
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
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(itemBuilder(item)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectBirthDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF4A7AA7)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedBirthDate != null
                    ? 'Fecha de nacimiento: ${_formatDate(_selectedBirthDate!)}'
                    : 'Fecha de nacimiento',
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedBirthDate != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF4A7AA7)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      bool value,
      void Function(bool) onChanged,
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

  Widget _buildSaveButton() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        return Container(
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
            onPressed: petProvider.isLoading ? null : _savePet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7AA7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: petProvider.isLoading
                ? const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 20),
                SizedBox(width: 8),
                Text(
                  'Guardar Mascota',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      _showSnackBar('Máximo 5 fotos permitidas', isError: true);
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
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 1),
      firstDate: DateTime(now.year - 30),
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

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null || _selectedSex == null || _selectedSize == null) {
      _showSnackBar('Por favor completa todos los campos obligatorios', isError: true);
      return;
    }

    if (_selectedBirthDate == null) {
      _showSnackBar('Por favor selecciona la fecha de nacimiento', isError: true);
      return;
    }

    if (_selectedImages.isEmpty) {
      _showSnackBar('Por favor agrega al menos una foto', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      _showSnackBar('Error: Usuario no autenticado', isError: true);
      return;
    }

    final pet = PetModel(
      id: '', // Se generará automáticamente
      name: _nameController.text.trim(),
      type: _selectedType!,
      breed: _breedController.text.trim(),
      sex: _selectedSex!,
      birthDate: _selectedBirthDate!,
      size: _selectedSize!,
      weight: double.parse(_weightController.text.trim()),
      ownerId: authProvider.currentUser!.id,
      description: _descriptionController.text.trim(),
      isForAdoption: _isForAdoption,
      isForMating: _isForMating,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await petProvider.createPet(
      pet: pet,
      photoFiles: _selectedImages,
    );

    if (success) {
      _showSnackBar('¡Mascota registrada exitosamente!');
      Navigator.of(context).pop();
    } else {
      _showSnackBar(
        petProvider.errorMessage ?? 'Error al registrar mascota',
        isError: true,
      );
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

  String _getPetTypeName(PetType type) {
    switch (type) {
      case PetType.dog:
        return 'Perro';
      case PetType.cat:
        return 'Gato';
      case PetType.bird:
        return 'Ave';
      case PetType.rabbit:
        return 'Conejo';
      case PetType.hamster:
        return 'Hámster';
      case PetType.fish:
        return 'Pez';
      case PetType.reptile:
        return 'Reptil';
      case PetType.other:
        return 'Otro';
    }
  }

  String _getPetSizeName(PetSize size) {
    switch (size) {
      case PetSize.small:
        return 'Pequeño';
      case PetSize.medium:
        return 'Mediano';
      case PetSize.large:
        return 'Grande';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}