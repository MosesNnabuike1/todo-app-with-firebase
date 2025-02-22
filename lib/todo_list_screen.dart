import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task.dart';

class TodoListScreen extends StatefulWidget {
  final String listTitle;
  final String listId;

  const TodoListScreen({super.key, required this.listTitle, required this.listId});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> with SingleTickerProviderStateMixin {
  List<Task> tasks = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadTasksFromFirestore();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveTasksToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      for (var task in tasks) {
        await tasksCollection.doc(task.title).set({
          'title': task.title,
          'isCompleted': task.isCompleted,
        });
      }
    }
  }

  Future<void> _loadTasksFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      final snapshot = await tasksCollection.get();
      setState(() {
        tasks = snapshot.docs.map((doc) => Task(title: doc['title'], isCompleted: doc['isCompleted'])).toList();
        _controller.forward(from: 0.0);
      });
    }
  }

  void _addTask(String taskTitle) {
    setState(() {
      tasks.add(Task(title: taskTitle));
      _saveTasksToFirestore();
    });
    _controller.forward(from: 0.0);
  }

  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
      _saveTasksToFirestore();
    });
  }

  void _editTask(int index) {
    TextEditingController controller = TextEditingController(text: tasks[index].title);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('Edit Task', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter task",
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C63FF))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save', style: TextStyle(color: Color(0xFF6C63FF))),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  tasks[index].title = controller.text;
                  _saveTasksToFirestore();
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      tasks[index].isCompleted = !tasks[index].isCompleted;
      _saveTasksToFirestore();
    });
  }

  Future<bool?> _confirmDeleteTask(int index) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this task?', style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  _showAddTaskDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('Add New Task', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter task",
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                if (controller.text.trim().isNotEmpty) {
                  _addTask(controller.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Task> incompleteTasks = tasks.where((task) => !task.isCompleted).toList();
    List<Task> completedTasks = tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(widget.listTitle),
      ),
      backgroundColor: const Color(0xFF1E1E2C),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            if (incompleteTasks.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: incompleteTasks.length,
                  itemBuilder: (context, index) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeInOut,
                      ),
                      child: Dismissible(
                        key: Key(incompleteTasks[index].title),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.blue,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            _editTask(index);
                            return false;
                          } else if (direction == DismissDirection.startToEnd) {
                            final bool? confirmed = await _confirmDeleteTask(index);
                            if (confirmed == true) {
                              _deleteTask(index);
                            }
                            return confirmed;
                          }
                          return false;
                        },
                        child: Card(
                          color: const Color(0xFF282A3A),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                            leading: Transform.scale(
                              scale: 0.8,
                              child: IconButton(
                                icon: Icon(
                                  incompleteTasks[index].isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: incompleteTasks[index].isCompleted
                                      ? Colors.green
                                      : Colors.white,
                                ),
                                onPressed: () => _toggleTaskCompletion(index),
                              ),
                            ),
                            title: Text(
                              incompleteTasks[index].title,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Completed Tasks (${completedTasks.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (completedTasks.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: completedTasks.length,
                  itemBuilder: (context, index) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeInOut,
                      ),
                      child: Dismissible(
                        key: Key(completedTasks[index].title),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.blue,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            _editTask(index);
                            return false;
                          } else if (direction == DismissDirection.startToEnd) {
                            final bool? confirmed = await _confirmDeleteTask(index);
                            if (confirmed == true) {
                              _deleteTask(index);
                            }
                            return confirmed;
                          }
                          return false;
                        },
                        child: Card(
                          color: const Color(0xFF282A3A),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                            leading: Transform.scale(
                              scale: 0.8,
                              child: IconButton(
                                icon: Icon(
                                  completedTasks[index].isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: completedTasks[index].isCompleted
                                      ? Colors.green
                                      : Colors.white,
                                ),
                                onPressed: () => _toggleTaskCompletion(index),
                              ),
                            ),
                            title: Text(
                              completedTasks[index].title,
                              style: const TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add),
      ),
    );
  }
}
