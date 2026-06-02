import 'package:flutter/material.dart';

void showAddSheet(
  BuildContext context,
  String label,
  TextEditingController controller,
  Future<void> Function() onSave,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _QuickAddSheet(
      label: label,
      controller: controller,
      onSave: onSave,
    ),
  );
}

class _QuickAddSheet extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Future<void> Function() onSave;

  const _QuickAddSheet({
    required this.label,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New $label',
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _save(context),
              ),
            ),
            IconButton(
              tooltip: 'Create',
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _save(context),
            ),
          ],
        ),
      );

  Future<void> _save(BuildContext context) async {
    Navigator.pop(context);
    await onSave();
  }
}
