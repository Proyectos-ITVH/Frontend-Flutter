import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecoverPasswordService {
  static Future<bool> sendResetEmail({
    required BuildContext context,
    required String email,
  }) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!context.mounted) return false;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.mark_email_read_rounded, color: Color(0xFF005BBB)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "El correo se envió",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(),
                SizedBox(height: 10),
                Text(
                  "Siga estas instrucciones:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                Text("• Revise spam si no aparece."),
                SizedBox(height: 12),
                Text("• El enlace expira por seguridad."),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005BBB),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("¡Entendido!"),
                ),
              ),
            ],
          );
        },
      );

      return true;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
      return false;
    }
  }
}
