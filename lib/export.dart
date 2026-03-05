// Librerías base de Dart
import 'dart:io'; // Manejo de archivos
import 'dart:typed_data'; // Manejo de bytes

// Flutter y Firebase
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Librerías para exportación
import 'package:pdf/widgets.dart' as pw; // PDF
import 'package:path/path.dart' as path; // Rutas de archivos
import 'package:excel/excel.dart'; // Excel

// Pantalla para exportar datos
class ExportarScreen extends StatefulWidget {
  // Estanque recibido desde la pantalla anterior
  final String Estanque;
  const ExportarScreen({super.key, required this.Estanque});

  @override
  State<ExportarScreen> createState() => _ExportarScreenState();
}

class _ExportarScreenState extends State<ExportarScreen> {
  // Fechas seleccionadas por el usuario
  DateTime? _startDate;
  DateTime? _endDate;

  // Sensores disponibles para exportar
  final List<String> _sensorOptions = [
    'Todos',
    'temperatura',
    'ph',
    'oxigeno',
    'turbidez',
    'solidos_disueltos',
  ];

  // Sensor actualmente seleccionado
  String _selectedSensor = 'Todos';

  // Mapa de meses en español para parsear fechas
  static const Map<String, int> _meses = {
    'enero': 1,
    'febrero': 2,
    'marzo': 3,
    'abril': 4,
    'mayo': 5,
    'junio': 6,
    'julio': 7,
    'agosto': 8,
    'septiembre': 9,
    'octubre': 10,
    'noviembre': 11,
    'diciembre': 12,
  };

  // Convierte una fecha en texto (español) a DateTime
  DateTime? _parseFechaFromSpanishString(String fechaStr) {
    try {
      if (fechaStr.trim().isEmpty) return null;

      // Normaliza espacios y formato
      String s =
          fechaStr
              .replaceAll('\u202F', ' ')
              .replaceAll('\u00A0', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .toLowerCase()
              .trim();

      // Expresión regular para fechas en español
      final regex = RegExp(
        r'^(\d{1,2})\s+de\s+([a-záéíóúñ]+)\s+de\s+(\d{4}),\s*(\d{1,2}):(\d{2}):(\d{2})\s*(a\.m\.|p\.m\.)?$',
      );

      final m = regex.firstMatch(s);
      if (m != null) {
        final dia = int.parse(m.group(1)!);
        final mes = _meses[m.group(2)!] ?? 0;
        final anio = int.parse(m.group(3)!);
        int hora = int.parse(m.group(4)!);
        final minuto = int.parse(m.group(5)!);
        final segundo = int.parse(m.group(6)!);
        final ampm = m.group(7);

        // Ajuste AM / PM
        if (ampm != null) {
          final a = ampm.replaceAll('.', '');
          if (a == 'pm' && hora < 12) hora += 12;
          if (a == 'am' && hora == 12) hora = 0;
        }

        return DateTime(anio, mes, dia, hora, minuto, segundo);
      }

      // Intenta parseo estándar
      return DateTime.tryParse(fechaStr);
    } catch (e) {
      print('Error parseando fecha: $e -- input: $fechaStr');
      return null;
    }
  }

  // Obtiene y filtra los datos desde Firestore
  Future<List<Map<String, dynamic>>> _getDataFromFirestore() async {
    if (_startDate == null || _endDate == null) return [];

    // Rango de fechas completo
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

    final col = FirebaseFirestore.instance.collection('lecturas_sensores');

    // Consulta por estanque
    QuerySnapshot querySnapshot =
        await col.where('estanqueId', isEqualTo: widget.Estanque).get();

    // Fallback si no encuentra resultados
    if (querySnapshot.docs.isEmpty) {
      querySnapshot = await col.get();
    }

    final filteredData = <Map<String, dynamic>>[];

    // Recorre documentos
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final docEstanque = (data['estanqueId'] ?? '').toString();
      if (docEstanque != widget.Estanque) continue;

      // Obtiene timestamp
      dynamic ts = data['timestamp'];
      DateTime? fecha;

      if (ts is Timestamp) {
        fecha = ts.toDate().toLocal();
      } else if (ts is String) {
        fecha = _parseFechaFromSpanishString(ts)?.toLocal();
      } else {
        continue;
      }

      if (fecha == null) continue;
      if (fecha.isBefore(startDateTime) || fecha.isAfter(endDateTime)) continue;

      // Mapa base con fecha
      Map<String, dynamic> mapItem = {
        'fecha': fecha.toIso8601String().replaceFirst('T', ' ').split('.')[0],
      };

      // Agrega sensores
      if (_selectedSensor == 'Todos') {
        for (var sensor in _sensorOptions.where((e) => e != 'Todos')) {
          mapItem[sensor] = data['valores_sensores']?[sensor]?.toString() ?? '';
        }
      } else {
        mapItem[_selectedSensor] =
            data['valores_sensores']?[_selectedSensor]?.toString() ?? '';
      }

      filteredData.add(mapItem);
    }

    // Orden cronológico
    filteredData.sort((a, b) => a['fecha'].compareTo(b['fecha']));
    return filteredData;
  }

  // Agrega unidades según el sensor
  String _agregarUnidad(String sensor, dynamic value) {
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

  // Exporta datos como PDF
  Future<void> _exportAsPdf() async {
    final data = await _getDataFromFirestore();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar.')),
      );
      return;
    }

    final pdf = pw.Document();

    // Encabezados
    List<String> headers = [
      'Fecha',
      ...(_selectedSensor == 'Todos'
          ? _sensorOptions.where((e) => e != 'Todos')
          : [_selectedSensor]),
    ];

    // Filas
    final tableData =
        data.map((item) {
          return [
            item['fecha'],
            ...(_selectedSensor == 'Todos'
                ? _sensorOptions
                    .where((e) => e != 'Todos')
                    .map((sensor) => _agregarUnidad(sensor, item[sensor]))
                : [_agregarUnidad(_selectedSensor, item[_selectedSensor])]),
          ];
        }).toList();

    pdf.addPage(
      pw.Page(
        build:
            (context) =>
                pw.Table.fromTextArray(headers: headers, data: tableData),
      ),
    );

    // Guarda PDF en Descargas
    final pdfBytes = await pdf.save();
    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) await directory.create(recursive: true);

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

  // Exporta datos como Excel
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

    // Encabezados
    List<String> headers = [
      'Fecha',
      ...(_selectedSensor == 'Todos'
          ? _sensorOptions.where((e) => e != 'Todos')
          : [_selectedSensor]),
    ];

    // Escribe encabezados
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    // Escribe filas
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final rowIndex = i + 1;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(item['fecha']);

      final sensores =
          _selectedSensor == 'Todos'
              ? _sensorOptions.where((e) => e != 'Todos')
              : [_selectedSensor];

      int colIndex = 1;
      for (var sensor in sensores) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(_agregarUnidad(sensor, item[sensor]));
        colIndex++;
      }
    }

    final bytes = excel.encode();
    if (bytes == null || bytes.isEmpty) return;

    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) await directory.create(recursive: true);

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

  // Selector de fechas
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          isStart
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = selectedDate;
        } else {
          _endDate = selectedDate;
        }
      });
    }
  }

  // Widget selector de fecha
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

  // Dropdown de sensores
  Widget _buildSensorDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButton<String>(
        value: _selectedSensor,
        items:
            _sensorOptions
                .map(
                  (sensor) =>
                      DropdownMenuItem(value: sensor, child: Text(sensor)),
                )
                .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedSensor = value;
            });
          }
        },
        isExpanded: true,
        underline: Container(),
      ),
    );
  }

  // UI principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exportar archivos"),
        backgroundColor: Color(0xFF005BBB),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDatePicker('Fecha de inicio:', true),
                  const SizedBox(height: 10),
                  _buildDatePicker('Fecha de fin:', false),
                  const SizedBox(height: 20),
                  _buildSensorDropdown(),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Exportar como PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _exportAsPdf,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.table_chart),
                    label: const Text("Exportar como Excel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _exportAsExcel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
