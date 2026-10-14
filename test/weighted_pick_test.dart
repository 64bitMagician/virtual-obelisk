import 'dart:math';

import 'package:art_platform/core/feed_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [pickWeighted], the "spin the wheel" used by the feed algorithm to pick
/// users (weighted by Artist Points) and posts (weighted by likes).
void main() {
  group('pickWeighted', () {
    test('returns null for an empty list', () {
      expect(pickWeighted<String>([], (_) => 1, Random(1)), isNull);
    });

    test('always returns the only item of a single-item list', () {
      for (var i = 0; i < 100; i++) {
        expect(pickWeighted(['only'], (_) => 500, Random(i)), 'only');
      }
    });

    test('never returns null for a non-empty list', () {
      final random = Random(7);
      final items = [0, 3, 10, 250];
      for (var i = 0; i < 1000; i++) {
        expect(pickWeighted(items, (w) => w, random), isNotNull);
      }
    });

    test('picks items proportionally to their weight', () {
      // Weights 1, 3 and 6 => expected chances of 10%, 30% and 60%
      final weights = {'a': 1, 'b': 3, 'c': 6};
      final counts = {'a': 0, 'b': 0, 'c': 0};
      final random = Random(42);
      const spins = 20000;

      for (var i = 0; i < spins; i++) {
        final picked = pickWeighted(weights.keys.toList(), (k) => weights[k]!, random)!;
        counts[picked] = counts[picked]! + 1;
      }

      expect(counts['a']! / spins, closeTo(0.10, 0.02));
      expect(counts['b']! / spins, closeTo(0.30, 0.02));
      expect(counts['c']! / spins, closeTo(0.60, 0.02));
    });

    test('items with 0 weight still have a chance (they count as weight 1)', () {
      // A new artist with 0 Artist Points must still be able to appear in the feed
      final random = Random(3);
      var newArtistPicked = 0;

      for (var i = 0; i < 5000; i++) {
        if (pickWeighted(['new artist', 'popular artist'], (k) => k == 'new artist' ? 0 : 9, random) == 'new artist') {
          newArtistPicked++;
        }
      }

      // Expected chance: 1 / (1 + 9) = 10%
      expect(newArtistPicked / 5000, closeTo(0.10, 0.02));
    });
  });
}
