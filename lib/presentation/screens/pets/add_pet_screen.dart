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
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Colores actualizados con estilo Facebook
  static const Color primaryAppColor = Color(0xFF4A7AA7); // Facebook blue
  static const Color primaryAppColorLight = Color(0xFF42B72A); // Facebook green
  static const Color cardBackgroundColor = Colors.white;
  static const Color cardTextColor = Color(0xFF1C1E21); // Facebook dark text
  static const Color cardIconColor = Color(0xFF4A7AA7);
  static const Color appBarTextColor = Colors.white;
  static const Color inputBackgroundColor = Color(0xFFF0F2F5); // Facebook input background

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _animationController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Facebook background color
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: _buildAnimatedFormContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFormContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildPhotoSection(),
                const SizedBox(height: 16),
                _buildBasicInfo(),
                const SizedBox(height: 16),
                _buildPhysicalInfo(),
                const SizedBox(height: 16),
                _buildAdditionalInfo(),
                const SizedBox(height: 16),
                _buildOptionsSection(),
                const SizedBox(height: 24),
                _buildSaveButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: primaryAppColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 12),
          _buildAppBarTitle(),
          const Spacer(),
          _buildAppBarPawIcon(),
        ],
      ),
    );
  }

  Widget _buildAppBarPawIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.pets_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Agregar Mascota',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Crea el perfil de tu compañero',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotos de tu mascota',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildImageGrid(),
          const SizedBox(height: 12),
          _buildAddPhotoButton(),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return _buildAddImageButton();
          }
          return _buildImagePreview(_selectedImages[index], index);
        },
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: inputBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryAppColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              color: primaryAppColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Agregar foto',
              style: TextStyle(
                color: primaryAppColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File image, int index) {
    return Stack(
      children: [
        Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 16,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return ElevatedButton.icon(
      onPressed: _pickImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(Icons.add_a_photo_rounded),
      label: const Text('Agregar fotos'),
    );
  }

  Widget _buildBasicInfo() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información básica',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Nombre',
            icon: Icons.pets_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTypeSelector(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryAppColor),
        filled: true,
        fillColor: inputBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryAppColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de mascota',
          style: TextStyle(
            fontSize: 14,
            color: cardTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: inputBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedType != null ? primaryAppColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PetType>(
              value: _selectedType,
              isExpanded: true,
              hint: const Text('Selecciona el tipo de mascota'),
              icon: Icon(Icons.arrow_drop_down, color: primaryAppColor),
              items: PetType.values.map((PetType type) {
                String label;
                IconData icon;
                switch (type) {
                  case PetType.dog:
                    label = 'Perro';
                    icon = Icons.pets_rounded;
                    break;
                  case PetType.cat:
                    label = 'Gato';
                    icon = Icons.pets_rounded;
                    break;
                  case PetType.bird:
                    label = 'Ave';
                    icon = Icons.flutter_dash_rounded;
                    break;
                  case PetType.rabbit:
                    label = 'Conejo';
                    icon = Icons.pets_rounded;
                    break;
                  case PetType.hamster:
                    label = 'Hámster';
                    icon = Icons.pets_rounded;
                    break;
                  case PetType.fish:
                    label = 'Pez';
                    icon = Icons.pets_rounded;
                    break;
                  case PetType.reptile:
                    label = 'Reptil';
                    icon = Icons.pets_rounded;
                    break;
                  case PetType.other:
                    label = 'Otro';
                    icon = Icons.pets_rounded;
                    break;
                }
                return DropdownMenuItem<PetType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(icon, color: primaryAppColor, size: 20),
                      const SizedBox(width: 12),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (PetType? newValue) {
                setState(() {
                  _selectedType = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicalInfo() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información física',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _breedController,
            label: 'Raza',
            icon: Icons.pets_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _weightController,
            label: 'Peso (kg)',
            icon: Icons.monitor_weight_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildSizeSelector(),
          const SizedBox(height: 12),
          _buildSexSelector(),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tamaño',
          style: TextStyle(
            fontSize: 14,
            color: cardTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSizeOption(
                size: PetSize.small,
                label: 'Pequeño',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSizeOption(
                size: PetSize.medium,
                label: 'Mediano',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSizeOption(
                size: PetSize.large,
                label: 'Grande',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeOption({
    required PetSize size,
    required String label,
  }) {
    final isSelected = _selectedSize == size;
    return GestureDetector(
      onTap: () => setState(() => _selectedSize = size),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryAppColor.withOpacity(0.1) : inputBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryAppColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryAppColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSexSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sexo',
          style: TextStyle(
            fontSize: 14,
            color: cardTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSexOption(
                sex: PetSex.male,
                icon: Icons.male_rounded,
                label: 'Macho',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSexOption(
                sex: PetSex.female,
                icon: Icons.female_rounded,
                label: 'Hembra',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSexOption({
    required PetSex sex,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedSex == sex;
    return GestureDetector(
      onTap: () => setState(() => _selectedSex = sex),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryAppColor.withOpacity(0.1) : inputBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryAppColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryAppColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryAppColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información adicional',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Descripción',
            icon: Icons.description_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildBirthDateSelector(),
        ],
      ),
    );
  }

  Widget _buildBirthDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha de nacimiento',
          style: TextStyle(
            fontSize: 14,
            color: cardTextColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectBirthDate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: inputBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedBirthDate != null ? primaryAppColor : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: primaryAppColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedBirthDate != null
                      ? _formatDate(_selectedBirthDate!)
                      : 'Seleccionar fecha',
                  style: TextStyle(
                    color: _selectedBirthDate != null ? cardTextColor : Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: _selectedBirthDate != null ? primaryAppColor : Colors.grey,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cardTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionSwitch(
            value: _isForAdoption,
            onChanged: (value) => setState(() => _isForAdoption = value),
            title: 'Disponible para adopción',
            subtitle: 'Permite que otros usuarios puedan adoptar a tu mascota',
            icon: Icons.favorite_rounded,
          ),
          const SizedBox(height: 12),
          _buildOptionSwitch(
            value: _isForMating,
            onChanged: (value) => setState(() => _isForMating = value),
            title: 'Disponible para apareamiento',
            subtitle: 'Permite que otros usuarios puedan contactarte para apareamiento',
            icon: Icons.favorite_border_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryAppColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryAppColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cardTextColor,
                ),
              ),
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
          activeColor: primaryAppColor,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _savePet,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text(
        'Guardar mascota',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 1),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryAppColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: cardTextColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryAppColor,
              ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _savePet() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null || _selectedSex == null || _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la fecha de nacimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor agrega al menos una foto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
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

    petProvider.createPet(
      pet: pet,
      photoFiles: _selectedImages,
    ).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Mascota registrada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(petProvider.errorMessage ?? 'Error al registrar mascota'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
}

// Ensure your PetType, PetSex, PetSize enums are defined correctly.
// For example:
// enum PetType { dog, cat, bird, reptile, other }
// enum PetSex { male, female }
// enum PetSize { small, medium, large }