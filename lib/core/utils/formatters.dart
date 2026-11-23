/// Formats an amount as Rwandan francs, e.g. 25000 -> "25,000 RWF".
String formatRwf(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${buffer.toString()} RWF';
}

/// Short form for tight spaces, e.g. 85000 -> "85K RWF", 1500000 -> "1.5M RWF".
String formatRwfCompact(int amount) {
  if (amount >= 1000000) {
    final millions = amount / 1000000;
    final text = millions == millions.roundToDouble()
        ? millions.round().toString()
        : millions.toStringAsFixed(1);
    return '${text}M RWF';
  }
  if (amount >= 1000) {
    return '${(amount / 1000).round()}K RWF';
  }
  return '$amount RWF';
}

/// "just now", "5m ago", "2h ago", "3d ago". [now] exists so tests can fix the clock.
String timeAgo(DateTime time, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(time);
  if (difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  return '${difference.inDays}d ago';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// e.g. "12 Nov 2026".
String formatDate(DateTime time) =>
    '${time.day} ${_months[time.month - 1]} ${time.year}';
