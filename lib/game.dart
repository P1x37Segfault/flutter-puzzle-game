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

enum Axis {
  X,
  Y,
  Z,
}

enum Gesture {
  tiltForward,
  tiltBackward,
  tiltLeft,
  tiltRight,
  turnLeft,
  turnRight,
  unknown
}

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
      case Gesture.turnLeft:
        return 'Turn Left';
      case Gesture.turnRight:
        return 'Turn Right';
      default:
        return 'Unknown';
    }
  }
}

class GamePageState extends State<GamePage> {
  var useESenseSensor = false;
  final double gestureThresholdESense = 21;
  final double gestureThresholdDevice = 75;
  final int gestureCooldown = 750;

  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;
  bool gestureDetected = false;
  bool canDetectGesture = true;

  Gesture detectedGesture = Gesture.unknown; // Detected gesture
  Timer? _timer; // Timer for periodic updates

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
        Future.delayed(Duration(milliseconds: gestureCooldown), () {
          gestureDetected = false;
          canDetectGesture = true;
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

  void checkLeftRightTurn(double zVal) {
    if (zVal > gestureThreshold) {
      detectedGesture = Gesture.turnLeft;
      gestureDetected = true;
    } else if (zVal < -gestureThreshold) {
      detectedGesture = Gesture.turnRight;
      gestureDetected = true;
    } else {
      gestureDetected = false;
    }
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
            Text(detectedGesture != Gesture.unknown
                ? 'Detected Gesture: ${detectedGesture.name}'
                : 'No Gesture detected'),
            const SizedBox(height: 20),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canDetectGesture ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
