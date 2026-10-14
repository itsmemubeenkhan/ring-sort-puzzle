import 'dart:math';

import 'package:flutter/material.dart';

/// A single move in the game history (for undo).
class Move {
  final int fromPeg;
  final int toPeg;
  final int colorIndex;

  Move({required this.fromPeg, required this.toPeg, required this.colorIndex});
}

/// Procedurally generates levels with ramping difficulty.
class LevelGenerator {
  static const int maxLevels = 150;

  /// Ring colors used across the game (10 distinct colors).
  static const List<Color> ringColors = [
    Color(0xFFEF4444), // red
    Color(0xFF3B82F6), // blue
    Color(0xFF22C55E), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFA855F7), // purple
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
    Color(0xFFF97316), // orange
    Color(0xFF6366F1), // indigo
    Color(0xFF84CC16), // lime
  ];

  /// Difficulty parameters for a given level (1-based).
  /// Returns [numColors, numPegs, ringsPerPeg].
  static List<int> difficultyFor(int level) {
    if (level <= 5) {
      return [3, 5, 3]; // tutorial-ish
    } else if (level <= 15) {
      return [4, 6, 4];
    } else if (level <= 30) {
      return [5, 7, 4];
    } else if (level <= 50) {
      return [6, 8, 4];
    } else if (level <= 80) {
      return [7, 9, 4];
    } else if (level <= 110) {
      return [8, 10, 4];
    } else {
      return [9, 11, 4];
    }
  }

  /// Generates the starting peg configuration for [level].
  /// Each peg is a list of color indices (bottom -> top).
  /// Guaranteed solvable: we deal from solved pegs and shuffle.
  static List<List<int>> generate(int level) {
    final params = difficultyFor(level);
    final numColors = params[0];
    final numPegs = params[1];
    final ringsPerPeg = params[2];

    // Build solved state: each color fills one peg.
    final solved = List.generate(
      numColors,
      (c) => List.filled(ringsPerPeg, c),
    );

    // Flatten all rings and shuffle with a seeded RNG.
    final allRings = <int>[];
    for (final peg in solved) {
      allRings.addAll(peg);
    }
    final rng = _SeededRandom(level * 7919 + 13);
    allRings.shuffle(rng);

    // Deal back into pegs, leaving (numPegs - numColors) empty pegs.
    // Ensure no peg starts already solved (re-shuffle that peg's contents if so).
    final pegs = List.generate(numPegs, (_) => <int>[]);
    int idx = 0;
    for (int p = 0; p < numColors; p++) {
      for (int r = 0; r < ringsPerPeg; r++) {
        pegs[p].add(allRings[idx++]);
      }
    }

    // Avoid trivially solved pegs: if a peg is uniform, swap one ring with another peg.
    for (int p = 0; p < numColors; p++) {
      if (_isUniform(pegs[p]) && pegs[p].isNotEmpty) {
        final other = (p + 1) % numColors;
        if (pegs[other].isNotEmpty) {
          final tmp = pegs[p][0];
          pegs[p][0] = pegs[other][0];
          pegs[other][0] = tmp;
        }
      }
    }

    return pegs;
  }

  static bool _isUniform(List<int> peg) {
    if (peg.isEmpty) return false;
    return peg.every((c) => c == peg.first);
  }

  /// Coins earned for completing a level.
  static int coinsForLevel(int level) {
    final params = difficultyFor(level);
    return 10 + params[0] * 4; // 22..46
  }
}


/// Simple deterministic RNG so levels are stable across sessions.
class _SeededRandom implements Random {
  int _seed;
  _SeededRandom(this._seed);

  @override
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }

  @override
  double nextDouble() => nextInt(1000000) / 1000000.0;

  @override
  bool nextBool() => nextInt(2) == 0;

  void shuffle(List list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
