import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite/tflite.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  final _auth = FirebaseAuth.instance;

  List<String> _labels = [];
  List<dynamic> _recognitions = [];
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    Tflite.close();
    try {
      await Tflite.loadModel(
        model: 'assets/model.tflite',
        labels: 'assets/labels.txt',
      );
      setState(() {
        _modelLoaded = true;
      });
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      String labelsText = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsText.split('\n');
    } catch (e) {
      print('Error loading labels: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _runObjectDetection();
    }
  }

  Future<void> _runObjectDetection() async {
    try {
      List<dynamic>? recognitions = await Tflite.runModelOnImage(
        path: _image!.path,
        numResults: 10,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      if (recognitions != null) {
        setState(() {
          _recognitions = recognitions;
        });
      } else {
        setState(() {
          _recognitions = [];
        });
      }
    } catch (e) {
      print('Error running object detection: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      try {
        await FirebaseStorage.instance
            .ref('uploads/${_image!.path.split('/').last}')
            .putFile(_image!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully!')),
        );
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Car Image'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(
                _image!,
                width: 200,
                height: 200,
              ),
            SizedBox(height: 16),
            if (_modelLoaded)
              Expanded(
                child: ListView.builder(
                  itemCount: _recognitions.length,
                  itemBuilder: (context, index) {
                    final recognition = _recognitions[index];
                    final id = recognition['index'];
                    final confidence = recognition['confidence'];
                    final label = _labels[id];
                    final location = recognition['rect'];
                    return ListTile(
                      title: Text('$label (${confidence.toStringAsFixed(2)})'),
                      subtitle: Text('Location: $location'),
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}