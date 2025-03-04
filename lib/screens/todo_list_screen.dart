import 'package:flutter/material.dart'; // Import Flutter material package for UI components
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package for database operations
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth package for authentication
import 'package:todoapp_improved/task.dart'; // Import the Task model

// Define a stateful widget for the TodoListScreen
class TodoListScreen extends StatefulWidget {
  final String listTitle; // Title of the todo list
  final String listId; // ID of the todo list

  // Constructor to initialize the listTitle and listId
  const TodoListScreen(
      {super.key, required this.listTitle, required this.listId});

  @override
  _TodoListScreenState createState() =>
      _TodoListScreenState(); // Create the state for this widget
}

// Define the state for the TodoListScreen
class _TodoListScreenState extends State<TodoListScreen>
    with SingleTickerProviderStateMixin {
  List<Task> tasks = []; // List to store tasks
  late AnimationController
      _controller; // Animation controller for task animations
  bool _isLoading = true; // Variable to track loading state

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300), // Duration of the animation
      vsync: this, // Provide the vsync for the animation
    );
    _loadTasksFromFirestore(); // Load tasks from Firestore when the widget is initialized
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Dispose the animation controller when the widget is disposed
    super.dispose();
  }

  // Load tasks from Firestore
  Future<void> _loadTasksFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      // Get the tasks collection for the current user and list
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      final snapshot =
          await tasksCollection.get(); // Get the tasks from Firestore
      if (mounted) {
        setState(() {
          // Update the tasks list with the data from Firestore
          tasks = snapshot.docs
              .map((doc) =>
                  Task(title: doc['title'], isCompleted: doc['isCompleted']))
              .toList();
          _isLoading = false; // Set loading state to false
          _controller.forward(from: 0.0); // Start the animation
        });
      }
    }
  }

  // Add a new task
  Future<void> _addTask(String taskTitle) async {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      await tasksCollection.doc(taskTitle).set({
        'title': taskTitle,
        'isCompleted': false,
      }); // Add the new task to Firestore
      _loadTasksFromFirestore(); // Reload tasks from Firestore to ensure state is in sync
    }
  }

  // Delete a task
  Future<void> _deleteTask(int index) async {
    if (index < 0 || index >= tasks.length) return; // Check for valid index
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      final taskTitle = tasks[index].title;
      await tasksCollection
          .doc(taskTitle)
          .delete(); // Delete the task from Firestore
      _loadTasksFromFirestore(); // Reload tasks from Firestore to ensure state is in sync
    }
  }

  // Edit a task
  Future<void> _editTask(int index, String newTitle) async {
    if (index < 0 || index >= tasks.length) return; // Check for valid index
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      final taskTitle = tasks[index].title;
      await tasksCollection
          .doc(taskTitle)
          .delete(); // Delete the old task from Firestore
      await tasksCollection.doc(newTitle).set({
        'title': newTitle,
        'isCompleted': tasks[index].isCompleted,
      }); // Add the edited task to Firestore
      _loadTasksFromFirestore(); // Reload tasks from Firestore to ensure state is in sync
    }
  }

  // Toggle the completion status of a task
  Future<void> _toggleTaskCompletion(int index) async {
    if (index < 0 || index >= tasks.length) return; // Check for valid index
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      final tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('tasks');
      final taskTitle = tasks[index].title;
      await tasksCollection.doc(taskTitle).update({
        'isCompleted': !tasks[index].isCompleted,
      }); // Toggle the completion status in Firestore
      _loadTasksFromFirestore(); // Reload tasks from Firestore to ensure state is in sync
    }
  }

  // Confirm deletion of a task
  Future<bool?> _confirmDeleteTask(int index) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF1E1E2C), // Set the background color of the dialog
          title: const Text('Delete Task',
              style: TextStyle(
                  color: Colors.white)), // Set the title of the dialog
          content: const Text('Are you sure you want to delete this task?',
              style: TextStyle(
                  color: Colors.white)), // Set the content of the dialog
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors
                          .white)), // Set the text and style for the cancel button
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Close the dialog and return false
              },
            ),
            TextButton(
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors
                          .red)), // Set the text and style for the delete button
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // Close the dialog and return true
              },
            ),
          ],
        );
      },
    );
  }

  // Show the dialog to add a new task
  void _showAddTaskDialog() {
    TextEditingController controller =
        TextEditingController(); // Create a controller for the text field
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF1E1E2C), // Set the background color of the dialog
          title: const Text('Add New Task',
              style: TextStyle(
                  color: Colors.white)), // Set the title of the dialog
          content: TextField(
            controller: controller, // Set the controller for the text field
            style: const TextStyle(color: Colors.white), // Set the text style
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
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors
                          .white)), // Set the text and style for the cancel button
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Add',
                  style: TextStyle(
                      color: Colors
                          .white)), // Set the text and style for the add button
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (controller.text.trim().isNotEmpty) {
                  _addTask(controller.text.trim()); // Add the new task
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Show the dialog to edit a task
  void _showEditTaskDialog(int index) {
    if (index < 0 || index >= tasks.length) return; // Check for valid index
    TextEditingController controller = TextEditingController(
        text: tasks[index]
            .title); // Create a controller with the current task title
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF1E1E2C), // Set the background color of the dialog
          title: const Text('Edit Task',
              style: TextStyle(
                  color: Colors.white)), // Set the title of the dialog
          content: TextField(
            controller: controller, // Set the controller for the text field
            style: const TextStyle(color: Colors.white), // Set the text style
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
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Color(
                          0xFF6C63FF))), // Set the text and style for the cancel button
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Save',
                  style: TextStyle(
                      color: Color(
                          0xFF6C63FF))), // Set the text and style for the save button
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (controller.text.trim().isNotEmpty) {
                  _editTask(index, controller.text.trim()); // Edit the task
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
    // Separate tasks into incomplete and completed tasks
    List<Task> incompleteTasks =
        tasks.where((task) => !task.isCompleted).toList();
    List<Task> completedTasks =
        tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1E1E2C), // Set the background color of the app bar
        title: Text(widget.listTitle), // Set the title of the app bar
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _loadTasksFromFirestore,
          ),
        ],
      ),
      backgroundColor:
          const Color(0xFF1E1E2C), // Set the background color of the scaffold
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loader while loading
          : tasks.isEmpty
              ? const Center(
                  child: Text(
                    'No tasks added yet', // Show message if no tasks
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
                                  key: Key(incompleteTasks[index].title),
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
                                      _showEditTaskDialog(index);
                                      return false;
                                    } else if (direction ==
                                        DismissDirection.startToEnd) {
                                      final bool? confirmed =
                                          await _confirmDeleteTask(index);
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
                                              _toggleTaskCompletion(index),
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
                                      _showEditTaskDialog(index);
                                      return false;
                                    } else if (direction ==
                                        DismissDirection.startToEnd) {
                                      final bool? confirmed =
                                          await _confirmDeleteTask(index);
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
                                              _toggleTaskCompletion(index),
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
