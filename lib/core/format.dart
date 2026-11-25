import 'package:intl/intl.dart';

final _rm = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM', decimalDigits: 2);

String rm(num value) => _rm.format(value);

const _hari = ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad'];
const _bulan = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis'];

String dayName(DateTime d) => _hari[d.weekday - 1];
const _hariPendek = ['Isn', 'Sel', 'Rab', 'Kha', 'Jum', 'Sab', 'Ahd'];

String dayShort(DateTime d) => _hariPendek[d.weekday - 1];
String monthShort(DateTime d) => _bulan[d.month - 1];

/// e.g. "Sabtu, 28 Nov 2026"
String longDate(DateTime d) => '${dayName(d)}, ${d.day} ${monthShort(d)} ${d.year}';

/// e.g. "28 Nov"
String shortDate(DateTime d) => '${d.day} ${monthShort(d)}';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Minutes-from-midnight → "10:00 PG" style label.
String timeLabel(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final suffix = h < 12 ? 'PG' : (h < 19 ? 'PTG' : 'MLM');
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $suffix';
}
