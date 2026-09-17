import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');

  /// Format date as "Jan 5, 2024"
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }

  /// Format date and time as "Jan 5, 2024 14:30"
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  /// Format time as "14:30:05"
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  /// Format date as "05/01/2024"
  static String formatShortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime.toLocal());
  }

  /// Format duration as "HH:MM:SS"
  static String formatDuration(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Format speed in m/s to km/h string
  static String formatSpeed(double metersPerSecond) {
    final kmh = metersPerSecond * 3.6;
    return '${kmh.toStringAsFixed(1)} km/h';
  }
}
