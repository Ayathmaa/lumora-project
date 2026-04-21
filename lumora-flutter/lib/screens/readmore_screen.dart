import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);
const _kIconBg = Color(0xFFD6ECFA);
const _kHighlight = Color(0xFFD6ECFA);

const List<_ReadMoreTopic> _topics = [
  _ReadMoreTopic(
    id: 'cbt',
    title: 'Understanding CBT',
    markdownTitle: 'CBT',
    icon: Icons.psychology_outlined,
  ),
  _ReadMoreTopic(
    id: 'ocd',
    title: 'Understanding OCD',
    markdownTitle: 'OCD',
    icon: Icons.show_chart_rounded,
  ),
  _ReadMoreTopic(
    id: 'depression',
    title: 'About Depression',
    markdownTitle: 'Depression',
    icon: Icons.cloud_queue_rounded,
  ),
  _ReadMoreTopic(
    id: 'anxiety',
    title: 'Anxiety & Stress',
    markdownTitle: 'Anxiety',
    icon: Icons.favorite_border_rounded,
  ),
];

class ReadMoreScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ReadMoreScreen({super.key, this.onBack});

  @override
  State<ReadMoreScreen> createState() => _ReadMoreScreenState();
}

class _ReadMoreScreenState extends State<ReadMoreScreen> {
  final List<String> _expandedItems = [];
  late final Future<Map<String, List<_ContentBlock>>> _topicContentFuture;

  @override
  void initState() {
    super.initState();
    _topicContentFuture = _loadTopicContent();
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedItems.contains(id)) {
        _expandedItems.remove(id);
      } else {
        _expandedItems.add(id);
      }
    });
  }

  Future<Map<String, List<_ContentBlock>>> _loadTopicContent() async {
    final markdown = await rootBundle.loadString('readmorecontent.md');
    final sections = _splitTopicSections(markdown);

    return {
      for (final topic in _topics)
        topic.id: _parseTopicBlocks(sections[topic.markdownTitle] ?? ''),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap:
                          widget.onBack ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
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
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'ReadMore',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Learn more about your journey',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'How Lumora Works 💙',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your guide to healing, growth & understanding',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _kHighlight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lumora helps you track your mood,\npractice mindful exercises, and build\nhealthy habits.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E63B3),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSparklePoint('Use CBT-based tools'),
                          const SizedBox(height: 8),
                          _buildSparklePoint('Do ERP exercises'),
                          const SizedBox(height: 8),
                          _buildSparklePoint('Grow step by step'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FutureBuilder<Map<String, List<_ContentBlock>>>(
                future: _topicContentFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: _kBlue),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildTopicsError();
                  }

                  final topicContent =
                      snapshot.data ?? const <String, List<_ContentBlock>>{};

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explore Topics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kNavy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var index = 0; index < _topics.length; index++) ...[
                        if (index > 0) const SizedBox(height: 12),
                        _buildAccordion(
                          id: _topics[index].id,
                          icon: _topics[index].icon,
                          title: _topics[index].title,
                          isExpanded: _expandedItems.contains(
                            _topics[index].id,
                          ),
                          onToggle: () => _toggleExpand(_topics[index].id),
                          child: _buildTopicContent(
                            topicContent[_topics[index].id] ?? const [],
                          ),
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSparklePoint(String text) {
    return Row(
      children: [
        const Text('✨', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E63B3),
          ),
        ),
      ],
    );
  }

  Widget _buildDotPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 4, color: _kSubtitle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kSubtitle,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicsError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'ReadMore topics could not be loaded.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _kSubtitle,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTopicContent(List<_ContentBlock> blocks) {
    if (blocks.isEmpty) {
      return const Text(
        'No content available for this topic yet.',
        style: TextStyle(fontSize: 13, color: _kSubtitle, height: 1.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildTopicChildren(blocks),
    );
  }

  List<Widget> _buildTopicChildren(List<_ContentBlock> blocks) {
    final children = <Widget>[];

    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      children.add(SizedBox(height: _spacingForBlock(block.type, index == 0)));
      children.add(_buildBlock(block));
    }

    children.add(const SizedBox(height: 4));
    return children;
  }

  double _spacingForBlock(_ContentBlockType type, bool isFirst) {
    return switch (type) {
      _ContentBlockType.heading => isFirst ? 0 : 16,
      _ContentBlockType.subheading => 12,
      _ContentBlockType.paragraph => 8,
      _ContentBlockType.bullet => 6,
    };
  }

  Widget _buildBlock(_ContentBlock block) {
    return switch (block.type) {
      _ContentBlockType.heading => Text(
        block.text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: _kNavy,
        ),
      ),
      _ContentBlockType.subheading => Text(
        block.text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _kNavy,
        ),
      ),
      _ContentBlockType.paragraph => Text(
        block.text,
        style: const TextStyle(fontSize: 13, color: _kSubtitle, height: 1.5),
      ),
      _ContentBlockType.bullet => _buildDotPoint(block.text),
    };
  }

  Map<String, String> _splitTopicSections(String markdown) {
    final sections = <String, StringBuffer>{};
    String? currentTopic;

    for (final line in const LineSplitter().convert(markdown)) {
      final trimmed = line.trimRight();

      if (trimmed.startsWith('## ')) {
        currentTopic = trimmed.substring(3).trim();
        sections[currentTopic] = StringBuffer();
        continue;
      }

      if (currentTopic == null || trimmed == '---') {
        continue;
      }

      sections[currentTopic]!.writeln(line);
    }

    return {
      for (final entry in sections.entries)
        entry.key: entry.value.toString().trim(),
    };
  }

  List<_ContentBlock> _parseTopicBlocks(String section) {
    if (section.trim().isEmpty) {
      return const [];
    }

    final blocks = <_ContentBlock>[];
    final paragraphBuffer = <String>[];
    final bulletBuffer = <String>[];

    void flushParagraph() {
      if (paragraphBuffer.isEmpty) {
        return;
      }

      blocks.add(
        _ContentBlock.paragraph(
          _cleanInlineMarkdown(paragraphBuffer.join(' ').trim()),
        ),
      );
      paragraphBuffer.clear();
    }

    void flushBullets() {
      if (bulletBuffer.isEmpty) {
        return;
      }

      for (final bullet in bulletBuffer) {
        blocks.add(_ContentBlock.bullet(_cleanInlineMarkdown(bullet)));
      }
      bulletBuffer.clear();
    }

    for (final rawLine in const LineSplitter().convert(section)) {
      final line = rawLine.trim();

      if (line.isEmpty || line == '---') {
        flushParagraph();
        flushBullets();
        continue;
      }

      if (line.startsWith('### ')) {
        flushParagraph();
        flushBullets();
        blocks.add(
          _ContentBlock.heading(_cleanInlineMarkdown(line.substring(4).trim())),
        );
        continue;
      }

      if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        flushParagraph();
        flushBullets();
        blocks.add(
          _ContentBlock.subheading(
            _cleanInlineMarkdown(line.substring(2, line.length - 2).trim()),
          ),
        );
        continue;
      }

      if (line.startsWith('- ')) {
        flushParagraph();
        bulletBuffer.add(line.substring(2).trim());
        continue;
      }

      flushBullets();
      paragraphBuffer.add(line);
    }

    flushParagraph();
    flushBullets();

    return blocks;
  }

  String _cleanInlineMarkdown(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAllMapped(
          RegExp(r'\[(.*?)\]\((.*?)\)'),
          (match) => match.group(1) ?? '',
        )
        .trim();
  }

  Widget _buildAccordion({
    required String id,
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kIconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _kSubtitle, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _kBlue,
                  size: 24,
                ),
              ],
            ),
            if (isExpanded) ...[const SizedBox(height: 20), child],
          ],
        ),
      ),
    );
  }
}

class _ReadMoreTopic {
  final String id;
  final String title;
  final String markdownTitle;
  final IconData icon;

  const _ReadMoreTopic({
    required this.id,
    required this.title,
    required this.markdownTitle,
    required this.icon,
  });
}

enum _ContentBlockType { heading, subheading, paragraph, bullet }

class _ContentBlock {
  final _ContentBlockType type;
  final String text;

  const _ContentBlock._({required this.type, required this.text});

  const _ContentBlock.heading(String text)
    : this._(type: _ContentBlockType.heading, text: text);

  const _ContentBlock.subheading(String text)
    : this._(type: _ContentBlockType.subheading, text: text);

  const _ContentBlock.paragraph(String text)
    : this._(type: _ContentBlockType.paragraph, text: text);

  const _ContentBlock.bullet(String text)
    : this._(type: _ContentBlockType.bullet, text: text);
}
