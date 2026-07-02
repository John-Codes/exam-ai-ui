import 'package:flutter/material.dart';

import '../../mainlogic/ai_agent_mainlogic.dart';
import '../../slavelogic/agent_models.dart';

class DrawerNavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final AgentView view;
  final AiAgentMainlogic logic;

  const DrawerNavigationItem({super.key, required this.icon,
    required this.label, required this.view, required this.logic});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: logic.view == view,
        onTap: () {
          Navigator.pop(context);
          logic.setView(view);
        },
      );
}
