import 'package:firebase_messaging/firebase_messaging.dart'; //Importación para uso en web
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart'; // generado por flutterfire configure
import 'loginScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Inicialización para web
  await FirebaseMessaging.instance.requestPermission();

  // Inicializamos la localización para Español (España)
  await initializeDateFormatting('es_ES', null); // Ahora 'es_ES' es un String

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
