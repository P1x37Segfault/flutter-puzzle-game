import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'widgets/circular_icon.dart';

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

enum SoundType { sequence, wrong, correct, point, gameover }

class GamePageState extends State<GamePage> {
  final double gestureThresholdESense = 21;
  final double gestureThresholdDevice = 75;
  final int gestureCooldown = 500;

  double _x = 0.0;
  double _y = 0.0;
  // double _z = 0.0;

  bool gestureDetected = false;
  bool canDetectGesture = true;
  bool isUserTurn = false;
  bool gameStarted = false;

  Gesture detectedGesture = Gesture.unknown;
  List<Gesture> sequence = [];
  List<Gesture> userInput = [];

  Color forwardArrowColor = Colors.grey;
  Color backwardArrowColor = Colors.grey;
  Color leftArrowColor = Colors.grey;
  Color rightArrowColor = Colors.grey;

  int score = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (gameStarted && isUserTurn && canDetectGesture) {
        detectGesture(widget.gyroData);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startNewGame() async {
    sequence.clear();
    userInput.clear();
    score = 0;
    await Future.delayed(const Duration(milliseconds: 500));
    addNewGestureToSequence();
  }

  void addNewGestureToSequence() async {
    setState(() {
      sequence.add(Gesture.values[Random().nextInt(4)]);
      userInput.clear();
    });
    await playSequence();
    setState(() {
      isUserTurn = true;
    });
  }

  Future<void> playSequence() async {
    await Future.delayed(const Duration(milliseconds: 750));
    for (var gesture in sequence) {
      await highlightGesture(gesture, Colors.orange);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> highlightGesture(Gesture gesture, Color color) async {
    setState(() {
      switch (gesture) {
        case Gesture.tiltForward:
          forwardArrowColor = color;
          break;
        case Gesture.tiltBackward:
          backwardArrowColor = color;
          break;
        case Gesture.tiltLeft:
          leftArrowColor = color;
          break;
        case Gesture.tiltRight:
          rightArrowColor = color;
          break;
        default:
          break;
      }
    });

    // wait for a while before resetting the color
    await Future.delayed(Duration(milliseconds: gestureCooldown));
    resetArrowColors();
  }

  void resetArrowColors() {
    forwardArrowColor = Colors.grey;
    backwardArrowColor = Colors.grey;
    leftArrowColor = Colors.grey;
    rightArrowColor = Colors.grey;
  }

  void checkUserInput(Gesture gesture) async {
    if (!isUserTurn) return;

    userInput.add(gesture);
    int currentIndex = userInput.length - 1;
    if (userInput[currentIndex] != sequence[currentIndex]) {
      isUserTurn = false;
      await highlightGesture(detectedGesture, Colors.red);
      // game over
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Game Over'),
              content: Text('Your score: $score'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    startNewGame();
                  },
                  child: const Text('Play Again'),
                ),
              ],
            );
          },
        );
      }
    } else if (userInput.length == sequence.length) {
      score++;
      isUserTurn = false;
      await highlightGesture(detectedGesture, Colors.green);
      addNewGestureToSequence();
    } else {
      highlightGesture(detectedGesture, Colors.green);
    }
  }

  void detectGesture(List<double> gyroData) {
    setState(() {
      _x = gyroData[0];
      _y = gyroData[1];
      // _z = gyroData[2];

      // the device orientation is as follows:
      // X is left
      // Y is backward
      // Z is down

      // check which axis has the highest abs input
      if (_x.abs() < _y.abs()) {
        checkLeftRightTilt(_y);
      } else {
        checkForwardBackwardTilt(_x);
      }

      if (gestureDetected) {
        canDetectGesture = false;
        checkUserInput(detectedGesture);
        Future.delayed(Duration(milliseconds: gestureCooldown), () {
          gestureDetected = false;
          canDetectGesture = true;
          resetArrowColors();
        });
      }
    });
  }

  void checkForwardBackwardTilt(double xVal) {
    double gestureThreshold = widget.useESenseSensor
        ? gestureThresholdESense
        : gestureThresholdDevice;
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
    double gestureThreshold = widget.useESenseSensor
        ? gestureThresholdESense
        : gestureThresholdDevice;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Score: $score', style: const TextStyle(fontSize: 24)),
          ),
          Expanded(
            child: Center(
              child: gameStarted
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircularIcon(
                            icon: Icons.arrow_upward, color: forwardArrowColor),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularIcon(
                                icon: Icons.arrow_back, color: leftArrowColor),
                            const SizedBox(width: 130),
                            CircularIcon(
                                icon: Icons.arrow_forward,
                                color: rightArrowColor),
                          ],
                        ),
                        const SizedBox(height: 30),
                        CircularIcon(
                            icon: Icons.arrow_downward,
                            color: backwardArrowColor),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          gameStarted = true;
                          startNewGame();
                        });
                      },
                      child: const Text('Start Game'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
