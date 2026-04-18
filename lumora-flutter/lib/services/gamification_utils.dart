class GamificationUtils {
  static const Map<int, String> _levelsMap = {
    0: 'Novice',
    100: 'Seeker',
    300: 'Blooming Soul',
    600: 'Warrior',
    1000: 'Guardian',
    1500: 'Champion',
    2500: 'Master',
    5000: 'Legend',
  };

  static String getLevelDisplay(int xp) {
    int level = 1;
    String title = 'Novice';
    for (final entry in _levelsMap.entries) {
      if (xp >= entry.key) {
        title = entry.value;
        level = (_levelsMap.keys.toList().indexOf(entry.key)) + 1;
      } else {
        break;
      }
    }
    return 'Level $level – $title';
  }

  static int getNextXpLimit(int xp) {
    for (final limit in _levelsMap.keys) {
      if (xp < limit) return limit;
    }
    return ((xp ~/ 2500) + 1) * 2500;
  }

  static int getCurrentLevelBase(int xp) {
    int base = 0;
    for (final limit in _levelsMap.keys) {
      if (xp >= limit) {
        base = limit;
      } else {
        break;
      }
    }
    return base;
  }

  static double getProgress(int xp) {
    final base = getCurrentLevelBase(xp);
    final limit = getNextXpLimit(xp);
    if (limit == base) return 1.0;
    return (xp - base) / (limit - base);
  }
}
