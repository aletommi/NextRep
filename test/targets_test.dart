import 'package:flutter_test/flutter_test.dart';
import 'package:nextrep/core/utils/targets.dart';

void main() {
  group('targetForSet', () {
    test('single value applies to every set', () {
      expect(targetForSet('10', 0), '10');
      expect(targetForSet('10', 5), '10');
    });

    test('comma separated values map to set index', () {
      expect(targetForSet('10, 8,6', 0), '10');
      expect(targetForSet('10, 8,6', 1), '8');
      expect(targetForSet('10, 8,6', 2), '6');
    });

    test('falls back to last value past the list', () {
      expect(targetForSet('10,8', 4), '8');
    });

    test('empty or null gives empty string', () {
      expect(targetForSet(null, 0), '');
      expect(targetForSet('  ', 0), '');
    });
  });

  group('parseWeight / parseReps', () {
    test('parses decimals with dot or comma', () {
      expect(parseWeight('60'), 60);
      expect(parseWeight('62.5'), 62.5);
      expect(parseWeight('62,5'), 62.5);
    });

    test('invalid or zero weight is null', () {
      expect(parseWeight(''), isNull);
      expect(parseWeight('0'), isNull);
      expect(parseWeight('abc'), isNull);
    });

    test('reps takes the first number of a range', () {
      expect(parseReps('8-10'), 8);
      expect(parseReps('12'), 12);
      expect(parseReps('max'), isNull);
    });
  });

  group('targetVolume', () {
    test('sums reps x weight over the sets', () {
      expect(targetVolume(sets: '3', reps: '10', weight: '50'), 1500);
      expect(targetVolume(sets: '3', reps: '10,8,6', weight: '50,60,70'), 1400);
    });

    test('is zero without weight targets', () {
      expect(targetVolume(sets: '3', reps: '10', weight: null), 0);
    });
  });
}
