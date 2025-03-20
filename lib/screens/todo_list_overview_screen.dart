import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todoapp_improved/screens/todo_list_screen.dart';
import 'login_screen.dart';
import 'dart:async';

class TodoListOverviewScreen extends StatefulWidget {
  const TodoListOverviewScreen({super.key});

  @override
  _TodoListOverviewScreenState createState() => _TodoListOverviewScreenState();
}

class _TodoListOverviewScreenState extends State<TodoListOverviewScreen> {
  List<Map<String, dynamic>> lists = [];
  String? username;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLists();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userData.exists) {
        if (mounted) {
          setState(() {
            username = userData['username'];
          });
        }
      } else {
        print('User document does not exist');
      }
    }
  }

  Future<void> _loadLists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('lists').get();
      if (mounted) {
        setState(() {
          lists = snapshot.docs.map((doc) => {'id': doc.id, 'title': doc['title']}).toList();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addList(String listTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('lists').add({'title': listTitle});
      _loadLists();
    }
  }

  Future<void> _deleteList(String listId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('lists').doc(listId).delete();
      _loadLists();
    }
  }

  Future<bool?> _confirmDeleteList(String listId) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('Delete List', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this list?', style: TextStyle(color: Colors.white)),
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

  void _showAddListDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('Add New List', style: TextStyle(color: Colors.white)),
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
                  _addList(controller.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('Your Todo Lists'),
          actions: [
            if (username != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    'Welcome, $username!',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : lists.isEmpty
                ? const Center(
                    child: Text(
                      'No list, Create a list to get started',
                      style: TextStyle(color: Colors.white70, fontSize: 18.0),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ListView.builder(
                            itemCount: lists.length,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => TodoListScreen(
                                        listTitle: lists[index]['title'],
                                        listId: lists[index]['id'].toString(),
                                      ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.ease;

                                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                onLongPress: () async {
                                  final bool? confirmed = await _confirmDeleteList(lists[index]['id']);
                                  if (confirmed == true) {
                                    _deleteList(lists[index]['id']);
                                  }
                                },
                                child: Card(
                                  color: const Color(0xFF282A3A),
                                  child: ListTile(
                                    leading: const Icon(Icons.list, color: Colors.white),
                                    title: Text(
                                      lists[index]['title'],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward, color: Colors.white),
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
          onPressed: _showAddListDialog,
          backgroundColor: const Color(0xFF6C63FF),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
