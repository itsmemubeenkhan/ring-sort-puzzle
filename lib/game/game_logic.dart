import 'dart:math';

import '../models/level.dart';

/// Core game state and rules for Ring Sort Puzzle.
class GameLogic {
  List<List<int>> pegs;
  List<Move> history = [];
  int freeUndosLeft;
  int extraPegsAdded = 0;

  // Peg capacity: 4 rings (matches level generation).
  static const int pegCapacity = 4;

  GameLogic({required this.pegs, this.freeUndosLeft = 3});

  GameLogic.fromLevel(int level)
      : pegs = LevelGenerator.generate(level),
        freeUndosLeft = 3;

  int get pegCount => pegs.length;

  bool get isWon {
    for (final peg in pegs) {
      if (peg.isEmpty) continue;
      if (peg.length != pegCapacity) return false;
      if (!peg.every((c) => c == peg.first)) return false;
    }
    return true;
  }

  /// Attempt to move the top ring from [from] to [to].
  /// Returns true if the move was valid and applied.
  bool move(int from, int to) {
    if (from == to) return false;
    if (from < 0 || from >= pegs.length) return false;
    if (to < 0 || to >= pegs.length) return false;
    final src = pegs[from];
    final dst = pegs[to];
    if (src.isEmpty) return false;
    if (dst.length >= pegCapacity) return false;
    final ring = src.last;
    if (dst.isNotEmpty && dst.last != ring) return false;

    src.removeLast();
    dst.add(ring);
    history.add(Move(fromPeg: from, toPeg: to, colorIndex: ring));
    return true;
  }

  /// Undo the last move. Returns true if undone.
  bool undo() {
    if (history.isEmpty) return false;
    final last = history.removeLast();
    final dst = pegs[last.toPeg];
    final src = pegs[last.fromPeg];
    if (dst.isEmpty || dst.last != last.colorIndex) return false;
    dst.removeLast();
    src.add(last.colorIndex);
    return true;
  }

  /// Shuffle all rings across non-empty pegs (keeps counts).
  void shuffle() {
    final all = <int>[];
    for (final peg in pegs) {
      all.addAll(peg);
      peg.clear();
    }
    final rng = _QuickRandom();
    all.shuffle(rng);
    // Re-deal into pegs, keeping each peg within capacity.
    int i = 0;
    for (final ring in all) {
      int tries = 0;
      while (pegs[i % pegs.length].length >= pegCapacity &&
          tries < pegs.length * 2) {
        i++;
        tries++;
      }
      pegs[i % pegs.length].add(ring);
      i++;
    }
    history.clear();
  }

  /// Add one empty peg for this level.
  void addExtraPeg() {
    pegs.add(<int>[]);
    extraPegsAdded++;
  }

  /// Auto-place one ring correctly: find a ring whose color matches a peg
  /// that already has that color on top (or an empty peg if none), and move it.
  /// Returns true if a move was made.
  bool magicSort() {
    for (int from = 0; from < pegs.length; from++) {
      final src = pegs[from];
      if (src.isEmpty) continue;
      final ring = src.last;
      // Prefer a peg whose top is the same color.
      for (int to = 0; to < pegs.length; to++) {
        if (to == from) continue;
        final dst = pegs[to];
        if (dst.isNotEmpty &&
            dst.last == ring &&
            dst.length < pegCapacity) {
          return move(from, to);
        }
      }
      // Otherwise an empty peg.
      for (int to = 0; to < pegs.length; to++) {
        if (to == from) continue;
        if (pegs[to].isEmpty) {
          return move(from, to);
        }
      }
    }
    return false;
  }

  /// Serialize for saving (in-progress level).
  List<List<int>> snapshot() => pegs.map((p) => List<int>.from(p)).toList();
}


class _QuickRandom implements Random {
  int _s = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;

  @override
  int nextInt(int max) {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s % max;
  }

  @override
  double nextDouble() => nextInt(1000000) / 1000000.0;

  @override
  bool nextBool() => nextInt(2) == 0;

  void shuffle(List list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
  }
}
