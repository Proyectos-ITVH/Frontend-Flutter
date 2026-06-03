import 'package:cloud_firestore/cloud_firestore.dart';

class MonitoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> cargarEstanques() async {
    final snapshot = await _firestore.collection('estanques').get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<Map<String, bool>> cargarSensoresAsignados(String estanqueId) async {
    final doc = await _firestore.collection('estanques').doc(estanqueId).get();

    if (!doc.exists) {
      return {};
    }

    final data = doc.data();

    return Map<String, bool>.from(data?['sensores_asignados'] ?? {});
  }

  Stream<QuerySnapshot> obtenerUltimaLectura(String estanqueId) {
    return _firestore
        .collection('lecturas_sensores')
        .where('estanqueId', isEqualTo: estanqueId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }

  Future<Map<String, dynamic>?> obtenerUltimaLecturaMap(
    String estanqueId,
  ) async {
    final snapshot =
        await _firestore
            .collection('lecturas_sensores')
            .where('estanqueId', isEqualTo: estanqueId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.data();
  }
}
