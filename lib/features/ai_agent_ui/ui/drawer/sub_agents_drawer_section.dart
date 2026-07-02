import 'package:flutter/material.dart';

import '../../mainlogic/ai_agent_mainlogic.dart';

/// Stub UI only. Sub-agent chat/history APIs are disabled until Hermes sub-agents ship.
class SubAgentsDrawerSection extends StatelessWidget {
  final AiAgentMainlogic logic;
  const SubAgentsDrawerSection({super.key, required this.logic});

  @override
  Widget build(BuildContext context) => ExpansionTile(
        leading: const Icon(Icons.smart_toy_outlined),
        title: const Text('Sub Agents'),
        subtitle: const Text('Coming soon'),
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Sub agents are work in progress'),
            subtitle: Text('Use Master Agent chat for now.'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: const Text('See all active sub agents'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sub agents coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('See full sub agent history'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sub agent history coming soon')),
              );
            },
          ),
        ],
      );
}
