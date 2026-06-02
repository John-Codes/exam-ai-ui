import 'package:flutter/material.dart';
import '../../slavelogic/agent_models.dart';

class SessionTile extends StatelessWidget {
  final AgentChatSession session;
  final bool active;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const SessionTile({
    super.key,
    required this.session,
    required this.active,
    required this.busy,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey(session.id),
        direction: busy ? DismissDirection.none : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Theme.of(context).colorScheme.errorContainer,
          child: const Icon(Icons.delete_outline),
        ),
        onDismissed: (_) => onDelete(),
        child: ListTile(
          leading: Icon(active ? Icons.chat_bubble : Icons.chat_bubble_outline),
          title: Text(session.title, maxLines: 1),
          subtitle: Text('Updated ${session.updatedAt.toLocal()}'),
          selected: active,
          onTap: busy ? null : onOpen,
          trailing: IconButton(
            tooltip: 'Delete conversation',
            icon: const Icon(Icons.delete_outline),
            onPressed: busy ? null : onDelete,
          ),
        ),
      );
}
