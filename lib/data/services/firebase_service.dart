import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters para acceso directo
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseAuth get auth => _auth;
  static FirebaseStorage get storage => _storage;

  // Referencias de colecciones
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get pets => _firestore.collection('pets');
  static CollectionReference get posts => _firestore.collection('posts');
  static CollectionReference get lostPets => _firestore.collection('lost_pets');
  static CollectionReference get matches => _firestore.collection('matches');
  static CollectionReference get notifications => _firestore.collection('notifications');

  // Usuario actual
  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;

  // Stream del usuario actual
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Inicializar configuraciones de Firestore
  static Future<void> initialize() async {
    await _firestore.enableNetwork();
  }
}