import 'package:flutter/material.dart';

import '../../services/breathing_service.dart';

const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kBg = Color(0xFFD0E4F4);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);

class BreathingHistoryScreen extends StatefulWidget {
  const BreathingHistoryScreen({super.key});

  @override
  State<BreathingHistoryScreen> createState() => _BreathingHistoryScreenState();
}

class _BreathingHistoryScreenState extends State<BreathingHistoryScreen> {
  final _service = BreathingService();
  List<BreathingSession>? _sessions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sessions = await _service.getHistory();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Breathing History',
          style: TextStyle(
            color: _kNavy,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kSubtitle, fontSize: 14),
          ),
        ),
      );
    }

    final sessions = _sessions!;

    if (sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.air_rounded, size: 56, color: _kBlue),
              SizedBox(height: 16),
              Text(
                'No sessions yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Complete a breathing exercise to see your history here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _kSubtitle, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _kBlue,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final BreathingSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isComplete = session.completed == 1;
    const statusGreen = Color(0xFF3DAA6E);
    const statusRed = Color(0xFFD94F4F);
    final statusColor = isComplete ? statusGreen : statusRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.exerciseType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  session.formattedDate,
                  style: const TextStyle(fontSize: 12, color: _kSubtitle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isComplete ? 'Complete' : 'Incomplete',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.formattedDuration,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kSubtitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
