// Librerías base
import 'dart:io';
import 'dart:typed_data';

// Flutter y Firebase
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Exportación
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:excel/excel.dart';

class ExportarScreen extends StatefulWidget {
  final String Estanque;
  const ExportarScreen({super.key, required this.Estanque});

  @override
  State<ExportarScreen> createState() => _ExportarScreenState();
}

class _ExportarScreenState extends State<ExportarScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _sensorOptions = [
    'Todos',
    'temperatura',
    'ph',
    'oxigeno',
    'turbidez',
    'solidos_disueltos',
  ];

  String _selectedSensor = 'Todos';

  /// 🔥 OBTENER DATOS (FIX REAL)
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
    );

    final col = FirebaseFirestore.instance.collection('lecturas_sensores');

    QuerySnapshot querySnapshot;

    try {
      querySnapshot =
          await col
              .where('estanqueId', isEqualTo: widget.Estanque)
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDateTime),
              )
              .where(
                'timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endDateTime),
              )
              .orderBy('timestamp')
              .get();
    } catch (e) {
      // fallback para datos viejos (String)
      querySnapshot =
          await col.where('estanqueId', isEqualTo: widget.Estanque).get();
    }

    final filteredData = <Map<String, dynamic>>[];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      DateTime? fecha;
      final ts = data['timestamp'];

      if (ts is Timestamp) {
        fecha = ts.toDate().toLocal();
      } else if (ts is String) {
        fecha = DateTime.tryParse(ts)?.toLocal();
      }

      if (fecha == null) continue;

      if (fecha.isBefore(startDateTime) || fecha.isAfter(endDateTime)) continue;

      Map<String, dynamic> mapItem = {
        'fecha': fecha.toIso8601String().replaceFirst('T', ' ').split('.')[0],
      };

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

    filteredData.sort((a, b) => a['fecha'].compareTo(b['fecha']));
    return filteredData;
  }

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

  /// 📄 PDF SIN ERROR
  Future<void> _exportAsPdf() async {
    final data = await _getDataFromFirestore();

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar.')),
      );
      return;
    }

    final pdf = pw.Document();

    List<String> headers = [
      'Fecha',
      ...(_selectedSensor == 'Todos'
          ? _sensorOptions.where((e) => e != 'Todos')
          : [_selectedSensor]),
    ];

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

    /// 🔥 FIX TooManyPagesException
    const rowsPerPage = 25;

    for (int i = 0; i < tableData.length; i += rowsPerPage) {
      final chunk = tableData.skip(i).take(rowsPerPage).toList();

      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Table.fromTextArray(headers: headers, data: chunk);
          },
        ),
      );
    }

    final bytes = await pdf.save();

    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) await directory.create(recursive: true);

    final file = File(
      path.join(
        directory.path,
        'datos_${DateTime.now().millisecondsSinceEpoch}.pdf',
      ),
    );

    await file.writeAsBytes(Uint8List.fromList(bytes));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF guardado en: ${file.path}')));
  }

  /// 📊 EXCEL
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

    List<String> headers = [
      'Fecha',
      ...(_selectedSensor == 'Todos'
          ? _sensorOptions.where((e) => e != 'Todos')
          : [_selectedSensor]),
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

      final sensores =
          _selectedSensor == 'Todos'
              ? _sensorOptions.where((e) => e != 'Todos')
              : [_selectedSensor];

      int col = 1;

      for (var sensor in sensores) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1))
            .value = TextCellValue(_agregarUnidad(sensor, item[sensor]));
        col++;
      }
    }

    final bytes = excel.encode();
    if (bytes == null) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exportar archivos"),
        backgroundColor: const Color(0xFF005BBB),
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
