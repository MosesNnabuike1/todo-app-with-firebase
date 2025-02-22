import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todoapp_improved/todo_list_screen.dart'; // Corrected import path
import 'login_screen.dart';

class TodoListOverviewScreen extends StatefulWidget {
  const TodoListOverviewScreen({super.key});

  @override
  _TodoListOverviewScreenState createState() => _TodoListOverviewScreenState();
}

class _TodoListOverviewScreenState extends State<TodoListOverviewScreen> {
  List<Map<String, dynamic>> lists = [];
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadListsFromFirestore();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc.data()?['username'];
          print('Username fetched: $username'); // Debugging statement
        });
      } else {
        print('User document does not exist'); // Debugging statement
      }
    } else {
      print('No user is currently signed in'); // Debugging statement
    }
  }

  Future<void> _loadListsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final listsCollection = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('lists');
      final snapshot = await listsCollection.get();
      setState(() {
        lists = snapshot.docs.map((doc) => {'id': doc.id, 'title': doc['title']}).toList();
      });
    }
  }

  void _addList(String listTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final listsCollection = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('lists');
      final newList = await listsCollection.add({'title': listTitle});
      setState(() {
        lists.add({'id': newList.id, 'title': listTitle});
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color(0xFF282A3A),
                    child: ListTile(
                      leading: const Icon(Icons.list, color: Colors.white),
                      title: Text(
                        lists[index]['title'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(Icons.arrow_forward, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => TodoListScreen(
                              listTitle: lists[index]['title'],
                              listId: lists[index]['id'],
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
    );
  }
}
