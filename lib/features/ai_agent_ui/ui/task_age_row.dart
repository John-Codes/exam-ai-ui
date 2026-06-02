import 'package:flutter/material.dart';
import '../slavelogic/agent_models.dart';

class TaskAgeRow extends StatelessWidget {
  final AgentTask task;
  const TaskAgeRow({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final created = _ageLabel('Created', task.createdAt);
    final inList = _ageLabel(
      'In list',
      task.listEnteredAt ?? task.createdAt ?? task.updatedAt,
      suffixForPast: false,
    );
    if (created == null && inList == null) return const SizedBox.shrink();

    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      children: [
        if (created != null) Text(created, style: style),
        if (inList != null) Text(inList, style: style),
      ],
    );
  }
}

String? _ageLabel(
  String prefix,
  DateTime? value, {
  bool suffixForPast = true,
}) {
  if (value == null) return null;
  final days = _wholeDaysSince(value);
  if (days <= 0) return '$prefix today';
  final unit = days == 1 ? 'day' : 'days';
  if (suffixForPast) return '$prefix $days $unit ago';
  return '$prefix $days $unit';
}

int _wholeDaysSince(DateTime value) {
  final now = DateTime.now();
  final start = DateTime(
      value.toLocal().year, value.toLocal().month, value.toLocal().day);
  final today = DateTime(now.year, now.month, now.day);
  return today.difference(start).inDays;
}
