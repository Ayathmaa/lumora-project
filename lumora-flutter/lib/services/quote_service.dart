import 'dart:convert';

import 'package:http/http.dart' as http;

class DailyQuote {
  final String text;
  final String author;

  const DailyQuote({required this.text, required this.author});
}

class QuoteService {
  // In-memory cache — same result served for the lifetime of the app session.
  // ZenQuotes /today already guarantees one quote per UTC day server-side,
  // so there is no need for persistent storage.
  static DailyQuote? _cached;
  static String? _cachedDate;

  Future<DailyQuote> fetchTodayQuote() async {
    final today = _todayKey();
    if (_cached != null && _cachedDate == today) return _cached!;

    final uri = Uri.parse('https://zenquotes.io/api/today');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Failed to load quote (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) throw Exception('Empty response from quote API');

    final map = data.first as Map<String, dynamic>;
    final quote = DailyQuote(
      text: map['q'] as String? ?? '',
      author: map['a'] as String? ?? '',
    );

    _cached = quote;
    _cachedDate = today;
    return quote;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
