import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/url.dart';

class AuthService {
  /// =========================
  /// LOGIN API
  /// =========================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.API_BASE_URL}/users/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Error al iniciar sesión');
    }

    return data;
  }

  /// =========================
  /// FCM TOKEN
  /// =========================
  Future<void> saveFcmToken(String email) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    QueryDocumentSnapshot? userDoc;

    for (var doc in snapshot.docs) {
      final firestoreEmail = doc['email'];
      if (firestoreEmail.toLowerCase() == email.toLowerCase()) {
        userDoc = doc;
        break;
      }
    }

    if (userDoc == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userDoc.id).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
