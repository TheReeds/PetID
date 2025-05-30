import 'package:apppetid/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
                ],
              ),
          ],
        ),
      ),
    );
  }
}
