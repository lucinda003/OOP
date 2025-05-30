import 'package:flutter/material.dart';
import 'api_service.dart'; // Assuming ApiService is in api_service.dart
import 'package:logger/logger.dart'; // Import logger package

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final logger = Logger(); // Initialize logger

  void _attemptLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    logger.d('Attempting login with email: $email');

    setState(() {
      _isLoading = true;
      logger.d('Setting _isLoading to true');
    });

    final startTime = DateTime.now();
    final result = await ApiService.login(email, password);
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;
    logger.d('ApiService.login completed in $duration ms');

    if (!mounted) {
      logger.d('Widget not mounted after API call');
      return;
    }

    setState(() {
      _isLoading = false;
      logger.d('Setting _isLoading to false');
    });

    if (result['success']) {
      logger.d('Login successful, navigating to home');
      widget.onLogin();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      logger.d('Login failed: ${result['message']}');
      if (mounted) {
        String errorMessage = result['message'];
        if (result['details'] != null) {
          logger.d('Error details: ${result['details']}');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : _attemptLogin, // Disable button while loading
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
