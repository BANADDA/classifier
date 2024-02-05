import 'dart:async';

import 'package:classifier/screens/start_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: 'AIzaSyDXkYYbRQ5lT6veVFjCVjje8Y1ynj6kZvI',
          appId: '1:888456447894:android:db86dfbafc400673877fb7',
          messagingSenderId: '888456447894',
          projectId: 'digisave-b0822'));
  Fluttertoast.showToast;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.brown,
          contentTextStyle: TextStyle(
            fontSize: 20,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _startTimer();
  }

  void _startTimer() {
    Timer(Duration(seconds: 3), _redirectGetStarted);
  }

  void _redirectGetStarted() {
    if (mounted) {
      setState(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const GetStartedScreen(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/coffe.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Coffee Detect",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 5.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 35,
              ),
              LoadingAnimationWidget.flickr(
                leftDotColor: Color.fromARGB(255, 29, 220, 0),
                rightDotColor: const Color(0xFFFF0084),
                size: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
