import 'package:flutter/material.dart';
import 'app.dart';
import 'data/services/calendar_service.dart';
import 'presentation/pages/calendar_page.dart';
import 'presentation/pages/login_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Calendar Assistant',
      theme: AppTheme.light(),
      home: const LoginPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final String? authToken;
  final CalendarService calendarService;

  HomePage({super.key, this.authToken, CalendarService? calendarService})
      : calendarService = calendarService ?? CalendarService(authToken: authToken);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController(
    text: 'Study for Algorithms exam tomorrow 3–5 PM with a 15m break',
  );
  late final CalendarService _service;

  bool _isLoading = false;
  String _title = 'Study Session';
  String _timeRange = 'Tomorrow · 3:00 PM – 5:00 PM';
  String _location = 'Library, 2nd Floor';
  String _note = 'Includes 15m break; remind me 20m before.';
  List<String> _timeline = const [
    '3:00 PM  Deep focus block',
    '4:00 PM  Break + review notes',
    '4:15 PM  Flashcards & practice',
    '5:00 PM  Wrap & summary',
  ];

  @override
  void initState() {
    _service = widget.calendarService;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFE0F7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(theme),
                  const SizedBox(height: 18),
                  _quickChips(),
                  const SizedBox(height: 18),
                  _promptField(theme),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onGeneratePressed,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : const Text('Generate with AI'),
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('AI Preview'),
                  _previewCard(theme),
                  const SizedBox(height: 16),
                  _sectionTitle('Today'),
                  _dayStrip(),
                  const SizedBox(height: 20),
                  _sectionTitle('Planned timeline'),
                  _timelineCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CalendarPage()),
              );
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Open Calendar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: const Icon(Icons.auto_awesome, color: Color(0xFF5B7CFF), size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your AI Scheduler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Tell me what you need and I’ll arrange it.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDCF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.flash_on, size: 16, color: Color(0xFF1D9BF0)),
              SizedBox(width: 6),
              Text('AI Ready', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickChips() {
    final suggestions = [
      'Study for math exam',
      'Plan weekly workout',
      'Team standup tomorrow',
      'Doctor visit Friday',
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: suggestions
          .map(
            (s) => ActionChip(
              label: Text(s),
              avatar: const Icon(Icons.bolt, size: 16, color: Color(0xFF5B7CFF)),
              onPressed: () => _controller.text = s,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              shadowColor: Colors.black12,
            ),
          )
          .toList(),
    );
  }

  Widget _promptField(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('What do you want to schedule?', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g. Move dentist appointment to Friday 10 AM and block 30m commute',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: const [
                _HintPill(icon: Icons.tune, text: 'Add constraints'),
                SizedBox(width: 8),
                _HintPill(icon: Icons.people_outline, text: 'Invite people'),
                SizedBox(width: 8),
                _HintPill(icon: Icons.location_on_outlined, text: 'Set location'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF5B7CFF)),
                const SizedBox(width: 8),
                Text(_timeRange),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.pin_drop_outlined, color: Color(0xFF5B7CFF)),
                const SizedBox(width: 8),
                Text(_location),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_outlined, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_note)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit details'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                        onPressed: _onAddToCalendarPressed,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Add to calendar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayStrip() {
    final days = [
      ['Mon', '9'],
      ['Tue', '10'],
      ['Wed', '11'],
      ['Thu', '12'],
      ['Fri', '13'],
      ['Sat', '14'],
      ['Sun', '15'],
    ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final isActive = i == 1; // today as sample highlight
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF5B7CFF) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 10)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(days[i][0],
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                Text(days[i][1],
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _timelineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _timeline
              .map(
                (line) => ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE9EDFF),
                    child: Icon(Icons.schedule, color: Color(0xFF5B7CFF)),
                  ),
                  title: Text(line, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.drag_indicator_rounded, color: Color(0xFFCBD5E1)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onGeneratePressed() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what you want to schedule')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.generateSchedule(prompt);
      setState(() {
        _title = result.title;
        _timeRange = result.timeRange;
        _location = result.location;
        _note = result.note;
        _timeline = result.timeline.isEmpty ? ['No steps returned'] : result.timeline;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate schedule: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildVEventFromPreview() {
    final description = '$_note\nTimeline:\n${_timeline.join('\n')}';
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('SUMMARY:${_title.replaceAll('\n', ' ')}');
    buffer.writeln('DESCRIPTION:${description.replaceAll('\n', '\\n')}');
    buffer.writeln('LOCATION:${_location.replaceAll('\n', ' ')}');
    buffer.writeln('END:VEVENT');
    return buffer.toString();
  }

  Future<void> _onAddToCalendarPressed() async {
    final vevent = _buildVEventFromPreview();
    // For now use a demo user id; replace with real user id from auth when available
    const demoUserId = 'demo-user';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending event to backend...')),
    );

    try {
      await _service.addEvent(demoUserId, vevent);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event added to calendar')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event: $e')),
      );
    }
  }
}

class _HintPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HintPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Color(0xFF4B5563))),
        ],
      ),
    );
  }
}
