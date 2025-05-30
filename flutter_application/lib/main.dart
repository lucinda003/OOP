import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../screens/home_screen.dart'; // Correct import for HomeScreen
import '../screens/newsfeed_screen.dart'
    as custom; // Correct import for NewsFeedScreen

void main() => runApp(const FacebookReplication());

class FacebookReplication extends StatelessWidget {
  const FacebookReplication({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(412, 715),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Facebook Replication',
          initialRoute: '/home', // Initial route is /home
          routes: {
            '/home': (context) => const HomeScreen(), // Route for HomeScreen
            '/newsfeed': (context) =>
                const custom.NewsFeedScreen(), // Route for NewsFeedScreen
          },
        );
      },
    );
  }
}
