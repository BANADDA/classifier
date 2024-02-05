import 'package:flutter/material.dart';

class FrostedDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200.withOpacity(0.5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: PhysicalModel(
            color: Colors.white,
            elevation: 0.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 200.0,
              height: 200.0,
              child: Center(
                child: Text(
                  'Frosted',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
