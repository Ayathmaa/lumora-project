import 'package:flutter/material.dart';
import 'package:lumora_flutter/widgets/lumora_nav_bar.dart';

const _kBg      = Color(0xFFC8DCF0);
const _kNavy    = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg  = Colors.white;
const _kIconBg  = Color(0xFFD6ECFA);
const _kBlue    = Color(0xFF6BAED4);
const _kFieldFill = Color(0xFFEEF5FB);
const _kBorder  = Color(0xFFB8D8EC);

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  int _navIndex = 1;

  final List<_JournalEntry> _entries = [
    _JournalEntry(
      date: 'Mon, Mar 3',
      title: 'A calmer morning',
      preview: 'Woke up feeling lighter today. The breathing exercise really helped...',
    ),
    _JournalEntry(
      date: 'Sun, Mar 2',
      title: 'Challenging afternoon',
      preview: 'Had some intrusive thoughts but managed to redirect them using...',
    ),
    _JournalEntry(
      date: 'Sat, Mar 1',
      title: 'Gratitude list',
      preview: 'Three things I am grateful for today: sunshine, my coffee and...',
    ),
  ];

  void _newEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewEntrySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _kNavy, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Journal',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _kNavy)),
                      Text('Your private space to reflect',
                          style: TextStyle(fontSize: 12, color: _kSubtitle)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: _kBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                      onPressed: _newEntry,
                      tooltip: 'New Entry',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Entry list ────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _EntryCard(entry: _entries[i]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LumoraNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ── Entry card ────────────────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final _JournalEntry entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(entry.date,
                    style: const TextStyle(
                        fontSize: 11, color: _kBlue, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: _kSubtitle),
            ],
          ),
          const SizedBox(height: 10),
          Text(entry.title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kNavy)),
          const SizedBox(height: 6),
          Text(entry.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: _kSubtitle, height: 1.4)),
        ],
      ),
    );
  }
}

// ── New entry bottom sheet ────────────────────────────────────────────────
class _NewEntrySheet extends StatefulWidget {
  const _NewEntrySheet();

  @override
  State<_NewEntrySheet> createState() => _NewEntrySheetState();
}

class _NewEntrySheetState extends State<_NewEntrySheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('New Entry',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: _kNavy)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: _kNavy, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: const TextStyle(color: _kBorder),
                filled: true,
                fillColor: _kFieldFill,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBlue, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              maxLines: 5,
              style: const TextStyle(color: _kNavy),
              decoration: InputDecoration(
                hintText: 'Write your thoughts here...',
                hintStyle: const TextStyle(color: _kBorder),
                filled: true,
                fillColor: _kFieldFill,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBlue, width: 1.5)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Entry',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalEntry {
  final String date;
  final String title;
  final String preview;
  const _JournalEntry(
      {required this.date, required this.title, required this.preview});
}
