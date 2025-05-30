import 'package:flutter/material.dart';
import 'package:bsit3bcrud/api_service.dart'
    as api_service; // Import your API service with alias
import 'package:bsit3bcrud/user_model.dart'; // Import the User model

class EditUserScreen extends StatefulWidget {
  final User user; // Refers to the User model from user_model.dart

  const EditUserScreen({super.key, required this.user});

  @override
  EditUserScreenState createState() => EditUserScreenState(); // Removed underscore
}

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
        bool isUpdated = await api_service.ApiService.updateUser(
          widget.user.id,
          {'name': _name, 'email': _email},
        );

        if (!mounted) return; // ✅ Mounted check after await

        if (isUpdated) {
          Navigator.pop(context); // Go back to the previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update user')),
          );
        }
      } catch (error) {
        if (!mounted) return; // ✅ Mounted check inside catch
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
                onSaved: (value) {
                  _name = value!;
                },
              ),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUser,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
