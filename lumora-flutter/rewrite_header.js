const fs = require('fs');
let content = fs.readFileSync('lib/screens/progress_screen.dart', 'utf8');

const newHeader = `
  Widget _buildHeader() {
    return StreamBuilder<GamificationStats>(
      stream: GamificationService().getStatsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const GamificationStats();
        final levelDisplay = GamificationUtils.getLevelDisplay(stats.xp);
        final progress = GamificationUtils.getProgress(stats.xp);
        final nextLimit = GamificationUtils.getNextXpLimit(stats.xp);

        return GestureDetector(
          onTap: () => _showLevelJourneyModal(context, stats.xp),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: _kBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'My Journey',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  levelDisplay,
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '\${stats.xp} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Next: $nextLimit XP (Tap here)',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
`;

const startIndex = content.indexOf('  Widget _buildHeader() {');
const endIndex = content.indexOf('  }\n\n  Widget _buildStreaksGrid() {', startIndex);
if (startIndex !== -1 && endIndex !== -1) {
  // It's the end of the state class, so _buildHeader is actually the last method in _ProgressScreenState?
  // Wait, no. Let's see what's after _buildHeader.
}
