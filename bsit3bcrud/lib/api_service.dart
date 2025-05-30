import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define the User class
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}

class ApiService {
  static const String apiUrl =
      'http://localhost:3000'; // Updated to use localhost
  static var logger = Logger();

  static Future<bool> createUser(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/users'),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log(
        'API Response: ${response.statusCode} - ${response.body}',
        name: 'ApiService',
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      developer.log('Error creating user: $e', name: 'ApiService', error: e);
      return false;
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      logger.d('Attempting login to: $apiUrl/login');
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      logger.d('Login Response Status: ${response.statusCode}');
      logger.d('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('auth_token', token);
          return {'success': true, 'message': 'Login successful'};
        } else {
          return {
            'success': false,
            'message': 'Token not found in response',
            'details': response.body,
          };
        }
      } else {
        String errorMessage = 'Login failed';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }

        developer.log('Login failed: $errorMessage', name: 'ApiService');
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
          'details': response.body,
        };
      }
    } catch (e) {
      String errorMessage = 'Network error occurred';
      if (e is SocketException) {
        errorMessage =
            'Cannot connect to server. Please check if the server is running at $apiUrl';
      }

      developer.log('Login error: $errorMessage', name: 'ApiService', error: e);
      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('auth_token');
    developer.log('Logged out', name: 'ApiService');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null;
  }

  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        developer.log(
          'Failed to fetch users: ${response.body}',
          name: 'ApiService',
        );
        return [];
      }
    } catch (e) {
      developer.log('Error fetching users: $e', name: 'ApiService', error: e);
      return [];
    }
  }

  static Future<bool> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        developer.log('User deleted successfully', name: 'ApiService');
        return true;
      } else {
        developer.log(
          'Failed to delete user: ${response.body}',
          name: 'ApiService',
        );
        return false;
      }
    } catch (e) {
      developer.log('Error deleting user: $e', name: 'ApiService', error: e);
      return false;
    }
  }

  static Future<bool> updateUser(int userId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$apiUrl/users/$userId'),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    return response.statusCode == 200;
  }

  // Add method to delete an image
  static Future<bool> deleteImage(String imageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/images/$imageId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        developer.log('Image deleted successfully', name: 'ApiService');
        return true;
      } else {
        developer.log(
          'Failed to delete image: ${response.body}',
          name: 'ApiService',
        );
        return false;
      }
    } catch (e) {
      developer.log('Error deleting image: $e', name: 'ApiService', error: e);
      return false;
    }
  }

  // **New Functionality to Upload Image**
  static Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/upload'), // Your API upload endpoint
      );

      var pic = await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
      );
      request.files.add(pic);

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        // Assuming the server returns the URL of the uploaded image
        return responseData; // This would be the image URL
      } else {
        developer.log('Failed to upload profile picture', name: 'ApiService');
        return null;
      }
    } catch (e) {
      developer.log(
        'Error uploading profile picture: $e',
        name: 'ApiService',
        error: e,
      );
      return null;
    }
  }
}

// Flutter UI for editing a user
class EditUserScreen extends StatefulWidget {
  final User user;
  const EditUserScreen({required this.user, super.key});

  @override
  EditUserScreenState createState() => EditUserScreenState();
}

// FIX 1: Made _EditUserScreenState ➔ EditUserScreenState (remove underscore)
class EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;

  @override
  void initState() {
    super.initState();
    _name = widget.user.name;
    _email = widget.user.email;
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        bool isUpdated = await ApiService.updateUser(widget.user.id, {
          'name': _name,
          'email': _email,
        });

        if (!mounted) return; // FIX 2: Add mounted check

        if (isUpdated) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update user')),
          );
        }
      } catch (error) {
        if (!mounted) return; // FIX 2: Add mounted check

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUser,
                child: const Text('Update User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
