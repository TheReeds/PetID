import 'package:apppetid/presentation/providers/auth_provider.dart';
import 'package:apppetid/presentation/screens/auth/register_screen.dart';
import 'package:apppetid/presentation/screens/home/add_first_pet_screen.dart';
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
  late AnimationController _logoAnimController;
  late Animation<double> _logoScaleAnim;

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

    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _logoScaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.elasticOut),
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
    _logoAnimController.dispose();
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

  void _onToggleRegister() {
    setState(() {
      isLogin = false;
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      errorText = null;
    });
    Provider.of<AuthProvider>(context, listen: false).clearError();
    _logoAnimController.forward(from: 0);
  }

  void _onToggleLogin() {
    setState(() {
      isLogin = true;
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      errorText = null;
    });
    Provider.of<AuthProvider>(context, listen: false).clearError();
    _logoAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: authProvider.isAuthenticated
          ? _buildAuthenticatedView(authProvider)
          : _buildLoginView(authProvider),
    );
  }

  Widget _buildAuthenticatedView(AuthProvider authProvider) {
    return SafeArea(
      child: Center(
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
      ),
    );
  }

  Widget _buildLoginView(AuthProvider authProvider) {
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
                                '¡Hola, Omar!',
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

                // Card scrollable con el mismo tamaño que RegisterScreen
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
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Accede a tu cuenta para gestionar tus mascotas',
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
                                    const SizedBox(height: 24),

                                    // Email
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
                                      hintText: 'Ingresa tu email',
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
                                      hintText: 'Ingresa tu contraseña',
                                      isPassword: true,
                                      obscureText: !isPasswordVisible,
                                      onSuffixTap: () {
                                        setState(() {
                                          isPasswordVisible = !isPasswordVisible;
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

                                    // Botón Iniciar Sesión
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
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Botón Google
                                    _buildGoogleButton(authProvider),

                                    const SizedBox(height: 24),

                                    // Enlaces inferiores
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            // Lógica de olvido de contraseña
                                          },
                                          child: const Text(
                                            '¿Olvidaste tu contraseña?',
                                            style: TextStyle(
                                              color: Color(0xFF4A7AA7),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _navigateToRegister,
                                          child: const Text(
                                            'Crear cuenta',
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

  // Botón Google moderno
  Widget _buildGoogleButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: authProvider.isLoading ? null : () async {
          HapticFeedback.lightImpact();
          final success = await authProvider.signInWithGoogle();
          if (success) {
            _showSnackBar('¡Bienvenido!');
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AddFirstPetScreen(),
                ),
              );
            }
          } else if (authProvider.errorMessage != null) {
            _showSnackBar(authProvider.errorMessage!, isError: true);
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.g_mobiledata,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continuar con Google',
              style: TextStyle(
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botón moderno para la vista autenticada
  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    IconData? icon,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF4A7AA7) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF4A7AA7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF4A7AA7), width: 1.2),
          ),
          elevation: isPrimary ? 2 : 0,
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7AA7)),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : const Color(0xFF4A7AA7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A7AA7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 0.15, 2.85, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}