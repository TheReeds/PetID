import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/lost_pet_model.dart';
import 'firebase_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _projectId = 'apppetid-1ff32'; // ⚠️ CAMBIAR ESTO por tu project ID

  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Permisos de notificación: ${settings.authorizationStatus}');
    }

    // Configuración Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // ✅ Configuración iOS añadida
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    // Inicialización combinada
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static Future<String?> getDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo token FCM: $e');
      }
      return null;
    }
  }

  static Future<void> saveDeviceToken(String userId) async {
    try {
      final token = await getDeviceToken();
      if (token != null) {
        await FirebaseService.users.doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': Timestamp.now(),
        });

        if (kDebugMode) {
          print('Token FCM guardado para usuario: $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error guardando token: $e');
      }
    }
  }

  static Future<void> sendLostPetNotification(LostPetModel lostPet) async {
    try {
      if (kDebugMode) {
        print('Creando notificación de mascota perdida...');
      }

      await FirebaseService.firestore.collection('mass_notifications').add({
        'type': 'lost_pet',
        'title': '🚨 Mascota Perdida',
        'body': '${lostPet.petName} se perdió en ${lostPet.lastSeenLocationName}',
        'data': {
          'type': 'lost_pet',
          'reportId': lostPet.id,
          'petName': lostPet.petName,
          'location': lostPet.lastSeenLocationName,
          'contactPhone': lostPet.contactPhone,
          'reward': lostPet.reward ?? '',
          'imageUrl': lostPet.photos.isNotEmpty ? lostPet.photos.first : '',
        },
        'createdAt': Timestamp.now(),
        'processed': false,
      });

      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: '🚨 Mascota Perdida Reportada',
        body: '${lostPet.petName} se perdió en ${lostPet.lastSeenLocationName}',
        payload: 'lost_pet_${lostPet.id}',
      );

      await _sendToTopic(
        topic: 'all_users',
        title: '🚨 Mascota Perdida',
        body: '${lostPet.petName} se perdió en ${lostPet.lastSeenLocationName}',
        data: {
          'type': 'lost_pet',
          'reportId': lostPet.id,
          'petName': lostPet.petName,
          'location': lostPet.lastSeenLocationName,
        },
      );

      if (kDebugMode) {
        print('Notificación de mascota perdida procesada');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error enviando notificación de mascota perdida: $e');
      }
    }
  }

  static Future<void> _sendToTopic({
    required String topic,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      await _messaging.sendMessage(
        to: '/topics/$topic',
        data: data,
      );

      if (kDebugMode) {
        print('Mensaje enviado al tópico: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error enviando a tópico: $e');
      }
    }
  }

  static Future<void> subscribeToAllNotifications() async {
    try {
      await _messaging.subscribeToTopic('all_users');
      if (kDebugMode) {
        print('Suscrito al tópico all_users');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error suscribiéndose al tópico: $e');
      }
    }
  }

  static Future<void> unsubscribeFromAllNotifications() async {
    try {
      await _messaging.unsubscribeFromTopic('all_users');
      if (kDebugMode) {
        print('Desuscrito del tópico all_users');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error desuscribiéndose del tópico: $e');
      }
    }
  }

  static Future<void> sendPetFoundNotification(String reportId) async {
    try {
      final reportDoc = await FirebaseService.lostPets.doc(reportId).get();
      if (!reportDoc.exists) return;

      final lostPet = LostPetModel.fromFirestore(reportDoc);

      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: '🎉 ¡Buenas Noticias!',
        body: '${lostPet.petName} ha sido encontrada',
        payload: 'pet_found_$reportId',
      );

      await _sendToTopic(
        topic: 'all_users',
        title: '🎉 Mascota Encontrada',
        body: '${lostPet.petName} ha sido encontrada',
        data: {
          'type': 'pet_found',
          'reportId': reportId,
          'petName': lostPet.petName,
        },
      );

    } catch (e) {
      if (kDebugMode) {
        print('Error enviando notificación de mascota encontrada: $e');
      }
    }
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'lost_pets_channel',
      'Mascotas Perdidas',
      channelDescription: 'Notificaciones de mascotas perdidas y encontradas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4A7AA7),
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    if (kDebugMode) {
      print('Mensaje en segundo plano: ${message.messageId}');
    }

    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: message.notification?.title ?? 'PetID',
      body: message.notification?.body ?? 'Nueva notificación',
      payload: message.data['type'] ?? '',
    );
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Mensaje en primer plano: ${message.messageId}');
      print('Título: ${message.notification?.title}');
      print('Cuerpo: ${message.notification?.body}');
      print('Datos: ${message.data}');
    }

    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: message.notification?.title ?? 'PetID',
      body: message.notification?.body ?? 'Nueva notificación',
      payload: message.data['type'] ?? '',
    );
  }

  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    if (kDebugMode) {
      print('App abierta desde notificación: ${message.messageId}');
      print('Datos: ${message.data}');
    }
  }

  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    if (kDebugMode) {
      print('Notificación local tocada: ${notificationResponse.payload}');
    }
  }

  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
