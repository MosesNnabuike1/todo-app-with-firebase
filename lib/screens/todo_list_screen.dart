import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todoapp_improved/task.dart';

class TodoListScreen extends StatefulWidget {
  final String listTitle;
  final String listId;

  const TodoListScreen(
      {super.key, required this.listTitle, required this.listId});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen>
    with SingleTickerProviderStateMixin {
  List<Task> tasks = [];
  late AnimationController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadTasks();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      final snapshot = await tasksCollection.get();
      if (mounted) {
        setState(() {
          tasks = snapshot.docs
              .map((doc) => Task(
                    id: doc.id, // Assign the Firestore document ID
                    title: doc['title'],
                    isCompleted: doc['isCompleted'],
                  ))
              .toList();
          _isLoading = false;
          _controller.forward(from: 0.0);
        });
      }
    }
  }

  Future<void> _addTask(String taskTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      final newTaskDoc = tasksCollection.doc(); // Generate unique ID
      await newTaskDoc.set({
        'id': newTaskDoc.id, // Store the generated ID in the document
        'title': taskTitle,
        'isCompleted': false,
      });
      _loadTasks();
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      await tasksCollection.doc(taskId).delete(); // Delete by unique task ID
      _loadTasks(); // Reload the tasks to reflect the change
    }
  }

  Future<void> _editTask(String taskId, String newTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');

      // Update the task title directly using its unique taskId
      await tasksCollection.doc(taskId).update({
        'title': newTitle,
      });

      // Update the local state for the task
      final taskIndex = tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        setState(() {
          tasks[taskIndex].title = newTitle;
        });
      }
    }
  }

  Future<void> _toggleTaskCompletion(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      final taskIndex =
          tasks.indexWhere((task) => task.id == taskId); // Find index by ID
      if (taskIndex == -1) return; // Task not found

      await tasksCollection.doc(taskId).update({
        'isCompleted':
            !tasks[taskIndex].isCompleted, // Toggle status in Firestore
      });

      setState(() {
        tasks[taskIndex].isCompleted =
            !tasks[taskIndex].isCompleted; // Update local state
      });
    }
  }

  Future<bool?> _confirmDeleteTask(String taskId) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text(
            'Delete Task',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title:
              const Text('Add New Task', style: TextStyle(color: Colors.white)),
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
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
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

  void _showEditTaskDialog(String taskId) {
    final taskIndex =
        tasks.indexWhere((task) => task.id == taskId); // Find index by ID
    if (taskIndex == -1) return; // If task is not found, exit early

    TextEditingController controller =
        TextEditingController(text: tasks[taskIndex].title);

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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF6C63FF)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (controller.text.trim().isNotEmpty) {
                  _editTask(taskId, controller.text.trim());
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
    List<Task> incompleteTasks =
        tasks.where((task) => !task.isCompleted).toList();
    List<Task> completedTasks =
        tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(widget.listTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _loadTasks,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E1E2C),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(
                  child: Text(
                    'No tasks added yet',
                    style: TextStyle(color: Colors.white70, fontSize: 18.0),
                  ),
                )
              : Padding(
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
                                  key: Key(incompleteTasks[index]
                                      .id), // Use taskId as the key
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  secondaryBackground: Container(
                                    color: Colors.blue,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: const Icon(Icons.edit,
                                        color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.endToStart) {
                                      _showEditTaskDialog(incompleteTasks[index]
                                          .id); // Use taskId
                                      return false;
                                    } else if (direction ==
                                        DismissDirection.startToEnd) {
                                      final bool? confirmed =
                                          await _confirmDeleteTask(
                                              incompleteTasks[index]
                                                  .id); // Use taskId
                                      if (confirmed == true) {
                                        _deleteTask(incompleteTasks[index]
                                            .id); // Use taskId
                                      }
                                      return confirmed;
                                    }
                                    return false;
                                  },
                                  child: Card(
                                    color: const Color(0xFF282A3A),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 2.0),
                                      leading: Transform.scale(
                                        scale: 0.8,
                                        child: IconButton(
                                          icon: Icon(
                                            incompleteTasks[index].isCompleted
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: incompleteTasks[index]
                                                    .isCompleted
                                                ? Colors.green
                                                : Colors.white,
                                          ),
                                          onPressed: () =>
                                              _toggleTaskCompletion(
                                                  incompleteTasks[index]
                                                      .id), // Use taskId
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
                                  key: Key(completedTasks[index]
                                      .id), // Use taskId as the key
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  secondaryBackground: Container(
                                    color: Colors.blue,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: const Icon(Icons.edit,
                                        color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.endToStart) {
                                      _showEditTaskDialog(completedTasks[index]
                                          .id); // Pass taskId
                                      return false;
                                    } else if (direction ==
                                        DismissDirection.startToEnd) {
                                      final bool? confirmed =
                                          await _confirmDeleteTask(
                                              completedTasks[index]
                                                  .id); // Pass taskId
                                      if (confirmed == true) {
                                        _deleteTask(completedTasks[index]
                                            .id); // Pass taskId
                                      }
                                      return confirmed;
                                    }
                                    return false;
                                  },
                                  child: Card(
                                    color: const Color(0xFF282A3A),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 2.0),
                                      leading: Transform.scale(
                                        scale: 0.8,
                                        child: IconButton(
                                          icon: Icon(
                                            completedTasks[index].isCompleted
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: completedTasks[index]
                                                    .isCompleted
                                                ? Colors.green
                                                : Colors.white,
                                          ),
                                          onPressed: () =>
                                              _toggleTaskCompletion(
                                                  completedTasks[index]
                                                      .id), // Pass taskId
                                        ),
                                      ),
                                      title: Text(
                                        completedTasks[index].title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          decoration:
                                              TextDecoration.lineThrough,
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
