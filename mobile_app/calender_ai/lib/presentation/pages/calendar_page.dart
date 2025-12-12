import 'package:flutter/material.dart';
import '../../data/services/calendar_service.dart';

class CalendarPage extends StatefulWidget {
  final String? userId;
  final String? authToken;
  final CalendarService? calendarService;

  const CalendarPage({
    super.key,
    this.userId,
    this.authToken,
    this.calendarService,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late CalendarService _service;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _selectedDay; // null means show all events

  @override
  void initState() {
    super.initState();
    _service = widget.calendarService ?? CalendarService(authToken: widget.authToken);
    if (widget.authToken != null) {
      _service.authToken = widget.authToken;
    }
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'No user logged in';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await _service.getUserEvents(widget.userId!);
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh events',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9FF), Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _monthHeader(theme, isTablet),
                SizedBox(height: isTablet ? 24 : 18),
                _weekStrip(isTablet),
                SizedBox(height: isTablet ? 24 : 18),
                if (_selectedDay != null) ...[
                  _selectedDayHeader(theme, isTablet),
                  SizedBox(height: isTablet ? 16 : 12),
                ],
                Expanded(
                  child: _buildEventsList(theme, isTablet, isDesktop),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(ThemeData theme, bool isTablet, bool isDesktop) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final parsedEvents = _parseEvents(_events);
    
    // Filter events by selected day if a day is selected
    final filteredEvents = _selectedDay == null
        ? parsedEvents
        : parsedEvents.where((event) {
            final eventDate = event['date'];
            if (eventDate == null) return false;
            try {
              // Parse the date string (format: YYYY-MM-DD)
              final eventDateTime = DateTime.parse(eventDate);
              // Normalize both dates to midnight for accurate comparison
              final eventDateNormalized = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
              final selectedDateNormalized = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
              
              // Compare normalized dates
              return eventDateNormalized == selectedDateNormalized;
            } catch (e) {
              // If parsing fails, don't include the event
              return false;
            }
          }).toList();

    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _selectedDay == null ? 'No events yet' : 'No events on this day',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDay == null
                  ? 'Add events from the home page'
                  : 'Try selecting another day or add new events',
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (_selectedDay != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() => _selectedDay = null),
                icon: const Icon(Icons.clear),
                label: const Text('Show all events'),
              ),
            ],
          ],
        ),
      );
    }

    if (isDesktop) {
      // Desktop: 2-column grid
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) => _buildEventCard(theme, filteredEvents[index], isTablet),
      );
    }

    // Mobile/Tablet: Single column list
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: ListView.separated(
          itemCount: filteredEvents.length,
          separatorBuilder: (_, __) => SizedBox(height: isTablet ? 20 : 18),
          itemBuilder: (_, i) => _buildEventItem(theme, filteredEvents[i], isTablet),
        ),
      ),
    );
  }

  Widget _selectedDayHeader(ThemeData theme, bool isTablet) {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final dayName = dayNames[_selectedDay!.weekday - 1];
    final monthName = monthNames[_selectedDay!.month - 1];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 14 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5B7CFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5B7CFF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: const Color(0xFF5B7CFF), size: isTablet ? 24 : 20),
          SizedBox(width: isTablet ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Showing events for $dayName',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5B7CFF),
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                Text(
                  '${monthName} ${_selectedDay!.day}, ${_selectedDay!.year}',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Color(0xFF6B7280)),
            onPressed: () => setState(() => _selectedDay = null),
            tooltip: 'Show all events',
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(ThemeData theme, Map<String, String> event, bool isTablet) {
    // Find the event index
    final eventIndex = _events.indexWhere((e) {
      final parsed = _parseVEvent(e['vevent'] as String? ?? '');
      return parsed['title'] == event['title'] && parsed['time'] == event['time'];
    });
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event['time'] ?? 'TBD',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF3B4BA3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(context, event, eventIndex >= 0 ? eventIndex : 0);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, eventIndex >= 0 ? eventIndex : 0);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event['title'] ?? 'Untitled Event',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (event['location'] != null && event['location']!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event['location']!,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(ThemeData theme, Map<String, String> event, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14 : 10,
            vertical: isTablet ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            event['time'] ?? 'TBD',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF3B4BA3),
              fontWeight: FontWeight.w700,
              fontSize: isTablet ? 14 : 12,
            ),
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title'] ?? 'Untitled Event',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
              if (event['location'] != null && event['location']!.isNotEmpty) ...[
                SizedBox(height: isTablet ? 6 : 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event['location']!,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
          onSelected: (value) {
            // Find the event index by matching title and time
            final eventIndex = _events.indexWhere((e) {
              final parsed = _parseVEvent(e['vevent'] as String? ?? '');
              return parsed['title'] == event['title'] && parsed['time'] == event['time'];
            });
            if (value == 'edit') {
              _showEditDialog(context, event, eventIndex >= 0 ? eventIndex : 0);
            } else if (value == 'delete') {
              _showDeleteDialog(context, eventIndex >= 0 ? eventIndex : 0);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ],
    );
  }

  List<Map<String, String>> _parseEvents(List<Map<String, dynamic>> events) {
    return events.map((eventData) {
      final vevent = eventData['vevent'] as String? ?? '';
      return _parseVEvent(vevent);
    }).toList();
  }

  Map<String, String> _parseVEvent(String vevent) {
    // Simple VEVENT parser - extracts SUMMARY, DESCRIPTION, LOCATION, DTSTART
    String title = 'Untitled Event';
    String time = 'TBD';
    String location = '';
    String description = '';
    String? dateString;

    final lines = vevent.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('SUMMARY:')) {
        title = trimmedLine.substring(8).trim();
      } else if (trimmedLine.startsWith('DESCRIPTION:')) {
        description = trimmedLine.substring(12).trim().replaceAll('\\n', '\n');
      } else if (trimmedLine.startsWith('LOCATION:')) {
        location = trimmedLine.substring(9).trim();
      } else if (trimmedLine.startsWith('DTSTART:')) {
        // Parse DTSTART if available
        final dtstart = trimmedLine.substring(8).trim();
        if (dtstart.length >= 8) {
          // Format: YYYYMMDDTHHMMSS or YYYYMMDD
          try {
            final year = dtstart.substring(0, 4);
            final month = dtstart.substring(4, 6);
            final day = dtstart.substring(6, 8);
            
            // Validate date components
            final yearInt = int.tryParse(year);
            final monthInt = int.tryParse(month);
            final dayInt = int.tryParse(day);
            
            if (yearInt != null && monthInt != null && dayInt != null &&
                monthInt >= 1 && monthInt <= 12 && dayInt >= 1 && dayInt <= 31) {
              dateString = '$year-$month-$day';
              
              if (dtstart.length > 9 && dtstart[8] == 'T') {
                // Has time component
                final hour = dtstart.length > 10 ? dtstart.substring(9, 11) : '00';
                final minute = dtstart.length > 12 ? dtstart.substring(11, 13) : '00';
                time = '$hour:$minute';
              }
            }
          } catch (e) {
            // Ignore parsing errors
          }
        }
      }
    }

    final result = <String, String>{
      'title': title,
      'time': time,
      'location': location,
      'description': description,
    };
    
    if (dateString != null) {
      result['date'] = dateString;
    }
    
    return result;
  }

  Widget _monthHeader(ThemeData theme, bool isTablet) {
    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${monthNames[now.month - 1]} ${now.year}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: isTablet ? 28 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your planned events',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _circleBtn(Icons.chevron_left, isTablet),
            SizedBox(width: isTablet ? 12 : 10),
            _circleBtn(Icons.chevron_right, isTablet),
          ],
        ),
      ],
    );
  }

  Widget _weekStrip(bool isTablet) {
    final now = DateTime.now();
    final weekDays = <(String, int, DateTime)>[];
    
    // Get current week
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      weekDays.add((dayNames[day.weekday - 1], day.day, day));
    }

    // Check if selected day is in current week
    final selectedIndex = _selectedDay == null
        ? null
        : weekDays.indexWhere((d) =>
            d.$3.year == _selectedDay!.year &&
            d.$3.month == _selectedDay!.month &&
            d.$3.day == _selectedDay!.day);

    // Highlight today if no day is selected, otherwise highlight selected day
    final today = now.day;
    final todayIndex = weekDays.indexWhere((d) => d.$2 == today);
    final activeIndex = selectedIndex ?? todayIndex;

    return SizedBox(
      height: isTablet ? 90 : 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        separatorBuilder: (_, __) => SizedBox(width: isTablet ? 12 : 10),
        itemBuilder: (_, i) {
          final (label, day, dateTime) = weekDays[i];
          final isActive = i == activeIndex;
          final isSelected = i == selectedIndex;
          
          // Count events for this day
          final dayEventCount = _getEventCountForDay(dateTime);
          
          return GestureDetector(
            onTap: () {
              setState(() {
                // Toggle: if clicking the same day, deselect it
                if (_selectedDay != null &&
                    _selectedDay!.year == dateTime.year &&
                    _selectedDay!.month == dateTime.month &&
                    _selectedDay!.day == dateTime.day) {
                  _selectedDay = null;
                } else {
                  _selectedDay = dateTime;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 14 : 12,
              ),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF5B7CFF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isSelected && !isActive
                    ? Border.all(color: const Color(0xFF5B7CFF), width: 2)
                    : null,
                boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 10)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isActive ? Colors.white : const Color(0xFF0F172A),
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (dayEventCount > 0 && !isActive)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF5B7CFF),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$dayEventCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getEventCountForDay(DateTime day) {
    final parsedEvents = _parseEvents(_events);
    final dayNormalized = DateTime(day.year, day.month, day.day);
    
    return parsedEvents.where((event) {
      final eventDate = event['date'];
      if (eventDate == null) return false;
      try {
        final eventDateTime = DateTime.parse(eventDate);
        final eventDateNormalized = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
        return eventDateNormalized == dayNormalized;
      } catch (e) {
        return false;
      }
    }).length;
  }

  Widget _circleBtn(IconData icon, bool isTablet) {
    return Container(
      width: isTablet ? 48 : 40,
      height: isTablet ? 48 : 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.12), blurRadius: 10)],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {},
        icon: Icon(icon, color: const Color(0xFF475569), size: isTablet ? 24 : 20),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, String> event, int eventIndex) {
    final titleController = TextEditingController(text: event['title'] ?? '');
    final locationController = TextEditingController(text: event['location'] ?? '');
    final descriptionController = TextEditingController(text: event['description'] ?? '');
    
    // Parse time
    final timeStr = event['time'] ?? '12:00';
    final timeParts = timeStr.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 12;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
    TimeOfDay selectedTime = TimeOfDay(hour: hour, minute: minute);
    
    // Parse date
    DateTime? selectedDate;
    if (event['date'] != null) {
      try {
        selectedDate = DateTime.parse(event['date']!);
      } catch (e) {
        selectedDate = DateTime.now();
      }
    } else {
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
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setDialogState(() => selectedTime = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
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
                    ),
                  ],
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
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }

                // Build VEVENT string
                final dateStr = '${selectedDate!.year.toString().padLeft(4, '0')}'
                    '${selectedDate!.month.toString().padLeft(2, '0')}'
                    '${selectedDate!.day.toString().padLeft(2, '0')}';
                final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}'
                    '${selectedTime.minute.toString().padLeft(2, '0')}00';
                final dtstart = '${dateStr}T$timeStr';
                
                // Calculate end time (default 1 hour duration)
                final endHour = (selectedTime.hour + 1) % 24;
                final endTimeStr = '${endHour.toString().padLeft(2, '0')}'
                    '${selectedTime.minute.toString().padLeft(2, '0')}00';
                final dtend = '${dateStr}T$endTimeStr';

                final vevent = '''BEGIN:VEVENT
SUMMARY:${titleController.text.trim().replaceAll('\n', ' ')}
DESCRIPTION:${descriptionController.text.trim().replaceAll('\n', '\\n')}
LOCATION:${locationController.text.trim().replaceAll('\n', ' ')}
DTSTART:$dtstart
DTEND:$dtend
END:VEVENT''';

                try {
                  await _service.updateEvent(widget.userId!, eventIndex, vevent);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadEvents();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update event: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int eventIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.deleteEvent(widget.userId!, eventIndex);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadEvents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete event: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
