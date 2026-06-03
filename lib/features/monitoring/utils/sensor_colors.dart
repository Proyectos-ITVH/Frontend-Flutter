import 'package:flutter/material.dart';

class SensorColors {
  static const Color azul = Color(0xFF005BBB);

  static Color determinarColor(String key, String valueStr) {
    double? value = double.tryParse(valueStr);

    if (value == null) {
      return Colors.grey;
    }

    final tipo = key.toLowerCase();

    if (tipo.contains('temperatura')) {
      if (value >= 20 && value <= 25) {
        return Colors.green;
      }

      if ((value >= 18 && value < 20) || (value > 25 && value <= 28)) {
        return Colors.amber;
      }

      return Colors.red;
    }

    if (tipo.contains('ph')) {
      if (value >= 6.5 && value <= 7.5) {
        return Colors.green;
      }

      if ((value >= 6 && value < 6.5) || (value > 7.5 && value <= 8)) {
        return Colors.amber;
      }

      return Colors.red;
    }

    if (tipo.contains('oxigeno')) {
      if (value >= 5 && value <= 7) {
        return Colors.green;
      }

      if ((value >= 4 && value < 5) || (value > 7 && value <= 8)) {
        return Colors.amber;
      }

      return Colors.red;
    }

    if (tipo.contains('tds') || tipo.contains('solidos_disueltos')) {
      if (value >= 20 && value <= 50) {
        return Colors.green;
      }

      if (value >= 60 && value <= 75) {
        return Colors.amber;
      }

      if (value > 100) {
        return Colors.red;
      }

      return Colors.red;
    }

    if (tipo.contains('turbidez')) {
      if (value >= 0 && value <= 5) {
        return Colors.green;
      }

      if (value > 5 && value <= 10) {
        return Colors.amber;
      }

      return Colors.red;
    }

    return azul;
  }

  static String agregarUnidad(String sensorKey, String value) {
    if (value == "Sin valores") {
      return value;
    }

    final key = sensorKey.toLowerCase();

    if (key.contains('temperatura')) {
      return '$value °C';
    }

    if (key.contains('ph')) {
      return '$value pH';
    }

    if (key.contains('oxigeno')) {
      return '$value mg/l';
    }

    return '$value ppm';
  }
}
