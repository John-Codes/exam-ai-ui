import 'package:flutter/material.dart';

class DeleteChatButton extends StatelessWidget {
  final String title;
  final bool disabled;
  final Future<void> Function() deleteChat;

  const DeleteChatButton({super.key, required this.title,
    required this.disabled, required this.deleteChat});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Delete conversation',
        icon: const Icon(Icons.delete_outline),
        onPressed: disabled ? null : () => _confirm(context),
      );

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text('Delete "$title" and all of its messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await deleteChat();
  }
}
