import 'dart:convert';
import 'dart:io';

import 'package:classifier/auth/login.dart';
import 'package:classifier/models/prediction_model.dart';
import 'package:classifier/screens/HistoryScreen.dart';
import 'package:classifier/screens/details_screen.dart';
import 'package:classifier/widget/functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glass/glass.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Interpreter? _interpreter;
  List<String> _classLabels = ["miner", "rust", "phoma"];

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  String? rememberedOption;
  final _auth = FirebaseAuth.instance;

  User? loggedInUser;
  String? loggedInUserName;

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

// Function to navigate to the details screen
  void _navigateToDetailsScreen(
      BuildContext context, String imagePath, String prediction) async {
    String jsonString = await rootBundle.loadString('assets/predictions.json');
    Map<String, dynamic> jsonData = json.decode(jsonString);

    List<String> symptoms =
        jsonData['predictions'][prediction]['symptoms'].cast<String>();
    List<String> remedies =
        jsonData['predictions'][prediction]['treatment'].cast<String>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsScreen(
          imagePath: imagePath,
          prediction: prediction,
          symptoms: symptoms,
          remedies: remedies,
        ),
      ),
    );
  }

  static const _modelPath = "assets/converted_model.tflite";

  Future<void> _loadModel() async {
    try {
      // Load model from assets
      _interpreter = await Interpreter.fromAsset(_modelPath);
    } catch (e) {
      print('Error loading TFLite model: $e');
    }
  }

  Future<Map<String, dynamic>> classifyImage(File imageFile) async {
    try {
      setState(() {
        isLoading = true;
      });
      var url = Uri.parse('https://api-coffe-tu74.onrender.com/predict');

      var request = http.MultipartRequest('POST', url);
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Response: ${responseData}");
        final predictedClass = responseData['class'];
        final confidenceScore =
            (responseData['confidence'] * 100).toStringAsFixed(2);
        setState(() {
          isLoading = false;
        });
        return {'class': predictedClass, 'confidence': '$confidenceScore%'};
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to classify image. Status code: ${response.statusCode}');
        return {'error': 'Failed to classify image'};
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error classifying image: $e');
      return {'error': 'Error: $e'};
    }
  }

  Future<Uint8List> _getImageBytes(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    return Uint8List.fromList(imageBytes);
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
      final File pickedImageFile = File(pickedImagePath);
      Map<String, dynamic> classificationResult = {};

      try {
        classificationResult = await classifyImage(pickedImageFile);
      } catch (e) {
        print('Error classifying image: $e');
      }
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
                      classificationResult['class'] ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: const Color.fromARGB(255, 1, 94, 4),
                      ),
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
                      classificationResult['confidence'] ?? 'N/A',
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
              // Conditionally display the "View Details" button
              if (classificationResult['class'] != 'nodisease')
                CupertinoDialogAction(
                  child: Text('View Details'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navigateToDetailsScreen(context, imagePath, "Coffee Rust");
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

  bool isLoading = false;

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
        body: Stack(children: [
          SingleChildScrollView(
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
                            tintColor: Color.fromARGB(255, 4, 254, 12)
                                .withOpacity(0.8),
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
                              bgColor: Color.fromARGB(255, 122, 143, 1),
                              onPressed: () => _showChooseOptionDialog(context),
                            ),
                            CustomContainer(
                              icon: Icons.history,
                              text: 'History',
                              bgColor: Color.fromARGB(255, 73, 43, 0),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HistoryScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                        Container(
                            child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Center(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Text(
                                              'Previous Predictions',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Divider(
                                            color: Colors.black,
                                          ),
                                          SizedBox(height: 5),
                                          // Small section for predictions made on the current date
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FutureBuilder<List<Prediction>>(
                                                future:
                                                    Prediction.retrieveAll(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return Center(
                                                        child:
                                                            CircularProgressIndicator());
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return Text(
                                                        "Error: ${snapshot.error}");
                                                  } else if (!snapshot
                                                          .hasData ||
                                                      snapshot.data!.isEmpty) {
                                                    return Center(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                              "No saved predictions available."),
                                                          SizedBox(
                                                            height: 15,
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  } else {
                                                    // Filter predictions made today
                                                    final today =
                                                        DateTime.now();
                                                    final todayPredictions =
                                                        snapshot.data!.where(
                                                            (prediction) {
                                                      final predictionDate =
                                                          DateTime.parse(
                                                              prediction.date);
                                                      return predictionDate
                                                                  .year ==
                                                              today.year &&
                                                          predictionDate
                                                                  .month ==
                                                              today.month &&
                                                          predictionDate.day ==
                                                              today.day;
                                                    }).toList();

                                                    if (todayPredictions
                                                        .isEmpty) {
                                                      return Text(
                                                          "No predictions made today.");
                                                    }

                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: todayPredictions
                                                          .map((prediction) {
                                                        return GestureDetector(
                                                          onTap: () {
                                                            // Navigate to details screen on prediction click
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) =>
                                                                    PredictionDetailsScreen(
                                                                        prediction:
                                                                            prediction),
                                                              ),
                                                            );
                                                          },
                                                          child: Card(
                                                            elevation: 5,
                                                            margin: EdgeInsets
                                                                .symmetric(
                                                                    vertical: 8,
                                                                    horizontal:
                                                                        16),
                                                            child: ListTile(
                                                              title: Text(
                                                                prediction
                                                                    .prediction,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              subtitle: Text(
                                                                "Time: ${DateFormat('hh:mm a').format(DateTime.parse(prediction.date))}", // Use formatted date
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              onTap: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        PredictionDetailsScreen(
                                                                            prediction:
                                                                                prediction),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(height: 20),
                                              // Button to view more predictions
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                HistoryScreen()),
                                                      );
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      primary:
                                                          Colors.green[900],
                                                      onPrimary: Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 10,
                                                              horizontal: 20),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "View More",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        primary:
                                                            Colors.green[900],
                                                        onPrimary: Colors.white,
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 10,
                                                                horizontal: 20),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator
                                                            .pushReplacement(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                HomeScreen(),
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        "Reload",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
                                                      ))
                                                ],
                                              )
                                            ],
                                          ),

                                          if (rememberedOption != null) ...[
                                            SizedBox(height: 10),
                                            Container(
                                              color: Color.fromARGB(
                                                  255, 208, 255, 210),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Selected scan Option: ",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        "$rememberedOption",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    2,
                                                                    156,
                                                                    8)),
                                                      )
                                                    ],
                                                  ),
                                                  IconButton(
                                                      onPressed:
                                                          _removeRememberedOption,
                                                      icon: Icon(
                                                        Icons
                                                            .read_more_outlined,
                                                        color: Color.fromARGB(
                                                            255, 162, 12, 1),
                                                      )),
                                                ],
                                              ),
                                            )
                                          ],
                                          SizedBox(
                                              height: (screenHeight - 280) / 3),
                                        ],
                                      )
                                    ]))))
                      ]))),
          if (isLoading) // Overlay loading widget
            Container(
              color: Colors.black.withOpacity(0.5), // Transparent black color
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Classifying image...",
                      style: TextStyle(
                          color: Color.fromARGB(255, 245, 247, 245),
                          fontWeight: FontWeight.w700,
                          fontSize: 25),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            )
        ]));
  }
}
