import 'package:crud_local_database_app/models/todolist.dart';
import 'package:crud_local_database_app/models/todolist_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodolistPage extends StatefulWidget {
  const TodolistPage({super.key});

  @override
  State<TodolistPage> createState() => _TodolistPageState();
}

class _TodolistPageState extends State<TodolistPage> {
  final TextEditingController _titleController = TextEditingController();

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime> onDateSelected,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  @override
  void initState() {
    super.initState();
    readTodolists();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // read todolists
  void readTodolists() {
    context.read<TodolistDatabase>().fetchTodolists();
  }

  Future<void> _showTodolistDialog({Todolist? todolist}) async {
    _titleController.text = todolist?.title ?? '';
    DateTime selectedDate = todolist?.deadline ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(todolist == null ? 'Create Todo' : 'Update Todo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(
                        dialogContext,
                        initialDate: selectedDate,
                        onDateSelected: (pickedDate) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        },
                      ),
                      icon: const Icon(Icons.date_range),
                      label: Text('Date: ${_formatDate(selectedDate)}'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) {
                    return;
                  }

                  final database = context.read<TodolistDatabase>();

                  if (todolist == null) {
                    await database.addTodolist(title, selectedDate);
                  } else {
                    await database.updateTodolist(
                      todolist.id,
                      title,
                      selectedDate,
                      todolist.isDone,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(todolist == null ? 'Create' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(Todolist todolist) async {
    await context.read<TodolistDatabase>().updateTodolist(
      todolist.id,
      todolist.title,
      todolist.deadline,
      !todolist.isDone,
    );
  }

  // delete a todolist
  void deleteTodolist(int id) {
    context.read<TodolistDatabase>().deleteTodolist(id);
  }

  @override
  Widget build(BuildContext context) {
    final todolistDatabase = context.watch<TodolistDatabase>();
    final currentTodolists = todolistDatabase.currentTodolists;

    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTodolistDialog(),
        child: const Icon(Icons.add),
      ),
      body: currentTodolists.isEmpty
          ? const Center(child: Text('No todos yet. Tap + to add one.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: currentTodolists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final todolist = currentTodolists[index];
                final titleStyle = TextStyle(
                  decoration: todolist.isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: todolist.isDone
                      ? Theme.of(context).colorScheme.outline
                      : null,
                );

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(todolist.title, style: titleStyle),
                    subtitle: Text(
                      'Due: ${_formatDate(todolist.deadline)} • ${todolist.isDone ? 'Done' : 'Pending'}',
                    ),
                    leading: Icon(
                      todolist.isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: todolist.isDone ? Colors.green : null,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: todolist.isDone
                              ? 'Mark as pending'
                              : 'Mark as done',
                          onPressed: () => _toggleStatus(todolist),
                          icon: Icon(
                            todolist.isDone ? Icons.undo : Icons.check,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () =>
                              _showTodolistDialog(todolist: todolist),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => deleteTodolist(todolist.id),
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
