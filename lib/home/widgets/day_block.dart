import 'package:npi/home/schedule_item.dart';
import 'package:flutter/material.dart';

import 'package:npi/home/home_view_model.dart';
import 'package:npi/home/widgets/schedule_card.dart';

class DayBlock extends StatelessWidget {
  final String dayCode;
  final HomeViewModel controller;
  final bool showHeaderChip;
  final bool showHorizontalDays;
  final bool isDetailView;
  final ValueChanged<String> onDaySelected;
  final ValueChanged<ScheduleItem>? onItemTap;
  final ValueChanged<ScheduleItem>? onItemDelete;

  const DayBlock({
    super.key,
    required this.dayCode,
    required this.controller,
    required this.onDaySelected,
    this.onItemTap,
    this.onItemDelete,
    this.showHeaderChip = false,
    this.showHorizontalDays = true,
    this.isDetailView = false,
  });

  String _getDayName(String code) {
    switch (code) {
      case 'L':
        return 'LUNES';
      case 'M':
        return 'MARTES';
      case 'X':
        return 'MIÉRCOLES';
      case 'J':
        return 'JUEVES';
      case 'V':
        return 'VIERNES';
      default:
        return 'DÍA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = controller.getItemsForDay(dayCode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getDayName(dayCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (showHeaderChip)
                Chip(
                  label: Text(
                    controller.isRegistered ? 'Registrado' : 'No Registrado',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No hay actividades programadas',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...items.map(
              (item) => ScheduleCard(
                item: item,
                isDetailView: isDetailView,
                onTap: onItemTap,
                onDelete: controller.isRegistered && item.isSavedEvent
                    ? onItemDelete
                    : null,
              ),
            ),
          if (showHorizontalDays) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['L', 'M', 'X', 'J', 'V'].map((day) {
                final isSelected = controller.selectedDay == day;
                return GestureDetector(
                  onTap: () => onDaySelected(day),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: isSelected
                        ? Colors.blue.shade600
                        : Colors.grey.shade200,
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
