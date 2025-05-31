import 'package:apppetid/presentation/providers/auth_provider.dart';
import 'package:apppetid/presentation/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  bool isPasswordVisible = false;
  String? errorText;
  final _formKey = GlobalKey<FormState>();

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
    super.dispose();
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

  bool _validateForm(AuthProvider authProvider) {
    setState(() {
      errorText = null;
    });

    // Validar campos obligatorios
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      setState(() {
        errorText = 'Por favor completa todos los campos obligatorios';
      });
      return false;
    }

    // Validar nombre si es registro
    if (!isLogin && nameController.text.trim().isEmpty) {
      setState(() {
        errorText = 'Por favor ingresa tu nombre';
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

    // Validar contraseña (más estricto para registro)
    if (!isLogin) {
      final passwordError = authProvider.validatePassword(passwordController.text);
      if (passwordError != null) {
        setState(() {
          errorText = passwordError;
        });
        return false;
      }
    } else {
      // Para login, solo validar que no esté vacía
      if (passwordController.text.trim().isEmpty) {
        setState(() {
          errorText = 'Por favor ingresa tu contraseña';
        });
        return false;
      }
    }

    return true;
  }

  Future<void> _handleSubmit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!_validateForm(authProvider)) return;

    HapticFeedback.mediumImpact();

    bool success = false;

    if (isLogin) {
      success = await authProvider.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (success) {
        _showSnackBar('¡Bienvenido de nuevo!');
        // Navegar a la pantalla principal - el Consumer en main.dart se encargará automáticamente
        // No necesitas navegación manual aquí
      }
    } else {
      success = await authProvider.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        displayName: nameController.text.trim(),
      );
      if (success) {
        _showSnackBar('¡Registro exitoso! Bienvenido a PetID');
        // El Consumer en main.dart se encargará automáticamente de la navegación
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: authProvider.isAuthenticated
            ? _buildAuthenticatedView(authProvider)
            : _buildLoginView(authProvider),
      ),
    );
  }

  Widget _buildAuthenticatedView(AuthProvider authProvider) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A7AA7),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A7AA7).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'PetID',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A7AA7),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Text(
                  'Bienvenido, ${authProvider.currentUser?.displayName ?? 'Usuario'}!',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              _buildButton(
                text: 'Ir al inicio',
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                isPrimary: true,
                icon: Icons.home_rounded,
                isLoading: false,
              ),
              const SizedBox(height: 16),
              _buildButton(
                text: 'Cerrar sesión',
                onPressed: () async {
                  await authProvider.signOut();
                  _showSnackBar('Sesión cerrada exitosamente');
                },
                isPrimary: false,
                icon: Icons.logout_rounded,
                isLoading: authProvider.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView(AuthProvider authProvider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo animado
              ScaleTransition(
                scale: _logoAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A7AA7),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A7AA7).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Título con animación
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A7AA7),
                          height: 1.2,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        isLogin
                            ? 'Ingresa tus credenciales para continuar'
                            : 'Completa la información para registrarte',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Formulario con animación
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 2),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 25,
                              offset: const Offset(0, 15),
                              spreadRadius: -5,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Campo de nombre (solo para registro)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              height: isLogin ? 0 : 80,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: isLogin ? 0 : 1,
                                child: !isLogin ? _buildTextField(
                                  controller: nameController,
                                  label: 'Nombre completo',
                                  icon: Icons.person_outline_rounded,
                                  prefixText: '👤',
                                ) : const SizedBox.shrink(),
                              ),
                            ),

                            // Campo de email
                            _buildTextField(
                              controller: emailController,
                              label: 'Correo electrónico',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              prefixText: '📧',
                            ),
                            const SizedBox(height: 20),

                            // Campo de contraseña
                            _buildTextField(
                              controller: passwordController,
                              label: 'Contraseña',
                              icon: Icons.lock_outline_rounded,
                              obscureText: !isPasswordVisible,
                              prefixText: '🔒',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF4A7AA7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                              ),
                            ),

                            // Mensaje de error local
                            if (errorText != null) ...[
                              const SizedBox(height: 20),
                              _buildErrorMessage(errorText!),
                            ],

                            // Mensaje de error del provider
                            if (authProvider.errorMessage != null) ...[
                              const SizedBox(height: 20),
                              _buildErrorMessage(authProvider.errorMessage!),
                            ],

                            const SizedBox(height: 32),

                            // Botón principal
                            _buildButton(
                              text: authProvider.isLoading
                                  ? (isLogin ? 'Iniciando sesión...' : 'Registrando...')
                                  : (isLogin ? 'Iniciar sesión' : 'Registrarse'),
                              onPressed: authProvider.isLoading ? () {} : _handleSubmit,
                              isPrimary: true,
                              icon: isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                              isLoading: authProvider.isLoading,
                            ),

                            const SizedBox(height: 24),

                            // Separador elegante
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.grey.withOpacity(0.4),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'O',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.grey.withOpacity(0.4),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Botón de Google mejorado
                            _buildGoogleButton(authProvider),

                            const SizedBox(height: 24),

                            // Botones de navegación
                            if (isLogin) ...[
                              // Registro completo
                              _buildSecondaryButton(
                                text: 'Crear cuenta completa',
                                onPressed: _navigateToRegister,
                                icon: Icons.person_add_alt_rounded,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Link "¿No tienes cuenta?" / "¿Ya tienes cuenta?"
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  isLogin = !isLogin;
                                  nameController.clear();
                                  emailController.clear();
                                  passwordController.clear();
                                  errorText = null;
                                });
                                // Limpiar errores del provider
                                Provider.of<AuthProvider>(context, listen: false).clearError();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 15,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: isLogin
                                            ? '¿No tienes cuenta? '
                                            : '¿Ya tienes cuenta? ',
                                      ),
                                      TextSpan(
                                        text: isLogin ? 'Registrarse' : 'Iniciar sesión',
                                        style: const TextStyle(
                                          color: Color(0xFF4A7AA7),
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefixText,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF333333),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A7AA7).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              prefixText ?? '',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.15),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFF4A7AA7),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFBFC),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: const Color(0xFF4A7AA7).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ] : null,
        border: !isPrimary ? Border.all(
          color: const Color(0xFF4A7AA7).withOpacity(0.3),
          width: 1.5,
        ) : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF4A7AA7) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF4A7AA7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isPrimary ? Colors.white : const Color(0xFF4A7AA7),
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF4A7AA7).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4A7AA7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () async {
          HapticFeedback.lightImpact();
          // Implementar Google Sign In cuando esté disponible
          _showSnackBar('Google Sign In próximamente disponible', isError: false);

          // Descomenta cuando implementes Google Sign In:
          // final success = await authProvider.signInWithGoogle();
          // if (success) {
          //   _showSnackBar('¡Bienvenido!');
          // }
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF333333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                ),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continuar con Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}