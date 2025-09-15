import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isOrganizer;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isOrganizer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isOrganizer ? _buildOrganizerItems(context) : _buildAttendeeItems(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAttendeeItems(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {'icon': Icons.search_outlined, 'activeIcon': Icons.search, 'label': 'Search'},
      {'icon': Icons.add_circle_outline, 'activeIcon': Icons.add_circle, 'label': 'Add'},
      {'icon': Icons.confirmation_number_outlined, 'activeIcon': Icons.confirmation_number, 'label': 'Tickets'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isActive = currentIndex == index;

      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                color: isActive 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildOrganizerItems(BuildContext context) {
    final items = [
      {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.event_note_outlined, 'activeIcon': Icons.event_note, 'label': 'Events'},
      {'icon': Icons.add_circle_outline, 'activeIcon': Icons.add_circle, 'label': 'Create'},
      {'icon': Icons.qr_code_scanner_outlined, 'activeIcon': Icons.qr_code_scanner, 'label': 'Scanner'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isActive = currentIndex == index;

      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Special styling for the notification badge on scanner
              Stack(
                children: [
                  Icon(
                    isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                    color: isActive 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
                  if (index == 3) // Scanner index
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}