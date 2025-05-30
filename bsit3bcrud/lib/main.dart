import 'package:flutter/material.dart';
import 'login_screen.dart'; // Ensure this is importing from the correct file
import 'user_screen.dart';
import 'api_service.dart' as api_service;
import 'create_user_screen.dart';
import 'package:bsit3bcrud/edit_user_screen.dart'; // Import the edit screen
import 'package:bsit3bcrud/user_model.dart'; // Import the User model
import 'feed_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => LoginScreen(onLogin: () {}),
        '/home':
            (context) => UserScreen(
              onLogout: () {
                api_service.ApiService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
        '/createUser':
            (context) => CreateUserScreen(
              onCreateUser: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
        '/editUser': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as User;
          return EditUserScreen(user: user); // Pass the user to the edit screen
        },
        '/feed': (context) => const FeedScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await api_service.ApiService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  void _handleLogin() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogout() {
    api_service.ApiService.logout();
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return UserScreen(onLogout: _handleLogout);
    }

    // New selection screen for login or create user
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(onLogin: _handleLogin),
                  ),
                );
              },
              child: const Text("Login"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CreateUserScreen(
                          onCreateUser: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                        ),
                  ),
                );
              },
              child: const Text("Create User"),
            ),
          ],
        ),
      ),
    );
  }
}
