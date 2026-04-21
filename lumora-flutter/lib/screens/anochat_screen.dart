import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lumora_flutter/services/anochat_service.dart';
import 'package:lumora_flutter/services/auth_service.dart';

// ── colour palette (matches app theme) ────────────────────────────────────
const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);
const _kIconBg = Color(0xFFD6ECFA);

// ── category badge colours ─────────────────────────────────────────────────
const _catEmoji = <String, String>{
  'Struggling Today': '🌊',
  'Small Win': '🌱',
  'ERP Progress': '🧠',
  'Seeking Advice': '💬',
  'Motivation': '✨',
};

const _catBg = <String, Color>{
  'Struggling Today': Color(0xFFFFE0E0),
  'Small Win': Color(0xFFDFF5E8),
  'ERP Progress': Color(0xFFD6ECFA),
  'Seeking Advice': Color(0xFFFFF3CC),
  'Motivation': Color(0xFFEDE7F6),
};
const _catText = <String, Color>{
  'Struggling Today': Color(0xFF9B2B2B),
  'Small Win': Color(0xFF2D7A55),
  'ERP Progress': Color(0xFF1A3A5C),
  'Seeking Advice': Color(0xFF7A5800),
  'Motivation': Color(0xFF4527A0),
};

// ══════════════════════════════════════════════════════════════════════════
//  Main Screen
// ══════════════════════════════════════════════════════════════════════════

class AnoChatScreen extends StatefulWidget {
  const AnoChatScreen({super.key});

  @override
  State<AnoChatScreen> createState() => _AnoChatScreenState();
}

class _AnoChatScreenState extends State<AnoChatScreen> {
  final _service = AnoChatService();
  final _auth = AuthService();

  String? _selectedCategory;
  late Stream<List<AnoPost>> _postsStream;
  Map<String, String> _myReactions = {};
  // postId → {reactionType → countDelta} — cleared once Firestore stream confirms
  final Map<String, Map<String, int>> _countDeltas = {};
  StreamSubscription<Map<String, String>>? _reactionSub;

  String _myName = '...';
  bool _nameLoaded = false;
  String _currentUid = '';

  @override
  void initState() {
    super.initState();
    _postsStream = _service.postsStream();
    _reactionSub = _service.myReactionsStream().listen((map) {
      if (mounted) {
        setState(() {
          _myReactions = map;
        });
      }
    });
    _loadIdentity();
  }

  void _loadIdentity() {
    final user = _auth.currentUser;
    if (user == null) return;
    _currentUid = user.uid;

    _auth
        .getUsername(user.uid)
        .then((username) {
          if (!mounted) return;
          setState(() {
            _myName =
                username?.trim().isNotEmpty == true
                    ? username!.trim()
                    : 'Anonymous';
            _nameLoaded = true;
          });
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() {
            _myName = 'Anonymous';
            _nameLoaded = true;
          });
        });
  }

  @override
  void dispose() {
    _reactionSub?.cancel();
    super.dispose();
  }

  void _setCategory(String? cat) {
    setState(() {
      _selectedCategory = cat;
      _postsStream = _service.postsStream(category: cat);
    });
  }

  Future<void> _handleReaction(String postId, String type) async {
    final prevReaction = _myReactions[postId];
    final isSameType = prevReaction == type;

    // Compute what the count change will be
    final delta = <String, int>{};
    if (prevReaction != null) delta[prevReaction] = -1;
    if (!isSameType) delta[type] = (delta[type] ?? 0) + 1;

    final prevReactions = Map<String, String>.from(_myReactions);
    final prevDeltas = <String, Map<String, int>>{
      for (final e in _countDeltas.entries)
        e.key: Map<String, int>.from(e.value),
    };

    setState(() {
      if (isSameType) {
        _myReactions.remove(postId);
      } else {
        _myReactions[postId] = type;
      }
      final existing = Map<String, int>.from(_countDeltas[postId] ?? {});
      delta.forEach((k, v) => existing[k] = (existing[k] ?? 0) + v);
      _countDeltas[postId] = existing;
    });

    // Clear the optimistic delta after a few seconds to let the Cloud Function update the aggregate
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _countDeltas.containsKey(postId)) {
        setState(() => _countDeltas.remove(postId));
      }
    });

    try {
      await _service.toggleReaction(postId, type);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _myReactions = prevReactions;
        _countDeltas
          ..clear()
          ..addAll(prevDeltas);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not react: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _handleDelete(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Delete post?',
              style: TextStyle(fontWeight: FontWeight.w800, color: _kNavy),
            ),
            content: const Text(
              'This cannot be undone.',
              style: TextStyle(color: _kSubtitle),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await _service.deletePost(postId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _openCreateSheet() {
    if (!_nameLoaded) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(authorName: _myName, service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSheet,
        backgroundColor: _kNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Center(
                child: const Text(
                  'AnoChat',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _kNavy,
                  ),
                ),
              ),
            ),

            // ── category filter ───────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedCategory == null,
                    onTap: () => _setCategory(null),
                  ),
                  ...AnoChatService.categories.map(
                    (cat) => _FilterChip(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => _setCategory(cat),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── post feed ─────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<AnoPost>>(
                stream: _postsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _kBlue,
                        strokeWidth: 2.5,
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Something went wrong.',
                        style: const TextStyle(color: _kSubtitle),
                      ),
                    );
                  }
                  final posts = snap.data ?? [];
                  if (posts.isEmpty) {
                    return _EmptyState(
                      category: _selectedCategory,
                      onPost: _openCreateSheet,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final post = posts[i];
                      return _PostCard(
                        post: post,
                        myReaction: _myReactions[post.id],
                        countDelta: _countDeltas[post.id] ?? const {},
                        isOwn: post.uid == _currentUid,
                        onReact: (type) => _handleReaction(post.id, type),
                        onDelete: () => _handleDelete(post.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Filter Chip
// ══════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = label == 'All' ? '✦ ' : '${_catEmoji[label] ?? ''} ';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _kNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kNavy : const Color(0xFFB0C4D8),
            width: 1.2,
          ),
        ),
        child: Text(
          '$emoji$label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _kSubtitle,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Post Card
// ══════════════════════════════════════════════════════════════════════════

class _PostCard extends StatelessWidget {
  final AnoPost post;
  final String? myReaction;
  final Map<String, int> countDelta;
  final bool isOwn;
  final ValueChanged<String> onReact;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.myReaction,
    required this.countDelta,
    required this.isOwn,
    required this.onReact,
    required this.onDelete,
  });

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── author row ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle with initial
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    post.authorName.isNotEmpty
                        ? post.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kNavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                    ),
                    Text(
                      _timeAgo(post.createdAt),
                      style: const TextStyle(fontSize: 11, color: _kSubtitle),
                    ),
                  ],
                ),
              ),
              // Category badge
              _CategoryBadge(category: post.category),
              // Delete (own posts only)
              if (isOwn) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // ── content ────────────────────────────────────────────────────
          Text(
            post.content,
            style: const TextStyle(fontSize: 14, color: _kNavy, height: 1.55),
          ),

          // ── review warning ─────────────────────────────────────────────
          if (post.requiresReview) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8CC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Color(0xFF7A5800),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'This post is under review',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF7A5800),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8EEF4)),
          const SizedBox(height: 10),

          // ── reactions ──────────────────────────────────────────────────
          Row(
            children: [
              _ReactionButton(
                emoji: '❤️',
                label: 'Support',
                count: post.supportCount + (countDelta['support'] ?? 0),
                isActive: myReaction == 'support',
                onTap: () => onReact('support'),
              ),
              const SizedBox(width: 8),
              _ReactionButton(
                emoji: '🤝',
                label: 'Relate',
                count: post.relateCount + (countDelta['relate'] ?? 0),
                isActive: myReaction == 'relate',
                onTap: () => onReact('relate'),
              ),
              const SizedBox(width: 8),
              _ReactionButton(
                emoji: '🌱',
                label: 'Encourage',
                count:
                    post.encouragementCount +
                    (countDelta['encouragement'] ?? 0),
                isActive: myReaction == 'encouragement',
                onTap: () => onReact('encouragement'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Category Badge
// ══════════════════════════════════════════════════════════════════════════

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final bg = _catBg[category] ?? _kIconBg;
    final fg = _catText[category] ?? _kNavy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Reaction Button
// ══════════════════════════════════════════════════════════════════════════

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              isActive
                  ? _kBlue.withValues(alpha: 0.15)
                  : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _kBlue : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              count > 0 ? '$count' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? _kNavy : _kSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Empty State
// ══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String? category;
  final VoidCallback onPost;

  const _EmptyState({this.category, required this.onPost});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              category == null
                  ? 'No posts yet.\nBe the first to share.'
                  : 'No posts in "$category" yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: _kSubtitle,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onPost,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _kNavy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Create a post',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Create Post Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════

class _CreatePostSheet extends StatefulWidget {
  final String authorName;
  final AnoChatService service;

  const _CreatePostSheet({required this.authorName, required this.service});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _controller = TextEditingController();
  String? _selectedCategory;
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post cannot be empty.')));
      return;
    }
    setState(() => _isPosting = true);
    try {
      await widget.service.createPost(
        content: _controller.text,
        category: _selectedCategory!,
        authorName: widget.authorName,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not post: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE6F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title row
          Row(
            children: [
              const Text(
                'Share with the community',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _kNavy,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close_rounded, color: _kSubtitle),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Posting as ${widget.authorName}',
            style: const TextStyle(fontSize: 12, color: _kSubtitle),
          ),
          const SizedBox(height: 18),

          // Category label
          const Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSubtitle,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Category chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                AnoChatService.categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final bg = _catBg[cat] ?? _kIconBg;
                  final fg = _catText[cat] ?? _kNavy;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? bg : const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? fg : const Color(0xFFD6E4F0),
                          width: 1.2,
                        ),
                        boxShadow:
                            isSelected
                                ? const [
                                  BoxShadow(
                                    color: Color(0x12000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                                : const [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(Icons.check_rounded, size: 14, color: fg),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? fg : _kSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory == null
                ? 'Select a category before posting.'
                : 'Selected: $_selectedCategory',
            style: TextStyle(
              fontSize: 11.5,
              color: _selectedCategory == null ? _kSubtitle : _kNavy,
              fontWeight:
                  _selectedCategory == null ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          // Text field + char counter
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (ctx, value, _) {
              final count = value.text.length;
              final nearLimit =
                  count > (AnoChatService.postMaxLength * 0.85).round();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD6E4F0)),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 3,
                      maxLength: AnoChatService.postMaxLength,
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => null,
                      decoration: const InputDecoration(
                        hintText: 'What\'s on your mind today?',
                        hintStyle: TextStyle(
                          color: Color(0xFFAEC4D8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kNavy,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count / ${AnoChatService.postMaxLength}',
                    style: TextStyle(
                      fontSize: 11,
                      color: nearLimit ? Colors.redAccent : _kSubtitle,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Post button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final canSubmit =
                  !_isPosting &&
                  _selectedCategory != null &&
                  value.text.trim().isNotEmpty;

              return SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kNavy,
                    disabledBackgroundColor: _kNavy.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child:
                      _isPosting
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            canSubmit
                                ? 'Post Anonymously'
                                : 'Select category to continue',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
