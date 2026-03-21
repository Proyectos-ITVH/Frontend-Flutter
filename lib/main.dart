import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'loginScreen.dart';

/// ===============================
/// HANDLER PARA NOTIFICACIONES EN BACKGROUND
/// ===============================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Notificación recibida en background: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// Registrar handler de mensajes en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// Pedir permisos de notificación
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);

  print("🔔 Permiso notificaciones: ${settings.authorizationStatus}");

  /// Obtener token FCM para verificar que se genere
  String? token = await FirebaseMessaging.instance.getToken();

  print("🔥 TOKEN FCM GENERADO: $token");

  /// Listener cuando llega una notificación con la app abierta
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Notificación recibida en foreground");
    print("Título: ${message.notification?.title}");
    print("Cuerpo: ${message.notification?.body}");
  });

  // Inicializamos localización
  await initializeDateFormatting('es_ES', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IOT Calidad del agua',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black87,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
