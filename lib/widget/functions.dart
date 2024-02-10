import 'package:flutter/material.dart';

class CustomContainer extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bgColor;
  final VoidCallback? onPressed;

  const CustomContainer({
    Key? key,
    required this.icon,
    required this.text,
    required this.bgColor,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 150, // Setting a fixed width for all containers
        height: 150, color: Color.fromARGB(255, 238, 250, 238),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 150,
                height: 80,
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors
                      .white, // Setting icon color to match background color
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              text,
              style: TextStyle(
                color: const Color.fromARGB(255, 1, 45, 2),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
