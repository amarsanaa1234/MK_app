import 'package:intl/intl.dart';

/// A fixed Monday-to-Sunday fortnight. Every screen that reports hours or
/// pay (Employees, Timesheets, My timesheet) uses the same periods, so
/// "paid" can be tracked against one stable range instead of a window that
/// slides forward every day.
class PayPeriod {
  static const _lengthDays = 14;
  // A Monday — periods are counted in whole fortnights from here.
  static final _anchor = DateTime.utc(2024, 1, 1);

  final DateTime start;
  const PayPeriod._(this.start);

  factory PayPeriod.containing(DateTime date) {
    final days = DateTime.utc(date.year, date.month, date.day).difference(_anchor).inDays;
    final first = _anchor.add(Duration(days: (days / _lengthDays).floor() * _lengthDays));
    return PayPeriod._(DateTime(first.year, first.month, first.day));
  }

  factory PayPeriod.current() => PayPeriod.containing(DateTime.now());

  DateTime get end => DateTime(start.year, start.month, start.day + _lengthDays - 1);

  PayPeriod get previous => PayPeriod.containing(DateTime(start.year, start.month, start.day - 1));

  PayPeriod get next => PayPeriod.containing(DateTime(start.year, start.month, start.day + _lengthDays));

  bool get isCurrent => start == PayPeriod.current().start;

  String get label => '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM').format(end)}';
}
