import 'package:classifier/auth/login.dart';
import 'package:classifier/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/coffe.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Column(children: [
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Welcome to Coffee Detect",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Empowering coffee farmers with AI to ensure healthier crops and richer brews.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).asGlass(
                      tintColor:
                          Color.fromARGB(255, 4, 254, 12).withOpacity(0.8),
                      clipBorderRadius: BorderRadius.circular(5.0),
                    ),
                  )
                ]),
              ),

              SizedBox(height: (screenHeight - 280) / 7),

              ElevatedButton(
                onPressed: () {
                  // Check if there's a logged-in user
                  User? loggedInUser = FirebaseAuth.instance.currentUser;
                  if (loggedInUser != null) {
                    // If there's a logged-in user, navigate to the HomeScreen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  } else {
                    // If there's no logged-in user, navigate to the Login screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.green[900],
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      5.0,
                    ), // Adjust the radius as needed
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 32.0,
                  ),
                ),
                child: Text(
                  "Get Started",
                  style: TextStyle(
                    fontSize: 20, // Adjust the font size as needed
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ), // Add space between the button and the bottom edge
            ],
          ),
        ),
      ),
    );
  }
}
