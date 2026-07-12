import 'package:flutter_test/flutter_test.dart';
import 'package:sudan_free/utils/safe_parse.dart';

void main() {
  group('SafeParse.string', () {
    test('returns string value unchanged', () {
      expect(SafeParse.string('hello'), 'hello');
    });

    test('returns fallback for null', () {
      expect(SafeParse.string(null), '');
      expect(SafeParse.string(null, 'default'), 'default');
    });

    test('converts int to string', () {
      expect(SafeParse.string(42), '42');
    });
  });

  group('SafeParse.integer', () {
    test('returns int value unchanged', () {
      expect(SafeParse.integer(5), 5);
    });

    test('returns fallback for null', () {
      expect(SafeParse.integer(null), 0);
      expect(SafeParse.integer(null, -1), -1);
    });

    test('parses numeric string', () {
      expect(SafeParse.integer('10'), 10);
    });

    test('returns fallback for non-numeric string', () {
      expect(SafeParse.integer('abc', 99), 99);
    });

    test('converts double to int', () {
      expect(SafeParse.integer(3.9), 3);
    });
  });

  group('SafeParse.decimal', () {
    test('returns double unchanged', () {
      expect(SafeParse.decimal(3.14), 3.14);
    });

    test('returns fallback for null', () {
      expect(SafeParse.decimal(null), 0.0);
    });

    test('converts int to double', () {
      expect(SafeParse.decimal(5), 5.0);
    });

    test('parses numeric string', () {
      expect(SafeParse.decimal('2.5'), 2.5);
    });
  });

  group('SafeParse.boolean', () {
    test('returns bool unchanged', () {
      expect(SafeParse.boolean(true), true);
      expect(SafeParse.boolean(false), false);
    });

    test('returns fallback for null', () {
      expect(SafeParse.boolean(null), false);
    });

    test('interprets 1 as true, 0 as false', () {
      expect(SafeParse.boolean(1), true);
      expect(SafeParse.boolean(0), false);
    });
  });

  group('SafeParse.nullableString', () {
    test('returns null for null input', () {
      expect(SafeParse.nullableString(null), null);
    });

    test('returns null for empty string', () {
      expect(SafeParse.nullableString(''), null);
    });

    test('returns the string for non-empty value', () {
      expect(SafeParse.nullableString('text'), 'text');
    });
  });

  group('SafeParse.stringList', () {
    test('returns list of strings', () {
      expect(SafeParse.stringList(['a', 'b', 'c']), ['a', 'b', 'c']);
    });

    test('returns empty list for null', () {
      expect(SafeParse.stringList(null), <String>[]);
    });

    test('returns empty list for non-list', () {
      expect(SafeParse.stringList('not a list'), <String>[]);
    });
  });
}

