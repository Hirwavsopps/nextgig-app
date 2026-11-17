import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/core/utils/formatters.dart';

void main() {
  test('formatRwf adds thousands separators', () {
    expect(formatRwf(0), '0 RWF');
    expect(formatRwf(950), '950 RWF');
    expect(formatRwf(25000), '25,000 RWF');
    expect(formatRwf(1250000), '1,250,000 RWF');
  });

  test('formatRwfCompact shortens large amounts', () {
    expect(formatRwfCompact(950), '950 RWF');
    expect(formatRwfCompact(85000), '85K RWF');
    expect(formatRwfCompact(2000000), '2M RWF');
    expect(formatRwfCompact(1500000), '1.5M RWF');
  });

  test('timeAgo describes elapsed time with a fixed clock', () {
    final now = DateTime(2026, 11, 17, 12);
    expect(timeAgo(DateTime(2026, 11, 17, 11, 59, 30), now: now), 'just now');
    expect(timeAgo(DateTime(2026, 11, 17, 11, 45), now: now), '15m ago');
    expect(timeAgo(DateTime(2026, 11, 17, 9), now: now), '3h ago');
    expect(timeAgo(DateTime(2026, 11, 14, 12), now: now), '3d ago');
  });
}
