import 'dart:async';

import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  final List<double> gyroData;
  final List<double> accData;

  const GamePage({
    super.key,
    required this.gyroData,
    required this.accData,
  });

  @override
  GamePageState createState() => GamePageState();
}

class GamePageState extends State<GamePage> {
  var useESenseSensor = false;
  final double gestureThreshold = 50;
  final List<double> gyroXValues = [];
  final List<double> gyroYValues = [];
  final List<double> gyroZValues = [];
  final int smoothingWindowSize = 10;

  double currentGyroX = 0.0;
  double currentGyroY = 0.0;
  double currentGyroZ = 0.0;
  bool gestureDetected = false;
  bool canDetectGesture = true;

  String detectedGesture = ''; // Detected gesture
  Timer? _timer; // Timer for periodic updates

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      updateGyroData(widget.gyroData);
      updateApplePosition();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing the widget
    super.dispose();
  }

  void updateGyroData(List<double> gyroData) {
    setState(() {
      currentGyroX = gyroData[0];
      currentGyroY = gyroData[1];
      currentGyroZ = gyroData[2];

      // Detect head gestures
      if (currentGyroX > gestureThreshold) {
        detectedGesture = 'Tilt Right';
        movePieceRight();
      } else if (currentGyroX < -gestureThreshold) {
        detectedGesture = 'Tilt Left';
        movePieceLeft();
      } else if (currentGyroY > gestureThreshold) {
        detectedGesture = 'Nod Down';
        rotatePieceCounterClockwise();
      } else if (currentGyroY < -gestureThreshold) {
        detectedGesture = 'Nod Up';
        rotatePieceClockwise();
      } else if (currentGyroZ > gestureThreshold ||
          currentGyroZ < -gestureThreshold) {
        detectedGesture = 'Shake Head';
        shufflePieces();
      } else {
        detectedGesture = '';
      }
    });
  }

  void movePieceLeft() {
    // Logic to move the puzzle piece to the left
  }

  void movePieceRight() {
    // Logic to move the puzzle piece to the right
  }

  void rotatePieceClockwise() {
    // Logic to rotate the puzzle piece clockwise
  }

  void rotatePieceCounterClockwise() {
    // Logic to rotate the puzzle piece counterclockwise
  }

  void shufflePieces() {
    // Logic to shuffle the puzzle pieces
  }

  void updateApplePosition() {
    // Update apple position logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Detected Gesture: $detectedGesture'),
          ],
        ),
      ),
    );
  }
}
