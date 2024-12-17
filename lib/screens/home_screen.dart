import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  late Interpreter _interpreter;
  List<String> _labels = [];
  String _result = "No Result";

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  // Load the TFLite model and labels
  Future<void> _loadModelAndLabels() async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset('assets/model (1) (1).tflite');

      // Load the labels
      final labelData = await DefaultAssetBundle.of(context).loadString('assets/labels (1).txt');
      _labels = labelData.split('\n');

      print('Model and labels loaded successfully');
    } catch (e) {
      print('Error loading model or labels: $e');
    }
  }

  // Run inference on the selected image
  Future<void> _runModelOnImage() async {
    if (_image == null) {
      setState(() {
        _result = "Aucune image sélectionnée";
      });
      return;
    }

    try {
      // Charger et prétraiter l'image
      final img.Image imageInput = img.decodeImage(await _image!.readAsBytes())!;
      final img.Image resizedImage = img.copyResize(imageInput, width: 224, height: 224);
      final input = _preprocessImage(resizedImage);

      // Définir la sortie avec la nouvelle forme
      final output = List.generate(1, (_) => List.filled(2, 0.0), growable: false);

      // Exécuter l'inférence
      _interpreter.run(input.reshape([1, 224, 224, 3]), output);

      // Récupérer le résultat
      final topResult = _getTopRecognition(output);
      setState(() {
        _result = "Résultat : ${topResult['label']} (Confiance : ${(topResult['confidence'] * 100).toStringAsFixed(2)}%)";
      });
    } catch (e) {
      print('Error during inference: $e');
      setState(() {
        _result = "Erreur pendant l'inférence";
      });
    }
  }



  // Preprocess the image for the model
  Float32List _preprocessImage(img.Image image) {
    final input = Float32List(1 * 224 * 224 * 3);
    int index = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = image.getPixel(x, y);
        input[index++] = (pixel.r / 127.5) - 1.0; // Red
        input[index++] = (pixel.g / 127.5) - 1.0; // Green
        input[index++] = (pixel.b / 127.5) - 1.0; // Blue
      }
    }
    return input;
  }

  // Get the top recognition result
  Map<String, dynamic> _getTopRecognition(List<List<double>> output) {
    final scores = output[0];
    int maxIndex = 0;
    double maxScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }
    return {
      'label': _labels[maxIndex],
      'confidence': maxScore,
    };
  }

  // Pick an image from the camera or gallery
  Future<void> _pickImage({required ImageSource source}) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = "Processing...";
      });
      await _runModelOnImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Damage Detection'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null)
                Image.file(
                  _image!,
                  width: 300,
                  height: 300,
                ),
              SizedBox(height: 16),
              Text(
                _result,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _pickImage(source: ImageSource.camera),
                child: Text('Take Photo'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _pickImage(source: ImageSource.gallery),
                child: Text('Pick from Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
