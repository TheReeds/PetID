import 'package:apppetid/presentation/providers/auth_provider.dart';
import 'package:apppetid/presentation/providers/chat_provider.dart';
import 'package:apppetid/presentation/providers/comment_provider.dart';
import 'package:apppetid/presentation/providers/match_provider.dart';
import 'package:apppetid/presentation/providers/pet_provider.dart';
import 'package:apppetid/presentation/providers/post_provider.dart';
import 'package:apppetid/presentation/providers/user_provider.dart';
import 'package:apppetid/presentation/providers/lost_pet_provider.dart'; // NUEVO
import 'package:apppetid/presentation/screens/auth/register_screen.dart';
import 'package:apppetid/presentation/screens/auth/login_screen.dart';
import 'package:apppetid/presentation/screens/chat/chat_list_screen.dart';
import 'package:apppetid/presentation/screens/chat/chat_screen.dart';
import 'package:apppetid/presentation/screens/home/add_first_pet_screen.dart';
import 'package:apppetid/presentation/screens/home/home_screen.dart';
import 'package:apppetid/presentation/screens/pets/add_pet_screen.dart';
import 'package:apppetid/presentation/screens/pets/my_pets.dart';
import 'package:apppetid/presentation/screens/pets/lost_pets_screen.dart'; // NUEVO
import 'package:apppetid/presentation/screens/social/discover_screen.dart';
import 'package:apppetid/presentation/screens/social/feed_screen.dart';
import 'package:apppetid/presentation/screens/social/post_create_screen.dart';
import 'package:apppetid/presentation/screens/social/profile_screen.dart';
import 'package:apppetid/data/services/notification_service.dart'; // NUEVO
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar servicio de notificaciones
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => LostPetProvider()), // NUEVO
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      // Usar Consumer para manejar el estado de autenticación
      home: Consumer2<AuthProvider, PetProvider>(
        builder: (context, authProvider, petProvider, child) {
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

          // Si el usuario está autenticado
          if (authProvider.isAuthenticated && authProvider.currentUser != null) {
            // Guardar token FCM cuando se autentica
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await NotificationService.saveDeviceToken(authProvider.currentUser!.id);
            });

            // Cargar mascotas del usuario si no se han cargado
            if (petProvider.state == PetState.idle) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                petProvider.loadUserPets(authProvider.currentUser!.id);
              });

              // Mostrar loading mientras cargan las mascotas
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
                        'Cargando tus mascotas...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A7AA7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Si ya cargaron las mascotas, decidir qué mostrar
            if (petProvider.userPets.isEmpty) {
              return const AddFirstPetScreen(); // Pantalla para agregar primera mascota
            } else {
              return const HomeScreen(); // Pantalla principal con mascotas
            }
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
        '/add-first-pet': (context) => const AddFirstPetScreen(),
        '/add-pet': (context) => const AddPetScreen(),
        '/my-pets': (context) => const MyPetsScreen(),
        '/lost-pets': (context) => const LostPetsScreen(), // NUEVO
        '/feed': (context) => const FeedScreen(),
        '/discover': (context) => const DiscoverScreen(),
        '/create-post': (context) => const PostCreateScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/chat-list': (context) => const ChatListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: args['chatId'] as String,
                currentUserId: args['currentUserId'] as String,
              ),
            );
          }
        }
        return null;
      },
    );
  }
}