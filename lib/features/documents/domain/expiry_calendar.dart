/// Local calendar-day helpers for document expiry (Module 8 / 11 / list card styling).
int calendarDaysUntilExpiry(DateTime expiry) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final exp = expiry.toLocal();
  final expiryDay = DateTime(exp.year, exp.month, exp.day);
  return expiryDay.difference(today).inDays;
}

/// Matches list-card urgent styling: overdue or fewer than 7 calendar days left.
bool isExpiryUrgentRed(DateTime expiry) => calendarDaysUntilExpiry(expiry) < 7;
