import 'dart:io';

import 'package:flutter/material.dart';
import '../service/export_service.dart';

class ExportScreen extends StatefulWidget {
  final String estanqueSeleccionado;

  const ExportScreen({super.key, required this.estanqueSeleccionado});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService service = ExportService();

  DateTime? _startDate;
  DateTime? _endDate;

  String _selectedSensor = 'Todos';

  final List<String> sensors = const [
    'Todos',
    'temperatura',
    'ph',
    'oxigeno',
    'turbidez',
    'solidos_disueltos',
  ];

  // =========================
  // DIALOGOS
  // =========================

  Future<void> _showResultDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // EXPORTAR PDF
  // =========================

  Future<void> _exportPdf() async {
    if (_startDate == null || _endDate == null) {
      await _showResultDialog(
        title: "Fechas requeridas",
        message:
            "Debes seleccionar una fecha de inicio y una fecha de fin antes de exportar.",
      );
      return;
    }

    try {
      final data = await service.getData(
        estanqueId: widget.estanqueSeleccionado,
        start: _startDate!,
        end: _endDate!,
        selectedSensor: _selectedSensor,
      );

      if (data.isEmpty) {
        await _showResultDialog(
          title: "Sin datos",
          message:
              "No se encontraron registros para exportar en el rango seleccionado.",
        );
        return;
      }

      const outputPath = ExportService.exportFolder;

      final directory = Directory(outputPath);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = await service.exportPdf(
        data: data,
        selectedSensor: _selectedSensor,
        outputPath: outputPath,
      );

      await _showResultDialog(
        title: "Exportación completada",
        message:
            "El archivo PDF se guardó correctamente.\n\n"
            "Ubicación:\n${file.path}",
      );
    } catch (e) {
      await _showResultDialog(
        title: "Error",
        message: "Ocurrió un error al exportar el PDF.\n\n$e",
      );
    }
  }

  // =========================
  // EXPORTAR EXCEL
  // =========================

  Future<void> _exportExcel() async {
    if (_startDate == null || _endDate == null) {
      await _showResultDialog(
        title: "Fechas requeridas",
        message:
            "Debes seleccionar una fecha de inicio y una fecha de fin antes de exportar.",
      );
      return;
    }

    try {
      final data = await service.getData(
        estanqueId: widget.estanqueSeleccionado,
        start: _startDate!,
        end: _endDate!,
        selectedSensor: _selectedSensor,
      );

      if (data.isEmpty) {
        await _showResultDialog(
          title: "Sin datos",
          message:
              "No se encontraron registros para exportar en el rango seleccionado.",
        );
        return;
      }

      const outputPath = ExportService.exportFolder;

      final directory = Directory(outputPath);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = await service.exportExcel(
        data: data,
        selectedSensor: _selectedSensor,
        outputPath: outputPath,
      );

      await _showResultDialog(
        title: "Exportación completada",
        message:
            "El archivo Excel se guardó correctamente.\n\n"
            "Ubicación:\n${file.path}",
      );
    } catch (e) {
      await _showResultDialog(
        title: "Error",
        message: "Ocurrió un error al exportar el Excel.\n\n$e",
      );
    }
  }
  // =========================
  // DATE PICKER
  // =========================

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate:
          isStart
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  // =========================
  // UI HELPERS
  // =========================

  Widget _glassBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _datePicker(String label, bool isStart) {
    final date = isStart ? _startDate : _endDate;

    return _glassBox(
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => _pickDate(isStart),
            child: Text(
              date == null
                  ? "Seleccionar fecha"
                  : date.toString().split(" ")[0],
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorDropdown() {
    return _glassBox(
      child: DropdownButton<String>(
        value: _selectedSensor,
        isExpanded: true,
        underline: Container(),
        items:
            sensors
                .map(
                  (sensor) =>
                      DropdownMenuItem(value: sensor, child: Text(sensor)),
                )
                .toList(),
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _selectedSensor = value;
          });
        },
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // =========================
  // UI PRINCIPAL
  // =========================

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
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _datePicker("Fecha de inicio:", true),

                  const SizedBox(height: 10),

                  _datePicker("Fecha de fin:", false),

                  const SizedBox(height: 20),

                  _sensorDropdown(),

                  const SizedBox(height: 20),

                  _actionButton(
                    text: "Exportar PDF",
                    icon: Icons.picture_as_pdf,
                    color: Colors.red,
                    onPressed: _exportPdf,
                  ),

                  const SizedBox(height: 10),

                  _actionButton(
                    text: "Exportar Excel",
                    icon: Icons.table_chart,
                    color: Colors.green,
                    onPressed: _exportExcel,
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
