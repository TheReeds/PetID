import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:apppetid/presentation/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final displayNameController = TextEditingController(); // Nombre de usuario
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  DateTime? selectedDate;
  String? selectedGender;
  File? profileImage;

  final ImagePicker picker = ImagePicker();

  String? errorText;

  Future<void> _pickImage() async {
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6A9AE2)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.person_add,
              size: 64,
              color: const Color(0xFF6A9AE2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Registrar Usuario',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B365D),
              ),
            ),
            const SizedBox(height: 24),

            // Foto perfil con preview y botón para cambiar
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFF4F8FF),
                backgroundImage:
                profileImage != null ? FileImage(profileImage!) : null,
                child: profileImage == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Color(0xFF6A9AE2))
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            _buildTextField(fullNameController, 'Nombre completo'),
            _buildTextField(phoneController, 'Teléfono', keyboardType: TextInputType.phone),
            _buildTextField(addressController, 'Dirección'),

            // Fecha de nacimiento con selector calendario
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF4F8FF),
                    labelText: 'Fecha de nacimiento',
                    labelStyle: const TextStyle(color: Color(0xFF6A9AE2)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFABC6F7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6A9AE2)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: Text(
                    selectedDate == null
                        ? 'Selecciona una fecha'
                        : '${selectedDate!.day.toString().padLeft(2, '0')}/'
                        '${selectedDate!.month.toString().padLeft(2, '0')}/'
                        '${selectedDate!.year}',
                    style: TextStyle(
                      color: selectedDate == null
                          ? Colors.grey[600]
                          : const Color(0xFF1B365D),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Dropdown para género
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFABC6F7)),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF4F8FF),
              ),
              child: DropdownButton<String>(
                value: selectedGender,
                hint: const Text('Selecciona tu género', style: TextStyle(color: Color(0xFF6A9AE2))),
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6A9AE2)),
                style: const TextStyle(color: Color(0xFF6A9AE2), fontSize: 16),
                onChanged: (String? value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
                items: ['Masculino', 'Femenino'].map((e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  );
                }).toList(),
              ),
            ),

            _buildTextField(emailController, 'Correo electrónico', keyboardType: TextInputType.emailAddress),
            _buildTextField(displayNameController, 'Nombre de usuario'),
            _buildTextField(passwordController, 'Contraseña', obscureText: true),
            _buildTextField(confirmPasswordController, 'Confirmar contraseña', obscureText: true),

            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(errorText!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Validaciones básicas
                  if (passwordController.text != confirmPasswordController.text) {
                    setState(() {
                      errorText = 'Las contraseñas no coinciden';
                    });
                    return;
                  }
                  if (selectedDate == null) {
                    setState(() {
                      errorText = 'Por favor, selecciona tu fecha de nacimiento';
                    });
                    return;
                  }
                  if (selectedGender == null) {
                    setState(() {
                      errorText = 'Por favor, selecciona tu género';
                    });
                    return;
                  }

                  setState(() {
                    errorText = null;
                  });

                  // Ejemplo de llamada al authProvider, adapta para enviar los datos extras
                  await authProvider.signUp(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    displayName: displayNameController.text.trim(),
                    // Aquí deberías enviar también los otros datos si tu authProvider lo soporta
                    // fullName: fullNameController.text.trim(),
                    // phone: phoneController.text.trim(),
                    // address: addressController.text.trim(),
                    // dob: selectedDate,
                    // gender: selectedGender,
                    // profileImage: profileImage,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A9AE2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text(
                  'Registrarse',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (authProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  authProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF4F8FF),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6A9AE2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFABC6F7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6A9AE2)),
          ),
        ),
      ),
    );
  }
}
