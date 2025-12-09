import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final events = [
      ('09:00', 'Team Standup', 'Room 2B'),
      ('11:30', 'Design Sync', 'Zoom'),
      ('14:00', 'Deep Work: AI calendar', 'Library'),
      ('17:30', 'Gym + stretch', 'Fitness Center'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _monthHeader(theme),
                const SizedBox(height: 18),
                _weekStrip(),
                const SizedBox(height: 18),
                Expanded(
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView.separated(
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const Divider(height: 18),
                        itemBuilder: (_, i) {
                          final (time, title, place) = events[i];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9EDFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  time,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF3B4BA3),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.place_outlined, size: 16, color: Color(0xFF6B7280)),
                                        const SizedBox(width: 4),
                                        Text(place, style: const TextStyle(color: Color(0xFF6B7280))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
                                onPressed: () {},
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('December 2025', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Your planned events', style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280))),
          ],
        ),
        Row(
          children: [
            _circleBtn(Icons.chevron_left),
            const SizedBox(width: 10),
            _circleBtn(Icons.chevron_right),
          ],
        ),
      ],
    );
  }

  Widget _weekStrip() {
    final days = [
      ('Mon', 8),
      ('Tue', 9),
      ('Wed', 10),
      ('Thu', 11),
      ('Fri', 12),
      ('Sat', 13),
      ('Sun', 14),
    ];
    const activeIndex = 2;
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (label, day) = days[i];
          final isActive = i == activeIndex;
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
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$day',
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _circleBtn(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.12), blurRadius: 10)],
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: const Color(0xFF475569)),
      ),
    );
  }
}

