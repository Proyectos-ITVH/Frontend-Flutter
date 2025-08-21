import 'package:flutter/material.dart';
import 'datos.dart';

class SelecStanq extends StatefulWidget {
  const SelecStanq({super.key});

  @override
  State<SelecStanq> createState() => _SelecStanqState();
}

class _SelecStanqState extends State<SelecStanq> {
  String _estanqueSeleccionado = 'Estanque1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/img.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset("assets/logo.png", height: 80),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 10,
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Presione "Generar" para visualizar los datos actuales del estanque:',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            DropdownButton<String>(
                              value: _estanqueSeleccionado,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Estanque1',
                                  child: Text('Estanque 1'),
                                ),
                                DropdownMenuItem(
                                  value: 'Estanque2',
                                  child: Text('Estanque 2'),
                                ),
                              ],
                              onChanged: (String? newValue) {
                                setState(() {
                                  _estanqueSeleccionado = newValue!;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => DatosScreen(
                                          Estanque: _estanqueSeleccionado,
                                        ),
                                  ),
                                );
                              },
                              child: const Text('Generar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
