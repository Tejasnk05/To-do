import 'package:intl/intl.dart';

/// Formats a DateTime as the yyyy-MM-dd key used throughout the storage layer.
String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

DateTime todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Returns the Monday that starts the ISO week containing [date].
DateTime startOfWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// Mon..Sat (6 days) for the week containing [anchor]. Sunday is excluded
/// per the user's request (Sunday is a holiday / not tracked).
List<DateTime> weekdaysMonToSat(DateTime anchor) {
  final monday = startOfWeek(anchor);
  return List.generate(6, (i) => monday.add(Duration(days: i)));
}

/// ISO-8601 week number (1-52/53).
int isoWeekNumber(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  final dayOfWeek = d.weekday; // Mon=1..Sun=7
  final thursday = d.add(Duration(days: 4 - dayOfWeek));
  final firstDayOfYear = DateTime.utc(thursday.year, 1, 1);
  final weekNumber =
      ((thursday.difference(firstDayOfYear).inDays) / 7).floor() + 1;
  return weekNumber;
}

String weekRangeLabel(DateTime anchor) {
  final days = weekdaysMonToSat(anchor);
  final first = days.first;
  final last = days.last;
  final sameMonth = first.month == last.month;
  final fmtDay = DateFormat('d');
  final fmtDayMonth = DateFormat('d MMM');
  final fmtYear = DateFormat('yyyy');
  if (sameMonth) {
    return '${fmtDay.format(first)}-${fmtDayMonth.format(last)} ${fmtYear.format(last)}';
  }
  return '${fmtDayMonth.format(first)} - ${fmtDayMonth.format(last)} ${fmtYear.format(last)}';
}

int daysInMonth(int year, int month) {
  final firstOfNextMonth =
      (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return firstOfNextMonth.subtract(const Duration(days: 1)).day;
}

/// Days of [year]-[month] from the 1st up to today (if it's the current
/// month) or through the end of the month (if it's a past month).
List<DateTime> elapsedDaysOfMonth(int year, int month) {
  final total = daysInMonth(year, month);
  final today = todayDateOnly();
  final isCurrentMonth = today.year == year && today.month == month;
  final lastDay = isCurrentMonth ? today.day : total;
  return List.generate(lastDay, (i) => DateTime(year, month, i + 1));
}
