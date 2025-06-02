import 'package:apppetid/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apppetid/presentation/screens/home/add_first_pet_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final displayNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (authProvider.isAuthenticated)
              Column(
                children: [
                  Text('Bienvenido, ${authProvider.currentUser?.displayName ?? 'Usuario'}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: authProvider.signOut,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(labelText: 'Nombre (solo registro)'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await authProvider.signIn(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                    },
                    child: const Text('Iniciar sesión'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await authProvider.signUp(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                        displayName: displayNameController.text.trim(),
                      );
                    },
                    child: const Text('Registrarse'),
                  ),
                  if (authProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.g_mobiledata,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    label: const Text('Continuar con Google'),
                    onPressed: authProvider.isLoading ? null : () async {
                      final success = await authProvider.signInWithGoogle();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('¡Bienvenido!')),
                        );
                        if (mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const AddFirstPetScreen(),
                            ),
                          );
                        }
                      } else if (authProvider.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authProvider.errorMessage!)),
                        );
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
