part of 'ai_agent_mainlogic.dart';

extension AiAgentTodoLogic on AiAgentMainlogic {
  Future<void> addTodo(AgentTask task) async {
    final title = todoText.text.trim();
    if (title.isEmpty) return;
    todoText.clear();
    await runBusy(() async {
      final todo = await api.addTodo(task, title);
      _replaceTask(task.withTodos([...task.todos, todo]));
    });
  }

  Future<void> toggleTodo(AgentTask task, AgentTodo todo, bool done) async {
    await runBusy(() async {
      final updated = await api.updateTodo(task, todo, done: done);
      _replaceTask(task.withTodos([
        for (final item in task.todos) item.id == todo.id ? updated : item,
      ]));
    });
  }

  Future<void> deleteTodo(AgentTask task, AgentTodo todo) async {
    await runBusy(() async {
      await api.deleteTodo(task, todo);
      _replaceTask(task.withTodos([
        for (final item in task.todos)
          if (item.id != todo.id) item,
      ]));
    });
  }

  void _replaceTask(AgentTask task) {
    final i = tasks.indexWhere((t) => t.id == task.id);
    if (i >= 0) tasks[i] = task;
  }
}
