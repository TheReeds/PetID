import 'package:apppetid/presentation/providers/auth_provider.dart';
import 'package:apppetid/presentation/screens/auth/register_screen.dart';
import 'package:apppetid/presentation/screens/auth/login_screen.dart'; // Importa tu HomeScreen
import 'package:apppetid/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppPetid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      // Usar Consumer para manejar el estado de autenticación
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Si está cargando inicialmente, mostrar pantalla de carga
          if (authProvider.state == AuthState.initial ||
              (authProvider.isLoading && authProvider.currentUser == null)) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8F9FA),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF4A7AA7),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'PetID',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A7AA7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Si el usuario está autenticado, ir al HomeScreen
          if (authProvider.isAuthenticated && authProvider.currentUser != null) {
            return const HomeScreen(); // Cambiado de AuthScreen a HomeScreen
          }

          // Si no está autenticado, mostrar LoginScreen
          return const LoginScreen();
        },
      ),
      // Definir rutas para navegación
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        // Agrega más rutas según necesites
      },
    );
  }
}