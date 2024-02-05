import 'dart:io';

import 'package:classifier/auth/login.dart';
import 'package:classifier/widget/functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? rememberedOption;
  final _auth = FirebaseAuth.instance;

  User? loggedInUser;
  String? loggedInUserName;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
          loggedInUserName = user.displayName;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _showInstructions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.green[900],
                padding: EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                child: Center(
                  child: Text(
                    "Instructions",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "To classify an image:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 5),
              Divider(),
              SizedBox(height: 5),
              Text(
                "1. Tap on the camera icon to take a picture for classification.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 5),
              Divider(),
              SizedBox(height: 5),
              Text(
                "2. Alternatively, tap on the gallery icon to choose an image from your device's gallery.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showChooseOptionDialog(BuildContext context) async {
    bool rememberOption = false;

    return showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return CupertinoAlertDialog(
            title: Container(
              color: Color.fromARGB(255, 2, 119, 6),
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(
                    "Choose Option",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      color: Colors.green,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _classifyImage('Gallery', rememberOption);
                      },
                      child: Text("Gallery",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                          )),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    CupertinoButton(
                      color: Colors.green,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _classifyImage('Camera', rememberOption);
                      },
                      child: Text("Camera",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                          )),
                    ),
                    SizedBox(height: 5),
                    Divider(),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          "Remember this option?",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        CupertinoSwitch(
                          value: rememberOption,
                          onChanged: (bool value) {
                            // Update the state using setState
                            setState(() {
                              rememberOption = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Flexible(
                child: CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
              ),
              Flexible(
                child: CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _classifyImage(
                        rememberOption ? 'Remembered Option' : 'Forget Option',
                        rememberOption);
                  },
                  child: Text("Select"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _classifyImage(String option, bool rememberOption) async {
    setState(() {
      if (rememberOption) {
        rememberedOption = option;
      } else {
        rememberedOption = null;
      }
    });

    // Do classification based on the selected option
    print('Classifying image using $option...');

    String? pickedImagePath;

    if (option == 'Camera') {
      // Open camera to take a picture
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);
      pickedImagePath = pickedFile?.path;
    } else if (option == 'Gallery') {
      // Open gallery to select a picture
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      pickedImagePath = pickedFile?.path;
    }

    if (pickedImagePath != null) {
      // Generate a unique name for the image
      final String uniqueFileName = Uuid().v4();

      // Get the directory path for saving images
      final Directory appDirectory = await getApplicationDocumentsDirectory();
      final String imagesDirectoryPath = '${appDirectory.path}/Images';

      // Create the Images directory if it doesn't exist
      final Directory imagesDirectory =
          await Directory(imagesDirectoryPath).create(recursive: true);

      // Construct the path for saving the image
      final String imagePath = '$imagesDirectoryPath/$uniqueFileName.jpg';

      // Copy the picked image to the specified directory with the unique name
      final File pickedImageFile = File(pickedImagePath);
      await pickedImageFile.copy(imagePath);

      // Show modal dialog
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Classifier'),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(File(imagePath)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Predicted class: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Disease X',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color.fromARGB(255, 1, 94, 4)),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Confidence score: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '80%',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color.fromARGB(255, 1, 94, 4)),
                    )
                  ],
                )
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('Save'),
                onPressed: () async {
                  // Move the image file to the designated folder
                  final File savedImage = await pickedImageFile.copy(imagePath);
                  // Show a success message
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.cyan[900],
                    content: Center(
                      child: Text(
                        'Image saved successfully.',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.white),
                      ),
                    ),
                  ));
                  Navigator.of(context).pop();
                },
              ),
              CupertinoDialogAction(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _removeRememberedOption() {
    setState(() {
      rememberedOption = null;
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Perform logout logic here
                await _auth.signOut();
                Navigator.of(context).pop();
                // Navigate to login screen after logout
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Classifier",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[900],
        actions: [
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          loggedInUserName != null
                              ? "Welcome, $loggedInUserName!"
                              : "Welcome!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Empowering coffee farmers with AI to ensure healthier crops and richer brews.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showInstructions(context),
                          icon: Icon(
                            Icons.help_outline,
                            color: Color.fromARGB(255, 0, 59, 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).asGlass(
                  tintColor: Color.fromARGB(255, 4, 254, 12).withOpacity(0.8),
                  clipBorderRadius: BorderRadius.circular(5.0),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CustomContainer(
                    icon: Icons.scanner,
                    text: 'Scan',
                    bgColor: Color.fromARGB(255, 147, 203, 249),
                    onPressed: () => _showChooseOptionDialog(context),
                  ),
                  CustomContainer(
                    icon: Icons.history,
                    text: 'History',
                    bgColor: Color.fromARGB(255, 161, 252, 164),
                    onPressed: () {
                      // Action to perform when History container is pressed
                      print('History pressed');
                    },
                  ),
                  CustomContainer(
                    icon: Icons.settings,
                    text: 'Settings',
                    bgColor: Color.fromARGB(255, 248, 207, 145),
                    onPressed: () {
                      // Action to perform when Settings container is pressed
                      print('Settings pressed');
                    },
                  ),
                ],
              ),
              if (rememberedOption != null) ...[
                SizedBox(height: 10),
                Container(
                  color: Color.fromARGB(255, 208, 255, 210),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Selected scan Option: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$rememberedOption",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 2, 156, 8)),
                          )
                        ],
                      ),
                      IconButton(
                          onPressed: _removeRememberedOption,
                          icon: Icon(
                            Icons.read_more_outlined,
                            color: Color.fromARGB(255, 162, 12, 1),
                          )),
                    ],
                  ),
                )
                // ElevatedButton(
                //   onPressed: _removeRememberedOption,
                //   style: ElevatedButton.styleFrom(
                //     primary: Colors.red,
                //     onPrimary: Colors.white,
                //     padding: EdgeInsets.symmetric(
                //       vertical: 10,
                //       horizontal: 20,
                //     ),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(5),
                //     ),
                //   ),
                //   child: Text(
                //     "Forget Option",
                //     style: TextStyle(
                //       fontSize: 16,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
              ],
              SizedBox(height: (screenHeight - 280) / 3),
              // Column(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceAround,
              //       children: [
              //         ElevatedButton(
              //           onPressed: () => _showChooseOptionDialog(context),
              //           style: ElevatedButton.styleFrom(
              //             primary: Colors.green[900],
              //             onPrimary: Colors.white,
              //             padding: EdgeInsets.symmetric(
              //               vertical: 15,
              //               horizontal: 20,
              //             ),
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(5),
              //             ),
              //           ),
              //           child: Text(
              //             "Classify Crop",
              //             style: TextStyle(
              //               fontSize: 18,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ),
              //         ElevatedButton(
              //           onPressed: () {
              //             // Handle View History button press
              //           },
              //           style: ElevatedButton.styleFrom(
              //             primary: Colors.green[900],
              //             onPrimary: Colors.white,
              //             padding: EdgeInsets.symmetric(
              //               vertical: 15,
              //               horizontal: 20,
              //             ),
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(5),
              //             ),
              //           ),
              //           child: Text(
              //             "View History",
              //             style: TextStyle(
              //               fontSize: 18,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
