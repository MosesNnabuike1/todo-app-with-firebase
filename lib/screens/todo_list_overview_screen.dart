import 'package:flutter/material.dart'; // Import Flutter material package for UI components
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package for database operations
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth package for authentication
import 'package:todoapp_improved/screens/todo_list_screen.dart';
import 'login_screen.dart'; // Import the LoginScreen
import 'dart:async'; // Import Dart async package for asynchronous operations

// Define a stateful widget for the TodoListOverviewScreen
class TodoListOverviewScreen extends StatefulWidget {
  const TodoListOverviewScreen({super.key});

  @override
  _TodoListOverviewScreenState createState() =>
      _TodoListOverviewScreenState(); // Create the state for this widget
}

// Define the state for the TodoListOverviewScreen
class _TodoListOverviewScreenState extends State<TodoListOverviewScreen> {
  List<Map<String, dynamic>> lists = []; // List to store todo lists
  String? username; // Variable to store the username
  bool _isLoading = true; // Variable to track loading state

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data when the widget is initialized
    _loadListsFromFirestoreWithRetry(); // Load lists from Firestore with retry mechanism
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        username = userData['username'];
      });
    }
  }

  // Load lists from Firestore with retry mechanism
  Future<void> _loadListsFromFirestoreWithRetry() async {
    const int maxRetries = 3;
    int retryCount = 0;
    bool success = false;

    while (retryCount < maxRetries && !success) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('lists')
              .get();
          setState(() {
            lists = snapshot.docs
                .map((doc) => {'id': doc.id, 'title': doc['title']})
                .toList();
            _isLoading = false;
          });
          success = true;
        }
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          setState(() {
            _isLoading = false;
          });
          // Handle error (e.g., show a message to the user)
        }
      }
    }
  }

  // Add a new list to Firestore
  Future<void> _addListToFirestore(String listTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .add({'title': listTitle});
      _loadListsFromFirestoreWithRetry();
    }
  }

  // Delete a list from Firestore method removed as it is not referenced

  // Show dialog to add a new list
  void _showAddListDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title:
              const Text('Add New List', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter list title",
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
                  _addListToFirestore(controller.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Logout the user
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Prevent the back button from taking the user back to the login page
  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:
          _onWillPop, // Prevent the back button from taking the user back to the login page
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove the back arrow
          backgroundColor: const Color(
              0xFF1E1E2C), // Set the background color of the app bar
          title: const Text('Your Todo Lists'), // Set the title of the app bar
          actions: [
            if (username != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    'Welcome, $username!', // Display the username
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(
                  Icons.logout), // Set the icon for the logout button
              onPressed:
                  _logout, // Call the logout function when the button is pressed
            ),
          ],
        ),
        backgroundColor:
            const Color(0xFF1E1E2C), // Set the background color of the scaffold
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator()) // Show loader while loading
            : lists.isEmpty
                ? const Center(
                    child: Text(
                      'No list, Create a list to get started', // Show message if no lists
                      style: TextStyle(color: Colors.white70, fontSize: 18.0),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(
                        16.0), // Set the padding for the body
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ListView.builder(
                            itemCount: lists
                                .length, // Set the number of items in the list
                            itemBuilder: (context, index) {
                              return Card(
                                color: const Color(
                                    0xFF282A3A), // Set the background color of the card
                                child: ListTile(
                                  leading: const Icon(Icons.list,
                                      color: Colors
                                          .white), // Set the icon for the list tile
                                  title: Text(
                                    lists[index][
                                        'title'], // Set the title of the list tile
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward,
                                      color: Colors
                                          .white), // Set the trailing icon for the list tile
                                  onTap: () async {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            TodoListScreen(
                                          listTitle: lists[index][
                                              'title'], // Pass the list title to the TodoListScreen
                                          listId: lists[index][
                                              'id'], // Pass the list ID to the TodoListScreen
                                        ),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          const begin = Offset(1.0, 0.0);
                                          const end = Offset.zero;
                                          const curve = Curves.ease;

                                          var tween = Tween(
                                                  begin: begin, end: end)
                                              .chain(CurveTween(curve: curve));

                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed:
              _showAddListDialog, // Show the dialog to add a new list when the button is pressed
          backgroundColor: const Color(
              0xFF6C63FF), // Set the background color of the floating action button
          child: const Icon(
              Icons.add), // Set the icon for the floating action button
        ),
      ),
    );
  }
}
