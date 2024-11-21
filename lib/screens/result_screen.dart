import 'package:flutter/material.dart';
import 'dart:io';

class ResultScreen extends StatelessWidget {
  final File image;
  final List<dynamic> recognitions;

  const ResultScreen({required this.image, required this.recognitions, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detection Results'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(
              image,
              width: 300,
              height: 300,
            ),
            SizedBox(height: 16),
            Text(
              'Detected Damage Type:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (recognitions.isNotEmpty)
              Text(
                recognitions.first['label'] ?? 'No damage detected',
                style: TextStyle(fontSize: 16, color: Colors.green),
              )
            else
              Text(
                'No damage detected',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
