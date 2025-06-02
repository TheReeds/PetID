import 'package:apppetid/presentation/providers/auth_provider.dart';
import 'package:apppetid/presentation/screens/home/add_first_pet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  // Controladores existentes
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Nuevos controladores
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // Variables de estado
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String? errorText;
  final _formKey = GlobalKey<FormState>();

  // Nuevas variables de estado
  File? _profileImage;
  DateTime? _selectedDate;
  String? _selectedGender;
  final List<String> _genderOptions = ['Masculino', 'Femenino', 'Otros'];
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.elasticOut),
    );

    _logoAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoAnimationController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      // Error handling sin mensaje
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 años atrás
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A7AA7),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _validateForm(AuthProvider authProvider) {
    setState(() {
      errorText = null;
    });

    // Validar campos obligatorios básicos
    if (nameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        errorText = 'Por favor completa todos los campos obligatorios';
      });
      return false;
    }

    // Validar email
    final emailError = authProvider.validateEmail(emailController.text);
    if (emailError != null) {
      setState(() {
        errorText = emailError;
      });
      return false;
    }

    // Validar contraseña
    final passwordError = authProvider.validatePassword(passwordController.text);
    if (passwordError != null) {
      setState(() {
        errorText = passwordError;
      });
      return false;
    }

    // Validar que las contraseñas coincidan
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorText = 'Las contraseñas no coinciden';
      });
      return false;
    }

    return true;
  }

  Future<void> _handleSubmit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!_validateForm(authProvider)) return;

    HapticFeedback.mediumImpact();

    // Lógica de registro sin mensajes
    final success = await authProvider.signUp(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      displayName: nameController.text.trim(),
    );

    if (success) {
      // Navegar directamente sin delay ni mensaje
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AddFirstPetScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo de pantalla que ocupa TODA la pantalla, incluyendo status bar
          Positioned.fill(
            child: Image.asset(
              'assets/images/1pet_collage_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // Overlay semitransparente para mejorar legibilidad
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Header estático (Logo y títulos)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      ScaleTransition(
                        scale: _logoAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A7AA7),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Título principal
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: AnimatedBuilder(
                          animation: _slideAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: const Text(
                                '¡Crear Cuenta!',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtítulo
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Bienvenido a PetID',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                // Card scrollable
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            // Header del card (fijo)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Crear Cuenta',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Completa la información para registrarte',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            // Contenido scrollable
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Foto de perfil
                                    Center(
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(50),
                                            border: Border.all(
                                              color: const Color(0xFF4A7AA7),
                                              width: 2,
                                            ),
                                          ),
                                          child: _profileImage != null
                                              ? ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Image.file(
                                              _profileImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                              : const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                color: Color(0xFF4A7AA7),
                                                size: 24,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Foto',
                                                style: TextStyle(
                                                  color: Color(0xFF4A7AA7),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Nombre Completo
                                    const Text(
                                      'Nombre Completo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: nameController,
                                      hintText: 'Ingresa tu nombre completo',
                                    ),
                                    const SizedBox(height: 16),

                                    // Nombre de Usuario
                                    const Text(
                                      'Username',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: usernameController,
                                      hintText: 'Elige un nombre de usuario',
                                    ),
                                    const SizedBox(height: 16),

                                    // Correo Electrónico
                                    const Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: emailController,
                                      hintText: 'tu-email@ejemplo.com',
                                    ),
                                    const SizedBox(height: 16),

                                    // Teléfono
                                    const Text(
                                      'Teléfono',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: phoneController,
                                      hintText: '+51 999 999 999',
                                    ),
                                    const SizedBox(height: 16),

                                    // Dirección
                                    const Text(
                                      'Dirección',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: addressController,
                                      hintText: 'Tu dirección completa',
                                    ),
                                    const SizedBox(height: 16),

                                    // Fecha de Nacimiento
                                    const Text(
                                      'Fecha de Nacimiento',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _selectDate,
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _selectedDate != null
                                                      ? _formatDate(_selectedDate!)
                                                      : 'Selecciona tu fecha de nacimiento',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: _selectedDate != null
                                                        ? const Color(0xFF2C2C2C)
                                                        : Colors.grey[500],
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.calendar_today,
                                                color: Colors.grey[400],
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Género
                                    const Text(
                                      'Género',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedGender,
                                            hint: Text(
                                              'Selecciona tu género',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 16,
                                              ),
                                            ),
                                            icon: Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Colors.grey[400],
                                            ),
                                            dropdownColor: Colors.white,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF2C2C2C),
                                            ),
                                            isExpanded: true,
                                            items: _genderOptions.map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _selectedGender = newValue;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Password
                                    const Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: passwordController,
                                      hintText: 'Ingresa una contraseña segura',
                                      isPassword: true,
                                      obscureText: !isPasswordVisible,
                                      onSuffixTap: () {
                                        setState(() {
                                          isPasswordVisible = !isPasswordVisible;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Confirmar Password
                                    const Text(
                                      'Confirmar Password',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: confirmPasswordController,
                                      hintText: 'Confirma tu contraseña',
                                      isPassword: true,
                                      obscureText: !isConfirmPasswordVisible,
                                      onSuffixTap: () {
                                        setState(() {
                                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                                        });
                                      },
                                    ),

                                    // Mostrar error si existe
                                    if (errorText != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red[400],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                errorText!,
                                                style: TextStyle(
                                                  color: Colors.red[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 24),

                                    // Botón Crear Cuenta
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: authProvider.isLoading ? null : _handleSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4A7AA7),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: authProvider.isLoading
                                            ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                            : const Text(
                                          'Crear Cuenta',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Enlaces inferiores
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            // Navegar a login
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                            '¿Ya tienes cuenta?',
                                            style: TextStyle(
                                              color: Color(0xFF4A7AA7),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                            'Iniciar Sesión',
                                            style: TextStyle(
                                              color: Color(0xFF4A7AA7),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixTap,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2C2C2C),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[400],
              size: 20,
            ),
            onPressed: onSuffixTap,
          )
              : null,
        ),
      ),
    );
  }
}