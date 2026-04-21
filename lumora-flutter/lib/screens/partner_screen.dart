import 'package:flutter/material.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);
const _kBlueDark = Color(0xFF2B99D1);
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
  int _selectedRangeDays = 7;
  late final List<_EmergencyContact> _contacts = [
    const _EmergencyContact(
      name: 'Dr. Sarah Mitchell',
      role: 'Therapist',
      phone: '+1 (555) 123 456',
    ),
    const _EmergencyContact(
      name: 'James Rivera',
      role: 'Partner',
      phone: '+1 (555) 787 345',
    ),
  ];

  final Map<String, bool> _sharingPrefs = {
    'Share ERP Data': true,
    'Share Journal Summary': true,
    'Share Addiction Tracking': false,
    'Share Mood Logs': false,
  };

  final Map<int, List<double>> _trendData = const {
    7: [0.34, 0.49, 0.43, 0.67, 0.59, 0.76, 0.71],
    30: [0.28, 0.36, 0.48, 0.55, 0.67, 0.74],
  };

  final Map<int, List<String>> _trendLabels = const {
    7: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    30: ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
  };

  @override
  Widget build(BuildContext context) {
    final trendPoints = _trendData[_selectedRangeDays]!;
    final trendLabels = _trendLabels[_selectedRangeDays]!;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PartnerHeader(),
              const SizedBox(height: 28),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Overall Mood\nTrend',
                            style: TextStyle(
                              color: _kNavy,
                              fontSize: 16,
                              height: 1.55,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _RangeToggle(
                          selectedDays: _selectedRangeDays,
                          onChanged:
                              (days) =>
                                  setState(() => _selectedRangeDays = days),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _TrendChart(values: trendPoints, labels: trendLabels),
                    const SizedBox(height: 22),
                    const Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: Color(0xFFFFA449),
                            title: 'Current Streak',
                            value: '14 Days',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _MiniStatCard(
                            icon: Icons.star_border_rounded,
                            iconColor: _kBlue,
                            title: 'Your Level',
                            value: 'Level 5',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Summary',
                      style: TextStyle(
                        color: _kNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ActivityTile(
                            icon: Icons.psychology_alt_outlined,
                            value: '24',
                            label: 'ERP Sessions',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _ActivityTile(
                            icon: Icons.air_rounded,
                            value: '18',
                            label: 'Mindful Sessions',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActivityTile(
                            icon: Icons.menu_book_outlined,
                            value: '32',
                            label: 'Journal Entries',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _ActivityTile(
                            icon: Icons.shield_outlined,
                            value: '45',
                            label: 'Smoke-free Days',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
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
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress Report',
                      style: TextStyle(
                        color: _kNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Download a comprehensive summary of your mental health journey to share with your care team.',
                      style: TextStyle(
                        color: _kSubtitle,
                        fontSize: 13,
                        height: 1.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _downloadSummary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 22),
                        label: const Text(
                          'Download Progress Summary\n(PDF)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Last generated: 3 days ago',
                        style: TextStyle(
                          color: _kSubtitle,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Contacts',
                      style: TextStyle(
                        color: _kNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'People who support your journey',
                      style: TextStyle(
                        color: _kSubtitle,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._buildContactTiles(),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _showContactEditor,
                        icon: const Icon(Icons.add_rounded, color: _kBlue),
                        label: const Text(
                          'Add Contact',
                          style: TextStyle(
                            color: _kBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSharingTiles() {
    final items = [
      ('Share ERP Data', Icons.psychology_alt_outlined),
      ('Share Journal Summary', Icons.menu_book_outlined),
      ('Share Addiction Tracking', Icons.shield_outlined),
      ('Share Mood Logs', Icons.favorite_border_rounded),
    ];

    return List.generate(items.length, (index) {
      final item = items[index];
      return Column(
        children: [
          _PreferenceTile(
            icon: item.$2,
            title: item.$1,
            value: _sharingPrefs[item.$1] ?? false,
            onChanged: (value) {
              setState(() => _sharingPrefs[item.$1] = value);
            },
          ),
          if (index != items.length - 1)
            const Divider(height: 18, color: _kBorder),
        ],
      );
    });
  }

  List<Widget> _buildContactTiles() {
    return List.generate(_contacts.length, (index) {
      final contact = _contacts[index];
      return Padding(
        padding: EdgeInsets.only(
          bottom: index == _contacts.length - 1 ? 0 : 14,
        ),
        child: _ContactTile(
          contact: contact,
          onEdit: () => _showContactEditor(contact: contact, index: index),
          onDelete: () => _deleteContact(index),
        ),
      );
    });
  }

  void _downloadSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Progress summary download will be connected next.',
        ),
        backgroundColor: _kBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _deleteContact(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Delete Contact',
              style: TextStyle(color: _kNavy, fontWeight: FontWeight.w800),
            ),
            content: Text(
              'Remove ${_contacts[index].name} from emergency contacts?',
              style: const TextStyle(color: _kSubtitle, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: _kSubtitle),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _contacts.removeAt(index));
  }

  Future<void> _showContactEditor({
    _EmergencyContact? contact,
    int? index,
  }) async {
    final nameCtrl = TextEditingController(text: contact?.name ?? '');
    final roleCtrl = TextEditingController(text: contact?.role ?? '');
    final phoneCtrl = TextEditingController(text: contact?.phone ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              contact == null ? 'Add Contact' : 'Edit Contact',
              style: const TextStyle(
                color: _kNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField(
                    controller: nameCtrl,
                    label: 'Full name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogField(
                    controller: roleCtrl,
                    label: 'Role',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogField(
                    controller: phoneCtrl,
                    label: 'Phone number',
                    icon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: _kSubtitle),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty ||
                      roleCtrl.text.trim().isEmpty ||
                      phoneCtrl.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.of(dialogContext).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (saved != true || !mounted) return;

    final updatedContact = _EmergencyContact(
      name: nameCtrl.text.trim(),
      role: roleCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
    );

    setState(() {
      if (index == null) {
        _contacts.add(updatedContact);
      } else {
        _contacts[index] = updatedContact;
      }
    });
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kSubtitle),
        filled: true,
        fillColor: _kBlueSoft,
        labelStyle: const TextStyle(color: _kSubtitle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PartnerHeader extends StatelessWidget {
  const _PartnerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Care Circle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Share your progress with someone you trust',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
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

class _RangeToggle extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onChanged;

  const _RangeToggle({required this.selectedDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kIconBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RangeChip(
            label: '7\nDays',
            selected: selectedDays == 7,
            onTap: () => onChanged(7),
          ),
          _RangeChip(
            label: '30\nDays',
            selected: selectedDays == 30,
            onTap: () => onChanged(30),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : _kBlue,
            height: 1.2,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _TrendChart({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(painter: _TrendChartPainter(values)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              labels
                  .map(
                    (label) => Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _kSubtitle,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> values;

  const _TrendChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chartHeight = size.height - 8;
    final stepX = values.length == 1 ? 0.0 : size.width / (values.length - 1);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(i * stepX, chartHeight - (values[i] * chartHeight)),
    ];

    final linePath = _smoothPath(points);
    final fillPath =
        Path.from(linePath)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    final fillPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x556BAED4), Color(0x106BAED4)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint =
        Paint()
          ..color = _kBlueDark
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 3.2;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final controlX = (current.dx + next.dx) / 2;
      path.cubicTo(controlX, current.dy, controlX, next.dy, next.dx, next.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: _kBlueSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _kIconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kSubtitle,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _kNavy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ActivityTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kIconBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kNavy, size: 26),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: _kNavy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _kSubtitle,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

class _ContactTile extends StatelessWidget {
  final _EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactTile({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _kIconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.initials,
                style: const TextStyle(
                  color: _kSubtitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: _kNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kIconBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        contact.role,
                        style: const TextStyle(
                          color: _kSubtitle,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        contact.phone,
                        style: const TextStyle(
                          color: _kSubtitle,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              _ContactActionButton(icon: Icons.edit_outlined, onTap: onEdit),
              const SizedBox(height: 8),
              _ContactActionButton(
                icon: Icons.delete_outline_rounded,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ContactActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: _kIconBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _kSubtitle, size: 18),
      ),
    );
  }
}

class _EmergencyContact {
  final String name;
  final String role;
  final String phone;

  const _EmergencyContact({
    required this.name,
    required this.role,
    required this.phone,
  });

  String get initials {
    final parts =
        name
            .trim()
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .toList();
    if (parts.isEmpty) return 'CC';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}
