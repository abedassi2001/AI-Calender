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
  final String? userId;
  final CalendarService calendarService;

  HomePage({super.key, this.authToken, this.userId, CalendarService? calendarService})
      : calendarService = calendarService ?? CalendarService(authToken: authToken) {
    if (authToken != null) {
      this.calendarService.authToken = authToken;
    }
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController(
    text: 'Study for Algorithms exam tomorrow 3–5 PM with a 15m break',
  );
  late final CalendarService _service;

  bool _isLoading = false;
  List<GeneratedEvent> _generatedEvents = [];
  String _summary = '';

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
                  if (_generatedEvents.isNotEmpty) ...[
                    _sectionTitle('AI Generated Events'),
                    _eventsPreview(theme),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle('Today'),
                  _dayStrip(),
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
            onPressed: () async {
              // Navigate to calendar and wait for it to return
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CalendarPage(
                    userId: widget.userId,
                    authToken: widget.authToken,
                    calendarService: _service,
                  ),
                ),
              );
              // Calendar page will auto-refresh when opened
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

  Widget _eventsPreview(ThemeData theme) {
    return Column(
      children: [
        if (_summary.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF5B7CFF), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _summary,
                    style: const TextStyle(color: Color(0xFF3B4BA3), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ..._generatedEvents.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          return Card(
            margin: EdgeInsets.only(bottom: index < _generatedEvents.length - 1 ? 12 : 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EDFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.displayDate,
                          style: const TextStyle(
                            color: Color(0xFF5B7CFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Color(0xFF5B7CFF)),
                        onPressed: () => _showEditGeneratedEventDialog(context, index, event),
                        tooltip: 'Edit event',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF5B7CFF), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        event.timeRange,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.pin_drop_outlined, color: Color(0xFF5B7CFF), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onAddAllToCalendarPressed,
            icon: const Icon(Icons.add_task),
            label: Text('Add All ${_generatedEvents.length} Events to Calendar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
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
    setState(() {
      _isLoading = true;
      _generatedEvents = [];
      _summary = '';
    });
    try {
      final result = await _service.generateSchedule(prompt);
      setState(() {
        _generatedEvents = result.events;
        _summary = result.summary;
      });
      
      if (_generatedEvents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No events were generated. Try being more specific.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate schedule: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildVEventFromEvent(GeneratedEvent event) {
    // Parse time from HH:MM format
    String startTime = '120000';
    String endTime = '130000';
    
    try {
      final startParts = event.startTime.split(':');
      final endParts = event.endTime.split(':');
      
      if (startParts.length >= 2) {
        final hour = startParts[0].padLeft(2, '0');
        final minute = startParts[1].padLeft(2, '0');
        startTime = '${hour}${minute}00';
      }
      
      if (endParts.length >= 2) {
        final hour = endParts[0].padLeft(2, '0');
        final minute = endParts[1].padLeft(2, '0');
        endTime = '${hour}${minute}00';
      }
    } catch (e) {
      // Use defaults if parsing fails
    }
    
    // Parse date from YYYY-MM-DD format
    DateTime eventDate;
    try {
      eventDate = DateTime.parse(event.date);
    } catch (e) {
      eventDate = DateTime.now();
    }
    
    // Format DTSTART and DTEND: YYYYMMDDTHHMMSS
    final dtstart = '${eventDate.year.toString().padLeft(4, '0')}'
        '${eventDate.month.toString().padLeft(2, '0')}'
        '${eventDate.day.toString().padLeft(2, '0')}'
        'T$startTime';
    
    final dtend = '${eventDate.year.toString().padLeft(4, '0')}'
        '${eventDate.month.toString().padLeft(2, '0')}'
        '${eventDate.day.toString().padLeft(2, '0')}'
        'T$endTime';
    
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('SUMMARY:${event.title.replaceAll('\n', ' ')}');
    if (event.description.isNotEmpty) {
      buffer.writeln('DESCRIPTION:${event.description.replaceAll('\n', '\\n')}');
    }
    if (event.location.isNotEmpty) {
      buffer.writeln('LOCATION:${event.location.replaceAll('\n', ' ')}');
    }
    buffer.writeln('DTSTART:$dtstart');
    buffer.writeln('DTEND:$dtend');
    buffer.writeln('END:VEVENT');
    return buffer.toString();
  }

  Future<void> _onAddAllToCalendarPressed() async {
    if (_generatedEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No events to add')),
      );
      return;
    }

    final String userId = widget.userId ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adding ${_generatedEvents.length} event(s) to calendar...'),
        duration: const Duration(seconds: 2),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    for (final event in _generatedEvents) {
      try {
        final vevent = _buildVEventFromEvent(event);
        await _service.addEvent(userId, vevent);
        successCount++;
      } catch (e) {
        failCount++;
        print('Failed to add event ${event.title}: $e');
      }
    }

    if (mounted) {
      // Clear the generated events and summary after adding
      setState(() {
        _generatedEvents = [];
        _summary = '';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount > 0
                ? 'Added $successCount event(s), $failCount failed'
                : 'Successfully added all $successCount event(s) to calendar!',
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showEditGeneratedEventDialog(BuildContext context, int index, GeneratedEvent event) {
    final titleController = TextEditingController(text: event.title);
    final locationController = TextEditingController(text: event.location);
    final descriptionController = TextEditingController(text: event.description);
    
    // Parse start time
    final startTimeParts = event.startTime.split(':');
    final startHour = int.tryParse(startTimeParts[0]) ?? 12;
    final startMinute = int.tryParse(startTimeParts.length > 1 ? startTimeParts[1] : '0') ?? 0;
    TimeOfDay startTime = TimeOfDay(hour: startHour, minute: startMinute);
    
    // Parse end time
    final endTimeParts = event.endTime.split(':');
    final endHour = int.tryParse(endTimeParts[0]) ?? 13;
    final endMinute = int.tryParse(endTimeParts.length > 1 ? endTimeParts[1] : '0') ?? 0;
    TimeOfDay endTime = TimeOfDay(hour: endHour, minute: endMinute);
    
    // Parse date
    DateTime? selectedDate;
    try {
      selectedDate = DateTime.parse(event.date);
    } catch (e) {
      selectedDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setDialogState(() => startTime = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (picked != null) {
                            setDialogState(() => endTime = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text('${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text('${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }

                // Validate that end time is after start time
                final startMinutes = startTime.hour * 60 + startTime.minute;
                final endMinutes = endTime.hour * 60 + endTime.minute;
                if (endMinutes <= startMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End time must be after start time')),
                  );
                  return;
                }

                // Create updated event
                final updatedEvent = GeneratedEvent(
                  title: titleController.text.trim(),
                  date: '${selectedDate!.year.toString().padLeft(4, '0')}-'
                      '${selectedDate!.month.toString().padLeft(2, '0')}-'
                      '${selectedDate!.day.toString().padLeft(2, '0')}',
                  startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                  endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                  location: locationController.text.trim(),
                  description: descriptionController.text.trim(),
                );

                // Update the event in the list
                setState(() {
                  _generatedEvents[index] = updatedEvent;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
