import 'package:flutter/material.dart';
import '../services/partner_service.dart';
import '../widgets/mood_overview_chart.dart';
import '../widgets/journey_calendar.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);
const _kBlueSoft = Color(0xFFD6ECFA);
const _kIconBg = Color(0xFFD6ECFA);
const _kBorder = Color(0xFFE0EAF4);
const _kShadow = Color(0x10000000);
const _kMuted = Color(0xFFC8CED8);

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final _partnerService = PartnerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: StreamBuilder<PartnerUser?>(
          stream: _partnerService.streamMyPartner(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _kBlue),
              );
            }
            final partner = snapshot.data;
            if (partner == null) {
              return _buildNoPartnerView(context);
            }
            return _buildDashboardView(context, partner);
          },
        ),
      ),
    );
  }

  Widget _buildNoPartnerView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PartnerHeader(
            onSearchTap: () => _showSearchDialog(context),
            onInvitesTap: (invites) => _showInvitesDialog(context, invites),
            partnerService: _partnerService,
          ),
          const SizedBox(height: 48),
          const Icon(Icons.people_outline_rounded, size: 80, color: _kBlue),
          const SizedBox(height: 24),
          const Text(
            'You haven\'t linked a partner yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kNavy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Invite a trusted friend or care provider to share your progress and build better habits together.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kSubtitle, fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => _showSearchDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text(
              'Find a Partner',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 32),
          StreamBuilder<List<PartnerInvite>>(
            stream: _partnerService.streamPendingInvites(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _kBlue),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error loading invites: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              final invites = snapshot.data ?? [];
              if (invites.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Invitations',
                    style: TextStyle(
                      color: _kNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...invites.map((invite) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: _kShadow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: _kIconBg,
                            radius: 22,
                            child: Icon(Icons.person, color: _kNavy),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "@${invite.sender?.username ?? 'unknown'}",
                              style: const TextStyle(
                                color: _kSubtitle,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.redAccent,
                            ),
                            onPressed:
                                () => _partnerService.declineInvite(invite.id),
                            tooltip: 'Decline',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 28,
                            ),
                            onPressed:
                                () => _partnerService.acceptInvite(invite.id),
                            tooltip: 'Accept',
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context, PartnerUser partner) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PartnerHeader(
            onSearchTap: () {}, // Not needed here because they have a partner
            onInvitesTap: (invites) => _showInvitesDialog(context, invites),
            partnerService: _partnerService,
          ),
          const SizedBox(height: 28),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sharing Preferences',
                  style: TextStyle(
                    color: _kNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Control what your trusted person can see',
                  style: TextStyle(
                    color: _kSubtitle,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                ..._buildSharingTiles(),
              ],
            ),
          ),
          const SizedBox(height: 22),

          StreamBuilder<PartnerPreferences>(
            stream: _partnerService.streamPartnerPreferences(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: _kBlue),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final partnerPrefs = snapshot.data!;
              final hasSharedProgress =
                  partnerPrefs.shareAnxietyRemaining ||
                  partnerPrefs.shareDailyMood ||
                  partnerPrefs.shareJourneyCalendar;

              return _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${partner.displayName}\'s Shared Progress',
                      style: const TextStyle(
                        color: _kNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasSharedProgress
                          ? 'Visible because @${partner.username} enabled these sharing preferences.'
                          : '@${partner.username} has not shared any progress details with you yet.',
                      style: const TextStyle(
                        color: _kSubtitle,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    if (hasSharedProgress) ...[
                      const SizedBox(height: 20),
                      if (partnerPrefs.shareAnxietyRemaining ||
                          partnerPrefs.shareDailyMood)
                        MoodOverviewWidget(
                          userId: partner.uid,
                          showAnxiety: partnerPrefs.shareAnxietyRemaining,
                          showMood: partnerPrefs.shareDailyMood,
                        ),
                      if (partnerPrefs.shareJourneyCalendar)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: JourneyCalendarWidget(userId: partner.uid),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSharingTiles() {
    return [
      StreamBuilder<PartnerPreferences>(
        stream: _partnerService.streamMyPreferences(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final prefs = snapshot.data!;
          return Column(
            children: [
              _PreferenceTile(
                icon: Icons.auto_graph_rounded,
                title: 'Anxiety Remaining Graph',
                value: prefs.shareAnxietyRemaining,
                onChanged: (val) {
                  _partnerService.updatePreferences(
                    PartnerPreferences(
                      shareAnxietyRemaining: val,
                      shareDailyMood: prefs.shareDailyMood,
                      shareJourneyCalendar: prefs.shareJourneyCalendar,
                    ),
                  );
                },
              ),
              const Divider(height: 18, color: _kBorder),
              _PreferenceTile(
                icon: Icons.mood_rounded,
                title: 'Daily Mood Graph',
                value: prefs.shareDailyMood,
                onChanged: (val) {
                  _partnerService.updatePreferences(
                    PartnerPreferences(
                      shareAnxietyRemaining: prefs.shareAnxietyRemaining,
                      shareDailyMood: val,
                      shareJourneyCalendar: prefs.shareJourneyCalendar,
                    ),
                  );
                },
              ),
              const Divider(height: 18, color: _kBorder),
              _PreferenceTile(
                icon: Icons.calendar_month_rounded,
                title: 'Journey Calendar',
                value: prefs.shareJourneyCalendar,
                onChanged: (val) {
                  _partnerService.updatePreferences(
                    PartnerPreferences(
                      shareAnxietyRemaining: prefs.shareAnxietyRemaining,
                      shareDailyMood: prefs.shareDailyMood,
                      shareJourneyCalendar: val,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    ];
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        List<PartnerUser>? searchResults;
        bool isSearching = false;
        int currentSearchIdTracker = 0;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SizedBox(
                height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Search Partner",
                      style: TextStyle(
                        color: _kNavy,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Enter exact username...",
                        filled: true,
                        fillColor: _kBlueSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search, color: _kSubtitle),
                      ),
                      onChanged: (val) async {
                        if (val.isEmpty) {
                          setModalState(() {
                            searchResults = null;
                            isSearching = false;
                          });
                          return;
                        }
                        setModalState(() {
                          isSearching = true;
                          searchResults = null;
                        });

                        final currentSearchId = ++currentSearchIdTracker;
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (currentSearchIdTracker != currentSearchId) return;

                        try {
                          final results = await _partnerService.searchUsers(
                            val,
                          );
                          if (currentSearchIdTracker == currentSearchId) {
                            setModalState(() {
                              isSearching = false;
                              searchResults = results;
                            });
                          }
                        } catch (e) {
                          if (currentSearchIdTracker == currentSearchId) {
                            setModalState(() {
                              isSearching = false;
                            });
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    if (isSearching)
                      const Center(
                        child: CircularProgressIndicator(color: _kBlue),
                      )
                    else if (searchResults != null)
                      Expanded(
                        child:
                            searchResults!.isEmpty
                                ? const Center(
                                  child: Text(
                                    "No users found.",
                                    style: TextStyle(
                                      color: _kSubtitle,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: searchResults!.length,
                                  itemBuilder: (c, i) {
                                    final user = searchResults![i];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: _kBorder),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            backgroundColor: _kIconBg,
                                            radius: 22,
                                            child: Icon(
                                              Icons.person,
                                              color: _kNavy,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              "@${user.username}",
                                              style: const TextStyle(
                                                color: _kSubtitle,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              _partnerService.sendInvite(
                                                user.uid,
                                              );
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Invite sent!"),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _kBlue,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              "Invite",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInvitesDialog(BuildContext context, List<PartnerInvite> invites) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Pending Invites"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: invites.length,
                itemBuilder: (c, i) {
                  final invite = invites[i];
                  return ListTile(
                    title: Text(invite.sender?.displayName ?? "Unknown"),
                    subtitle: Text("@${invite.sender?.username ?? 'unknown'}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            _partnerService.declineInvite(invite.id);
                            Navigator.pop(ctx);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            _partnerService.acceptInvite(invite.id);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
    );
  }

}

class _PartnerHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  final ValueChanged<List<PartnerInvite>> onInvitesTap;
  final PartnerService partnerService;

  const _PartnerHeader({
    required this.onSearchTap,
    required this.onInvitesTap,
    required this.partnerService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PartnerUser?>(
      stream: partnerService.streamMyPartner(),
      builder: (context, partnerSnapshot) {
        final partner = partnerSnapshot.data;
        return StreamBuilder<List<PartnerInvite>>(
          stream: partnerService.streamPendingInvites(),
          builder: (context, invitesSnapshot) {
            final invites = invitesSnapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: _kBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      partner != null
                          ? Icons.people_alt_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              partner != null
                                  ? 'Care Circle (${partner.displayName})'
                                  : 'Care Circle',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          partner != null
                              ? 'Sharing active. @${partner.username}'
                              : 'Share your progress with someone you trust',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (invites.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.amberAccent,
                            ),
                            onPressed: () => onInvitesTap(invites),
                            tooltip: 'Pending Invites',
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${invites.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (partner != null)
                    IconButton(
                      icon: const Icon(
                        Icons.person_remove_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => _confirmRemovePartner(context, partner),
                      tooltip: 'Remove Partner',
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRemovePartner(BuildContext context, PartnerUser partner) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove Partner?'),
            content: Text(
              'Are you sure you want to stop sharing your progress with ${partner.displayName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  partnerService.removePartner();
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: _kIconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kSubtitle, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _kNavy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: _kBlue,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: _kMuted,
        ),
      ],
    );
  }
}
