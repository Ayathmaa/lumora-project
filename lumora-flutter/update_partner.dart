import 'dart:io';

void main() {
  final file = File('lib/screens/partner_screen.dart');
  var content = file.readAsStringSync();

  // Add the import
  content = content.replaceFirst("import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport '../services/partner_service.dart';");

  // Add partner service variable
  content = content.replaceFirst("class _PartnerScreenState extends State<PartnerScreen> {",
    "class _PartnerScreenState extends State<PartnerScreen> {\n  final _partnerService = PartnerService();\n  PartnerPreferences _prefs = PartnerPreferences();\n  PartnerUser? _partnerUser;");

  // In build(), wrap the whole body in a StreamBuilder or add the Actions 
  // Let's add actions manually. Replace Scaffold(
  content = content.replaceFirst(
    "appBar: AppBar(",
"""appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _showSearchDialog(context),
          ),
          StreamBuilder<List<PartnerInvite>>(
            stream: _partnerService.streamPendingInvites(),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => _showInvitesDialog(context, snap.data!),
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('\$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],"""
  );

  // Replace the _buildSharingTiles to use PartnerService
  content = content.replaceFirst(
    "List<Widget> _buildSharingTiles() {",
"""List<Widget> _buildSharingTiles() {
    return [
      StreamBuilder<PartnerPreferences>(
        stream: _partnerService.streamMyPreferences(),
        builder: (context, snapshot) {
          final prefs = snapshot.data ?? PartnerPreferences();
          return Column(
            children: [
              _PreferenceTile(
                icon: Icons.psychology_alt_outlined,
                title: 'Share ERP Data',
                value: prefs.shareErpProgress,
                onChanged: (val) {
                  _partnerService.updatePreferences(PartnerPreferences(
                    shareErpProgress: val,
                    shareJournal: prefs.shareJournal,
                    shareHabits: prefs.shareHabits,
                  ));
                },
              ),
              const Divider(height: 18, color: _kBorder),
              _PreferenceTile(
                icon: Icons.menu_book_outlined,
                title: 'Share Journal Summary',
                value: prefs.shareJournal,
                onChanged: (val) {
                  _partnerService.updatePreferences(PartnerPreferences(
                    shareErpProgress: prefs.shareErpProgress,
                    shareJournal: val,
                    shareHabits: prefs.shareHabits,
                  ));
                },
              ),
              const Divider(height: 18, color: _kBorder),
              _PreferenceTile(
                icon: Icons.shield_outlined,
                title: 'Share Habit Streaks',
                value: prefs.shareHabits,
                onChanged: (val) {
                  _partnerService.updatePreferences(PartnerPreferences(
                    shareErpProgress: prefs.shareErpProgress,
                    shareJournal: prefs.shareJournal,
                    shareHabits: val,
                  ));
                },
              ),
            ],
          );
        },
      )
    ];"""
  );

  // Note: we can delete the old loop inside _buildSharingTiles
  content = content.replaceAll(RegExp(r"final items = \[(?:.|\n)*?\}\);(?=\n  \})", multiLine: true), "");

  // Add the search and invites dialogs at the end of _PartnerScreenState
  content = content.replaceFirst(
    "  Widget _buildDialogField({",
"""
  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SizedBox(
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Search Partner", style: TextStyle(color: _kNavy, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Enter exact username",
                    filled: true,
                    fillColor: _kBlueSoft,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (val) async {
                    if (val.isEmpty) return;
                    try {
                      final results = await _partnerService.searchUsers(val);
                      if (!ctx.mounted) return;
                      showDialog(context: ctx, builder: (dctx) => AlertDialog(
                        title: const Text("Results"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: results.length,
                            itemBuilder: (c, i) => ListTile(
                              title: Text(results[i].displayName),
                              subtitle: Text("@\${results[i].username}"),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  _partnerService.sendInvite(results[i].uid);
                                  Navigator.pop(dctx);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invite sent!")));
                                },
                                child: const Text("Invite"),
                              ),
                            ),
                          ),
                        ),
                      ));
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showInvitesDialog(BuildContext context, List<PartnerInvite> invites) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                subtitle: Text("@\${invite.sender?.username ?? 'unknown'}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {
                      _partnerService.declineInvite(invite.id);
                      Navigator.pop(ctx);
                    }),
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () {
                      _partnerService.acceptInvite(invite.id);
                      Navigator.pop(ctx);
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      )
    );
  }

  Widget _buildDialogField({"""
  );

  file.writeAsStringSync(content);
}
