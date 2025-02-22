import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoapp_improved/todo_list_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<String> _todoLists = [];
  List<String> _completedTodoLists = [];

  @override
  void initState() {
    super.initState();
    _loadTodoLists();
  }

  Future<void> _loadTodoLists() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todoLists = prefs.getStringList('todoLists') ?? [];
      _completedTodoLists = prefs.getStringList('completedTodoLists') ?? [];
    });
  }

  Future<void> _saveTodoLists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('todoLists', _todoLists);
    await prefs.setStringList('completedTodoLists', _completedTodoLists);
  }

  void _addTodoList(String listTitle) {
    setState(() {
      _todoLists.add(listTitle);
    });
    _saveTodoLists();
    _navigateToTodoListScreen(listTitle);
  }

  void _completeTodoList(int index) {
    setState(() {
      String completedTask = _todoLists.removeAt(index);
      _completedTodoLists.add(completedTask);
    });
    _saveTodoLists();
  }

  void _deleteTodoList(int index, {bool isCompleted = false}) {
    setState(() {
      if (isCompleted) {
        _completedTodoLists.removeAt(index);
      } else {
        _todoLists.removeAt(index);
      }
    });
    _saveTodoLists();
  }

  void _navigateToTodoListScreen(String listTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodoListScreen(listTitle: listTitle, listId: ''),
      ),
    );
  }

  void _showAddListDialog() {
    String newListTitle = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Create New List',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2D2D44),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter list title',
              hintStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6C63FF)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              newListTitle = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                if (newListTitle.isNotEmpty) {
                  Navigator.of(context).pop();
                  _addTodoList(newListTitle);
                }
              },
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('ToDo App'),
        backgroundColor: const Color(0xFF2D2D44),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextButton.icon(
              onPressed: _showAddListDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add New List',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _todoLists.isEmpty && _completedTodoLists.isEmpty
                  ? const Center(
                      child: Text(
                        'No ToDo on the list yet',
                        style: TextStyle(color: Colors.white70, fontSize: 18.0),
                      ),
                    )
                  : ListView(
                      children: [
                        if (_todoLists.isNotEmpty) ...[
                          const Text(
                            'Active ToDos:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._todoLists.asMap().entries.map(
                            (entry) {
                              int index = entry.key;
                              String title = entry.value;
                              return Card(
                                color: const Color(0xFF2D2D44),
                                margin: const EdgeInsets.symmetric(vertical: 5.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: ListTile(
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  onTap: () {
                                    _navigateToTodoListScreen(title);
                                  },
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                                        onPressed: () {
                                          _completeTodoList(index);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () {
                                          _deleteTodoList(index);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        if (_completedTodoLists.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Completed ToDos:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._completedTodoLists.asMap().entries.map(
                            (entry) {
                              int index = entry.key;
                              String title = entry.value;
                              return Card(
                                color: const Color(0xFF1E1E2C),
                                margin: const EdgeInsets.symmetric(vertical: 5.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  side: const BorderSide(
                                    color: Colors.greenAccent,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 16,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () {
                                      _deleteTodoList(index, isCompleted: true);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
