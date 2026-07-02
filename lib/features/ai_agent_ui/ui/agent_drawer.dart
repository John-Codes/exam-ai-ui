import 'package:flutter/material.dart';
import 'package:aone_ui/core/config/app_config.dart';

import '../mainlogic/ai_agent_mainlogic.dart';
import '../slavelogic/agent_models.dart';
import 'drawer/drawer_navigation_item.dart';
import 'drawer/master_agent_drawer_section.dart';
import 'drawer/sub_agents_drawer_section.dart';

class AgentDrawer extends StatelessWidget {
  final AiAgentMainlogic logic;
  const AgentDrawer({super.key, required this.logic});

  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const ListTile(
                leading: Icon(Icons.hub_outlined),
                title: Text('AI Agent UI'),
                subtitle: Text('Mobile project workspace'),
              ),
              const Divider(),
              DrawerNavigationItem(
                icon: Icons.view_kanban_outlined,
                label: 'Projects',
                view: AgentView.projects,
                logic: logic,
              ),
              MasterAgentDrawerSection(logic: logic),
              if (AppConfig.showSubAgentUi)
                SubAgentsDrawerSection(logic: logic),
            ],
          ),
        ),
      );
}
