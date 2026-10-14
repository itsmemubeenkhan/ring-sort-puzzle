import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/level.dart';
import '../providers/game_provider.dart';

/// Main gameplay screen: pegs with colored rings.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final logic = provider.logic;
    if (logic == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Level ${provider.currentLevel}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _coinBadge(context, provider),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart',
            onPressed: () => _confirmRestart(context, provider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _movesBar(provider),
            Expanded(child: _pegsArea(context, provider)),
            _powersBar(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _coinBadge(BuildContext context, GameProvider provider) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/shop'),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${provider.coins}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _movesBar(GameProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Moves: ${provider.moves}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (provider.freeUndosLeft > 0)
            Text(
              'Free undos: ${provider.freeUndosLeft}',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _pegsArea(BuildContext context, GameProvider provider) {
    final logic = provider.logic!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pegCount = logic.pegCount;
        // Responsive grid: up to 4 columns.
        final columns = pegCount <= 4 ? pegCount : 4;
        final pegWidth = constraints.maxWidth / columns;
        final pegHeight = constraints.maxHeight / ((pegCount / columns).ceil());
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: pegWidth / pegHeight,
          ),
          itemCount: pegCount,
          itemBuilder: (context, i) => _peg(context, provider, i),
        );
      },
    );
  }

  Widget _peg(BuildContext context, GameProvider provider, int index) {
    final logic = provider.logic!;
    final rings = logic.pegs[index];
    final selected = provider.selectedPeg == index;
    final canReceive = selected == false &&
        provider.selectedPeg != null &&
        (rings.isEmpty ||
            (rings.length < 4 &&
                rings.last ==
                    logic.pegs[provider.selectedPeg!].last));

    return GestureDetector(
      onTap: () {
        final result = provider.tapPeg(index);
        if (result == 'won') {
          _showWinDialog(context, provider);
        } else if (result == 'invalid') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Can't place that ring there"),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1E3A5F)
              : canReceive
                  ? const Color(0xFF14331F)
                  : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: Colors.lightBlueAccent, width: 2)
              : canReceive
                  ? Border.all(color: Colors.greenAccent, width: 2)
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Rings (bottom -> top), rendered top-first visually.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int r = rings.length - 1; r >= 0; r--)
                    _ring(rings[r], r == rings.length - 1 && selected),
                ],
              ),
            ),
            // Peg base
            Container(
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(int colorIndex, bool lifted) {
    final color = LevelGenerator.ringColors[colorIndex % LevelGenerator.ringColors.length];
    // Ring width shrinks slightly toward the top for a stacked look.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 30,
      margin: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: lifted ? 6 : 2,
      ),
      transform: lifted ? Matrix4.translationValues(0, -8, 0) : Matrix4.identity(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.75), color],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: lifted ? 12 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget _powersBar(BuildContext context, GameProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _powerButton(
            context,
            icon: Icons.undo,
            label: provider.freeUndosLeft > 0
                ? 'Undo (${provider.freeUndosLeft} free)'
                : 'Undo (10)',
            onTap: () async {
              final r = await provider.useUndo();
              _powerResult(context, r);
            },
          ),
          _powerButton(
            context,
            icon: Icons.shuffle,
            label: 'Shuffle (50)',
            onTap: () async {
              final r = await provider.useShuffle();
              _powerResult(context, r);
            },
          ),
          _powerButton(
            context,
            icon: Icons.add_circle_outline,
            label: 'Peg (80)',
            onTap: () async {
              final r = await provider.useExtraPeg();
              _powerResult(context, r);
            },
          ),
          _powerButton(
            context,
            icon: Icons.auto_awesome,
            label: 'Magic (100)',
            onTap: () async {
              final r = await provider.useMagicSort();
              if (r == 'won') {
                _showWinDialog(context, provider);
              } else {
                _powerResult(context, r);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _powerButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.amberAccent, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _powerResult(BuildContext context, String result) {
    if (result == 'no_coins') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins. Visit the shop!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmRestart(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Restart level?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your progress on this level will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.restartLevel();
            },
            child: const Text('Restart', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showWinDialog(BuildContext context, GameProvider provider) {
    final reward = LevelGenerator.coinsForLevel(provider.currentLevel);
    final hasNext = provider.currentLevel < LevelGenerator.maxLevels;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Level Complete!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 56),
            const SizedBox(height: 12),
            Text(
              'You earned $reward coins',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 18),
            ),
            Text(
              'Moves: ${provider.moves}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // dialog
              Navigator.pop(context); // game screen -> level select
            },
            child: const Text('Levels'),
          ),
          if (hasNext)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.nextLevel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }
}
