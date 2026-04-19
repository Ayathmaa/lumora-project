import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum InsightType { improvement, warning, info }

class Insight {
  final String text;
  final InsightType type;

  const Insight({required this.text, required this.type});

  Color get color {
    switch (type) {
      case InsightType.improvement:
        return const Color(0xFF2E7D52); // Green
      case InsightType.warning:
        return const Color(0xFFB02020); // Red
      case InsightType.info:
        return const Color(0xFF1A3A5C); // Navy
    }
  }

  Color get bgColor {
    switch (type) {
      case InsightType.improvement:
        return const Color(0xFFD6F0E0);
      case InsightType.warning:
        return const Color(0xFFFFE4E4);
      case InsightType.info:
        return const Color(0xFFE0EAF4);
    }
  }

  IconData get icon {
    switch (type) {
      case InsightType.improvement:
        return Icons
            .trending_up; // Or trending_down depending on context but arrow_upward is good for generic improvement
      case InsightType.warning:
        return Icons.warning_amber_rounded;
      case InsightType.info:
        return Icons.info_outline_rounded;
    }
  }
}

class InsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Insight>> getInsights() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final insights = <Insight>[];

    // Fetch the two most recent daily analytics
    final analyticsDocs =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('daily_analytics')
            .orderBy('timestamp', descending: true)
            .limit(2)
            .get();

    if (analyticsDocs.docs.length >= 2) {
      final todayData = analyticsDocs.docs[0].data();
      final yesterdayData = analyticsDocs.docs[1].data();

      // Evaluate Anxiety Trends
      final num? todayAnxiety = todayData['anxietyRemainingPercent'] as num?;
      final num? yesterdayAnxiety =
          yesterdayData['anxietyRemainingPercent'] as num?;

      if (todayAnxiety != null &&
          yesterdayAnxiety != null &&
          yesterdayAnxiety > 0) {
        if (todayAnxiety < yesterdayAnxiety) {
          final double diff =
              yesterdayAnxiety.toDouble() - todayAnxiety.toDouble();
          final double percentChange = (diff / yesterdayAnxiety) * 100;
          if (percentChange >= 1.0) {
            insights.add(
              Insight(
                text:
                    'Your anxiety decreased by ${percentChange.round()}% today',
                type: InsightType.improvement,
              ),
            );
          }
        } else if (todayAnxiety > yesterdayAnxiety) {
          final double diff =
              todayAnxiety.toDouble() - yesterdayAnxiety.toDouble();
          final double percentChange = (diff / yesterdayAnxiety) * 100;
          if (percentChange >= 5.0) {
            insights.add(
              Insight(
                text:
                    'Your anxiety increased by ${percentChange.round()}% today',
                type: InsightType.warning,
              ),
            );
          }
        }
      }

      // Evaluate Mood Trends
      final num? todayMood = todayData['moodScore'] as num?;
      final num? yesterdayMood = yesterdayData['moodScore'] as num?;

      if (todayMood != null && yesterdayMood != null) {
        if (todayMood > yesterdayMood) {
          insights.add(
            const Insight(
              text: 'Your mood is improving today',
              type: InsightType.improvement,
            ),
          );
        } else if (todayMood < yesterdayMood) {
          insights.add(
            const Insight(
              text: 'Your mood is lower today',
              type: InsightType.warning,
            ),
          );
        }
      }
    }

    // Evaluate "High stress detected on evenings" via recent cbt_journal
    // To do this sustainably, we just fetch a small number of recent journals.
    final journalDocs =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('cbt_journal')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

    int eveningJournals = 0;
    int eveningHighStress = 0;

    for (var doc in journalDocs.docs) {
      final data = doc.data();
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) continue;

      final date = ts.toDate();
      final hour = date.hour;

      // Evening considered 17:00 to 23:59
      if (hour >= 17 || hour <= 3) {
        eveningJournals++;
        final preAnxiety = data['preAnxietyLevel'] as int? ?? 0;
        final postAnxiety = data['postAnxietyLevel'] as int? ?? 0;
        // Using average of pre and post to define high stress
        if (preAnxiety >= 7 || postAnxiety >= 6) {
          eveningHighStress++;
        }
      }
    }

    if (eveningJournals >= 3 && (eveningHighStress / eveningJournals) >= 0.5) {
      insights.add(
        const Insight(
          text: 'High stress detected on evenings',
          type: InsightType.warning,
        ),
      );
    }

    // If no insights at all (e.g. brand new user), we can return an info or return empty
    if (insights.isEmpty) {
      insights.add(
        const Insight(
          text: 'Keep logging journals to see your insights',
          type: InsightType.info,
        ),
      );
    }

    return insights;
  }
}
