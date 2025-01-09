import 'dart:async';

import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  final List<double> gyroData;
  final bool useESenseSensor;

  const GamePage({
    super.key,
    required this.gyroData,
    required this.useESenseSensor,
  });

  @override
  GamePageState createState() => GamePageState();
}

enum Gesture { tiltForward, tiltBackward, tiltLeft, tiltRight, unknown }

extension GestureExtension on Gesture {
  String get name {
    switch (this) {
      case Gesture.tiltForward:
        return 'Tilt Forward';
      case Gesture.tiltBackward:
        return 'Tilt Backward';
      case Gesture.tiltLeft:
        return 'Tilt Left';
      case Gesture.tiltRight:
        return 'Tilt Right';
      default:
        return 'Unknown';
    }
  }
}

class GamePageState extends State<GamePage> {
  var useESenseSensor = false;
  final double gestureThresholdESense = 21;
  final double gestureThresholdDevice = 75;
  final int gestureCooldown = 500;

  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;
  bool gestureDetected = false;
  bool canDetectGesture = true;

  Gesture detectedGesture = Gesture.unknown; // Detected gesture
  Timer? _timer; // Timer for periodic updates

  // Define colors for each arrow
  Color forwardArrowColor = Colors.grey;
  Color backwardArrowColor = Colors.grey;
  Color leftArrowColor = Colors.grey;
  Color rightArrowColor = Colors.grey;
  Color turnLeftArrowColor = Colors.grey;
  Color turnRightArrowColor = Colors.grey;

  int score = 0; // Score indicator

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      updateGyroData(widget.gyroData);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing the widget
    super.dispose();
  }

  void updateGyroData(List<double> gyroData) {
    if (!canDetectGesture) {
      return;
    }

    setState(() {
      _x = gyroData[0];
      _y = gyroData[1];
      _z = gyroData[2];

      // the device orientation is as follows:
      // X is left
      // Y is backward
      // Z is down

      // check which axis has the highest tilt
      if (_x.abs() < _y.abs()) {
        checkLeftRightTilt(_y);
      } else {
        checkForwardBackwardTilt(_x);
      }

      if (gestureDetected) {
        canDetectGesture = false;
        updateArrowColors(detectedGesture);
        score++; // Increment score when a gesture is detected
        Future.delayed(Duration(milliseconds: gestureCooldown), () {
          gestureDetected = false;
          canDetectGesture = true;
          resetArrowColors();
        });
      }
    });
  }

  void checkForwardBackwardTilt(double xVal) {
    double gestureThreshold =
        useESenseSensor ? gestureThresholdESense : gestureThresholdDevice;
    if (xVal < -gestureThreshold) {
      detectedGesture = Gesture.tiltForward;
      gestureDetected = true;
    } else if (xVal > gestureThreshold) {
      detectedGesture = Gesture.tiltBackward;
      gestureDetected = true;
    } else {
      gestureDetected = false;
    }
  }

  void checkLeftRightTilt(double yVal) {
    double gestureThreshold =
        useESenseSensor ? gestureThresholdESense : gestureThresholdDevice;
    if (yVal < -gestureThreshold) {
      detectedGesture = Gesture.tiltLeft;
      gestureDetected = true;
    } else if (yVal > gestureThreshold) {
      detectedGesture = Gesture.tiltRight;
      gestureDetected = true;
    } else {
      gestureDetected = false;
    }
  }

  void updateArrowColors(Gesture gesture) {
    switch (gesture) {
      case Gesture.tiltForward:
        forwardArrowColor = Colors.green;
        break;
      case Gesture.tiltBackward:
        backwardArrowColor = Colors.green;
        break;
      case Gesture.tiltLeft:
        leftArrowColor = Colors.green;
        break;
      case Gesture.tiltRight:
        rightArrowColor = Colors.green;
        break;
      default:
        break;
    }
  }

  void resetArrowColors() {
    forwardArrowColor = Colors.grey;
    backwardArrowColor = Colors.grey;
    leftArrowColor = Colors.grey;
    rightArrowColor = Colors.grey;
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
            Text('Score: $score', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: forwardArrowColor,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.arrow_upward, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: leftArrowColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 60, color: Colors.white),
                ),
                const SizedBox(width: 121),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: rightArrowColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward,
                      size: 60, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: backwardArrowColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_downward,
                  size: 60, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
