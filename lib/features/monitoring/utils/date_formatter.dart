import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTimestamp(Timestamp timestamp) {
    final DateTime utcDate = timestamp.toDate().toUtc();

    final DateTime mexicoTime = utcDate.subtract(const Duration(hours: 6));

    final DateFormat dateFormat = DateFormat(
      "d 'de' MMMM 'de' yyyy, h:mm:ss a",
      'es_MX',
    );

    return dateFormat.format(mexicoTime);
  }
}
