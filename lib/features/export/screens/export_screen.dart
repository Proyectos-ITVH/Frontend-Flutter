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
  // SOLO UI HELPERS (como exp.dart)
  // =========================

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
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

  Widget _glassBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
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
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
        onChanged: (v) {
          setState(() => _selectedSensor = v!);
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
  // UI PRINCIPAL (MISMO DISEÑO exp.dart)
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
                    onPressed: () {},
                  ),

                  const SizedBox(height: 10),

                  _actionButton(
                    text: "Exportar Excel",
                    icon: Icons.table_chart,
                    color: Colors.green,
                    onPressed: () {},
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
