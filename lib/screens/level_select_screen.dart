import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/level.dart';
import '../providers/game_provider.dart';

/// Level select grid with unlock progress.
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final maxUnlocked = provider.maxLevelUnlocked;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Select Level',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${provider.coins}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: LevelGenerator.maxLevels,
        itemBuilder: (context, i) {
          final level = i + 1;
          final unlocked = level <= maxUnlocked;
          final completed = level < maxUnlocked;
          return GestureDetector(
            onTap: unlocked
                ? () {
                    provider.startLevel(level);
                    Navigator.pushNamed(context, '/game');
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFF166534)
                    : unlocked
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: unlocked
                    ? Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            '$level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (completed)
                            const Icon(Icons.check,
                                color: Colors.greenAccent,
                                size: 14),
                        ],
                      )
                    : const Icon(Icons.lock,
                        color: Colors.white24, size: 20),
              ),
            ),
          );
        },
      ),
    );
  }
}
