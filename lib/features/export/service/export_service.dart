import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> sensores = [
    'temperatura',
    'ph',
    'oxigeno',
    'turbidez',
    'solidos_disueltos',
  ];

  DateTime toMexicoTime(Timestamp ts) {
    final utc = ts.toDate().toUtc();
    return utc.subtract(const Duration(hours: 6));
  }

  String formatFecha(DateTime fecha) {
    return "${fecha.year.toString().padLeft(4, '0')}-"
        "${fecha.month.toString().padLeft(2, '0')}-"
        "${fecha.day.toString().padLeft(2, '0')} "
        "${fecha.hour.toString().padLeft(2, '0')}:"
        "${fecha.minute.toString().padLeft(2, '0')}:"
        "${fecha.second.toString().padLeft(2, '0')}";
  }

  Future<List<Map<String, dynamic>>> getData({
    required String estanqueId,
    required DateTime start,
    required DateTime end,
    required String selectedSensor,
  }) async {
    final startLocal = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final endLocal = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final startUTC = startLocal.add(const Duration(hours: 6));
    final endUTC = endLocal.add(const Duration(hours: 6));

    QuerySnapshot snapshot;

    try {
      snapshot =
          await _firestore
              .collection('lecturas_sensores')
              .where('estanqueId', isEqualTo: estanqueId)
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startUTC),
              )
              .where(
                'timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endUTC),
              )
              .orderBy('timestamp')
              .get();
    } catch (_) {
      snapshot =
          await _firestore
              .collection('lecturas_sensores')
              .where('estanqueId', isEqualTo: estanqueId)
              .get();
    }

    final List<Map<String, dynamic>> result = [];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      final ts = data['timestamp'];
      DateTime? fecha;

      if (ts is Timestamp) {
        fecha = toMexicoTime(ts);
      } else if (ts is String) {
        fecha = DateTime.tryParse(ts);
      }

      if (fecha == null) continue;

      final map = <String, dynamic>{'fecha': formatFecha(fecha)};

      if (selectedSensor == 'Todos') {
        for (final s in sensores) {
          map[s] = data['valores_sensores']?[s]?.toString() ?? '';
        }
      } else {
        map[selectedSensor] =
            data['valores_sensores']?[selectedSensor]?.toString() ?? '';
      }

      result.add(map);
    }

    result.sort((a, b) => a['fecha'].compareTo(b['fecha']));
    return result;
  }

  String addUnit(String sensor, dynamic value) {
    if (value == null || value.toString().isEmpty) return '';

    switch (sensor) {
      case 'temperatura':
        return '$value °C';
      case 'ph':
        return '$value pH';
      case 'oxigeno':
        return '$value mg/L';
      case 'turbidez':
        return '$value NTU';
      case 'solidos_disueltos':
        return '$value mg/L';
      default:
        return value.toString();
    }
  }

  Future<File> exportPdf({
    required List<Map<String, dynamic>> data,
    required String selectedSensor,
    required String outputPath,
  }) async {
    final pdf = pw.Document();

    final headers = [
      'Fecha',
      if (selectedSensor == 'Todos') ...sensores else selectedSensor,
    ];

    final rows =
        data.map((item) {
          return [
            item['fecha'],
            if (selectedSensor == 'Todos')
              ...sensores.map((s) => addUnit(s, item[s]))
            else
              addUnit(selectedSensor, item[selectedSensor]),
          ];
        }).toList();

    const rowsPerPage = 25;

    for (int i = 0; i < rows.length; i += rowsPerPage) {
      final chunk = rows.skip(i).take(rowsPerPage).toList();

      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Table.fromTextArray(headers: headers, data: chunk);
          },
        ),
      );
    }

    final bytes = await pdf.save();

    final file = File(
      path.join(
        outputPath,
        'datos_${DateTime.now().millisecondsSinceEpoch}.pdf',
      ),
    );

    await file.writeAsBytes(Uint8List.fromList(bytes));

    return file;
  }

  Future<File> exportExcel({
    required List<Map<String, dynamic>> data,
    required String selectedSensor,
    required String outputPath,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headers = [
      'Fecha',
      if (selectedSensor == 'Todos') ...sensores else selectedSensor,
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    for (int i = 0; i < data.length; i++) {
      final item = data[i];

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = TextCellValue(item['fecha']);

      int col = 1;

      final sensoresList =
          selectedSensor == 'Todos' ? sensores : [selectedSensor];

      for (final s in sensoresList) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1))
            .value = TextCellValue(addUnit(s, item[s]));
        col++;
      }
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception("Error al generar Excel");
    }

    final file = File(
      path.join(
        outputPath,
        'datos_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      ),
    );

    await file.writeAsBytes(Uint8List.fromList(bytes));

    return file;
  }
}
