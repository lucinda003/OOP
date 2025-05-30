import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:bsit3bcrud/api_service.dart' as api_service;
import 'package:bsit3bcrud/user_model.dart'; // Import the User class
import 'upload_picture_screen.dart'; // Import the UploadPictureScreen

class UserScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const UserScreen({super.key, required this.onLogout});

  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  // Fetch users from API
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usersData = await api_service.ApiService.fetchUsers();
      setState(() {
        _users = usersData.map((user) => User.fromMap(user)).toList();
        _isLoading = false;
      });
    } catch (error) {
      developer.log('Error fetching users: $error', name: 'UserScreen');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle user deletion
  Future<void> _deleteUser(int userId) async {
    bool isDeleted = await api_service.ApiService.deleteUser(userId);

    if (isDeleted) {
      setState(() {
        _users.removeWhere((user) => user.id == userId);
      });
      developer.log('User deleted successfully', name: 'UserScreen');
    } else {
      developer.log('Failed to delete user', name: 'UserScreen');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _refreshUserList() {
    _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management'), centerTitle: true),
      body: SingleChildScrollView(
        // Wrap everything inside a SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome to the User Management Screen'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/createUser').then((_) {
                    _refreshUserList();
                  });
                },
                child: const Text('Add New User'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Push the UploadPictureScreen onto the stack
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadPictureScreen(),
                    ),
                  );
                },
                child: const Text("Upload a Picture"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/feed');
                },
                child: const Text('View Feed'),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    shrinkWrap:
                        true, // Important to make it scrollable inside Column
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/editUser',
                                  arguments: user,
                                ).then((_) {
                                  _refreshUserList();
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirm Deletion'),
                                      content: const Text(
                                        'Are you sure you want to delete this user?',
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            if (mounted) {
                                              await _deleteUser(user.id);
                                            }
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
