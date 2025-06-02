import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/lost_pet_model.dart';
import '../models/event_model.dart';
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
  static Future<void> sendNewEventNotification(EventModel event) async {
    try {
      if (kDebugMode) {
        print('Enviando notificación de nuevo evento...');
      }

      // Crear documento en mass_notifications para referencia futura
      await FirebaseService.firestore.collection('mass_notifications').add({
        'type': 'new_event',
        'title': '🎉 Nuevo Evento Disponible',
        'body': '${event.title} - ${_formatEventDate(event.startDate)}',
        'data': {
          'type': 'new_event',
          'eventId': event.id,
          'eventTitle': event.title,
          'eventType': event.type.toString().split('.').last,
          'startDate': event.startDate.toIso8601String(),
          'location': event.location.address ?? event.displayLocation,
          'creatorId': event.creatorId,
          'isPetFriendly': event.isPetFriendly.toString(),
          'isFree': event.isFree.toString(),
        },
        'createdAt': Timestamp.now(),
        'processed': false,
      });

      // Mostrar notificación local inmediatamente
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: '🎉 Nuevo Evento',
        body: '${event.title} - ${_formatEventDate(event.startDate)}',
        payload: 'new_event_${event.id}',
      );

      // Enviar notificación a todos los usuarios usando tópicos
      await _sendToTopic(
        topic: 'all_users',
        title: '🎉 Nuevo Evento Disponible',
        body: '${event.title} - ${_formatEventDate(event.startDate)}',
        data: {
          'type': 'new_event',
          'eventId': event.id,
          'eventTitle': event.title,
          'eventType': event.type.toString().split('.').last,
          'startDate': event.startDate.toIso8601String(),
          'location': event.location.address ?? event.displayLocation,
        },
      );

      if (kDebugMode) {
        print('Notificación de nuevo evento procesada');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error enviando notificación de nuevo evento: $e');
      }
      // No lanzar excepción para no interrumpir el flujo principal
    }
  }

// Enviar notificación cuando alguien se une a un evento
  static Future<void> sendEventJoinNotification(EventModel event, String participantName) async {
    try {
      if (kDebugMode) {
        print('Enviando notificación de participación en evento...');
      }

      // Solo al creador del evento
      await _sendToUser(
        userId: event.creatorId,
        title: '👥 Nuevo Participante',
        body: '$participantName se unió a tu evento "${event.title}"',
        data: {
          'type': 'event_join',
          'eventId': event.id,
          'eventTitle': event.title,
          'participantName': participantName,
        },
      );

    } catch (e) {
      if (kDebugMode) {
        print('Error enviando notificación de participación: $e');
      }
    }
  }

// Enviar notificación de recordatorio de evento (próximo a iniciar)
  static Future<void> sendEventReminderNotification(EventModel event) async {
    try {
      if (kDebugMode) {
        print('Enviando recordatorio de evento...');
      }

      // Solo a los participantes del evento
      for (String participantId in event.participants) {
        await _sendToUser(
          userId: participantId,
          title: '⏰ Recordatorio de Evento',
          body: '${event.title} comienza en 1 hora',
          data: {
            'type': 'event_reminder',
            'eventId': event.id,
            'eventTitle': event.title,
            'startTime': event.startDate.toIso8601String(),
            'location': event.location.address ?? event.displayLocation,
          },
        );
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error enviando recordatorio de evento: $e');
      }
    }
  }

// Enviar notificación cuando se cancela un evento
  static Future<void> sendEventCancelledNotification(EventModel event) async {
    try {
      if (kDebugMode) {
        print('Enviando notificación de evento cancelado...');
      }

      // A todos los participantes
      for (String participantId in event.participants) {
        await _sendToUser(
          userId: participantId,
          title: '❌ Evento Cancelado',
          body: 'El evento "${event.title}" ha sido cancelado',
          data: {
            'type': 'event_cancelled',
            'eventId': event.id,
            'eventTitle': event.title,
          },
        );
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error enviando notificación de cancelación: $e');
      }
    }
  }

// Metodo auxiliar para enviar notificación a un usuario específico
  static Future<void> _sendToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // Obtener el token FCM del usuario
      final userDoc = await FirebaseService.users.doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken != null) {
        // Aquí podrías usar una función en la nube para enviar la notificación
        // Por ahora, usar el metodo de tópico como fallback
        await _sendToTopic(
          topic: 'user_$userId',
          title: title,
          body: body,
          data: data,
        );
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error enviando notificación a usuario: $e');
      }
    }
  }

// Metodo auxiliar para formatear fecha del evento
  static String _formatEventDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Mañana ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${DateFormat('EEEE HH:mm', 'es').format(dateTime)}';
    } else {
      return DateFormat('dd/MM HH:mm').format(dateTime);
    }
  }

// Suscribirse a notificaciones de eventos
  static Future<void> subscribeToEventNotifications() async {
    try {
      await _messaging.subscribeToTopic('events');
      if (kDebugMode) {
        print('Suscrito a notificaciones de eventos');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error suscribiéndose a eventos: $e');
      }
    }
  }

// Desuscribirse de notificaciones de eventos
  static Future<void> unsubscribeFromEventNotifications() async {
    try {
      await _messaging.unsubscribeFromTopic('events');
      if (kDebugMode) {
        print('Desuscrito de notificaciones de eventos');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error desuscribiéndose de eventos: $e');
      }
    }
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
