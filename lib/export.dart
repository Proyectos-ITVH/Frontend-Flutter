import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;

class ExportarScreen extends StatefulWidget {
  const ExportarScreen({super.key});

  @override
  State<ExportarScreen> createState() => _ExportarScreenState();
}

class _ExportarScreenState extends State<ExportarScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
        } else {
          _endDate = selectedDate;
        }
      });
    }
  }

  DateTime parseCustomDate(String fechaStr) {
    try {
      // Ejemplo: "20 - 06 - 2025 15:46:50"
      final dateTimeParts = fechaStr.split(' ');
      if (dateTimeParts.length < 6) throw FormatException('Formato incorrecto');

      final day = int.parse(dateTimeParts[0]);
      final month = int.parse(dateTimeParts[2]);
      final year = int.parse(dateTimeParts[4]);

      final timeParts = dateTimeParts[5].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      throw FormatException('Error al parsear fecha personalizada: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getDataFromFirestore() async {
    if (_startDate == null || _endDate == null) return [];

    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      0,
      0,
      0,
    );
    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      23,
      59,
      59,
      999,
    );

    final querySnapshot =
        await FirebaseFirestore.instance.collection('temperatura').get();

    final filteredData = <Map<String, dynamic>>[];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      if (!data.containsKey('fecha') || !data.containsKey('temperatura')) {
        continue;
      }

      try {
        final fechaStr = data['fecha'] as String;
        final fecha = parseCustomDate(fechaStr);

        if (!fecha.isBefore(startDateTime) && !fecha.isAfter(endDateTime)) {
          filteredData.add({
            'fecha': fecha.toLocal().toString().split('.')[0],
            'temperatura': data['temperatura'].toString(),
          });
        }
      } catch (e) {
        continue;
      }
    }

    filteredData.sort((a, b) => a['fecha'].compareTo(b['fecha']));

    return filteredData;
  }

  Future<void> _exportAsExcel() async {
    final data = await _getDataFromFirestore();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar.')),
      );
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];
    sheet.appendRow([TextCellValue('Fecha'), TextCellValue('Temperatura')]);

    for (var item in data) {
      sheet.appendRow([
        TextCellValue(item['fecha']),
        TextCellValue(item['temperatura']),
      ]);
    }

    final bytes = await excel.encode();
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al generar el archivo Excel.')),
      );
      return;
    }

    final directory = Directory('/storage/emulated/0/Download');
    final file = File(
      path.join(
        directory.path,
        'datos_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      ),
    );
    await file.writeAsBytes(Uint8List.fromList(bytes));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Excel guardado en: ${file.path}')));
  }

  Future<void> _exportAsPdf() async {
    final data = await _getDataFromFirestore();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar.')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Table.fromTextArray(
              headers: ['Fecha', 'Temperatura'],
              data:
                  data
                      .map((item) => [item['fecha'], item['temperatura']])
                      .toList(),
            ),
      ),
    );

    final pdfBytes = await pdf.save();

    final directory = Directory('/storage/emulated/0/Download');
    final file = File(
      path.join(
        directory.path,
        'datos_${DateTime.now().millisecondsSinceEpoch}.pdf',
      ),
    );
    await file.writeAsBytes(Uint8List.fromList(pdfBytes));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF guardado en: ${file.path}')));
  }

  Widget _buildDatePicker(String label, bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => _selectDate(context, isStart),
            child: Text(
              date == null
                  ? 'Seleccionar fecha'
                  : date.toLocal().toString().split(' ')[0],
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exportar archivos"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDatePicker('Fecha de inicio:', true),
                const SizedBox(height: 10),
                _buildDatePicker('Fecha de fin:', false),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.table_chart),
                  label: const Text("Exportar como Excel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _exportAsExcel,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Exportar como PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _exportAsPdf,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
