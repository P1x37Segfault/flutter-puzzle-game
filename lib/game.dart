import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/circular_icon.dart';
import 'how_to_play.dart';

class GamePage extends StatefulWidget {
  final List<double> gyroData;
  final bool useESenseSensor;
  final double sensitivity;

  /// Constructor for GamePage
  const GamePage({
    super.key,
    required this.gyroData,
    required this.useESenseSensor,
    required this.sensitivity,
  });

  @override
  GamePageState createState() => GamePageState();
}

enum Gesture { tiltForward, tiltBackward, tiltLeft, tiltRight }

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
        return '';
    }
  }
}

class GamePageState extends State<GamePage> {
  final double gestureThresholdESense = 25;
  final double gestureThresholdDevice = 75;
  final int gestureCooldown = 750;
  final String initialStatusMessage = "click on an\narrow to start the game";

  double _x = 0.0;
  double _y = 0.0;
  // double _z = 0.0;

  bool gestureDetected = false;
  bool canDetectGesture = true;
  bool isUserTurn = false;
  bool gameStarted = false;

  Gesture? detectedGesture;
  List<Gesture> sequence = [];
  List<Gesture> userInput = [];

  Color forwardArrowColor = Colors.grey;
  Color backwardArrowColor = Colors.grey;
  Color leftArrowColor = Colors.grey;
  Color rightArrowColor = Colors.grey;

  int score = 0;
  int highscore = 0;
  Timer? _timer;

  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    statusMessage = initialStatusMessage;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (gameStarted && isUserTurn && canDetectGesture) {
        detectGesture(widget.gyroData);
      }
    });
    _loadHighscore();
  }

  /// Loads the highscore from shared preferences
  Future<void> _loadHighscore() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      highscore = prefs.getInt('highscore') ?? 0;
    });
  }

  /// Saves the highscore to shared preferences
  Future<void> _saveHighscore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highscore', highscore);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Starts a new game
  void startNewGame() async {
    statusMessage = "Get ready!";
    sequence.clear();
    userInput.clear();
    score = 0;
    await Future.delayed(const Duration(milliseconds: 500));
    addNewGestureToSequence();
  }

  /// Adds a new gesture to the sequence
  void addNewGestureToSequence() async {
    setState(() {
      sequence.add(Gesture.values[Random().nextInt(4)]);
      userInput.clear();
    });
    await playSequence();
    setState(() {
      statusMessage = "Your turn!";
      isUserTurn = true;
    });
  }

  /// Plays the current sequence of gestures
  Future<void> playSequence() async {
    await Future.delayed(const Duration(milliseconds: 750));
    setState(() {
      statusMessage = "Sequence playing";
    });
    for (var gesture in sequence) {
      await highlightGesture(gesture, Colors.orange);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Highlights a gesture with a specified color
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
    await Future.delayed(const Duration(milliseconds: 500));
    resetArrowColors();
  }

  /// Resets the colors of the arrows
  void resetArrowColors() {
    forwardArrowColor = Colors.grey;
    backwardArrowColor = Colors.grey;
    leftArrowColor = Colors.grey;
    rightArrowColor = Colors.grey;
  }

  /// Checks the user's input against the sequence
  void checkUserInput(Gesture gesture) async {
    if (!isUserTurn) return;

    userInput.add(gesture);
    setState(() {
      statusMessage = "Gesture ${gesture.name} detected";
    });

    int currentIndex = userInput.length - 1;
    if (userInput[currentIndex] != sequence[currentIndex]) {
      isUserTurn = false;
      await highlightGesture(gesture, Colors.red);
      await _saveHighscore();
      // game over
      if (mounted) {
        final String sss = score > 1 ? 's' : '';
        List<String> messages = [
          "After eating $score taco$sss, Greg realized he might have misunderstood the concept of 'all-you-can-eat.'",
          "It only took $score raccoon$sss to completely destroy my camping trip.",
          "Martha hit snooze $score time$sss and still wondered why she was late.",
          "After $score hour$sss of assembling the furniture, I had two extra screws and zero patience.",
          "It took $score trie$sss to realize I was trying to unlock someone else`s car.",
          "At the party, Dave drank $score soda$sss, and now he`s vibrating like a phone on silent.",
          "After $score attempt$sss, I finally realized the 'push' door had a 'pull' sign.",
          "I spent $score hour$sss looking for my phone, only to realize I was holding it.",
        ];
        String gameOverMessage = messages[Random().nextInt(messages.length)];
        if (score == 0) {
          gameOverMessage = 'Do better.';
        }

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Game Over'),
              content: Text(
                gameOverMessage,
                style: const TextStyle(fontSize: 18),
              ),
              actions: [
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          statusMessage = initialStatusMessage;
                          gameStarted = false;
                        });
                      },
                      child: const Text('Ok', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } else if (userInput.length == sequence.length) {
      score++;
      if (score > highscore) {
        highscore = score;
      }
      isUserTurn = false;
      await highlightGesture(gesture, Colors.green);
      addNewGestureToSequence();
    } else {
      highlightGesture(gesture, Colors.green);
    }
  }

  /// Detects gestures based on gyro data
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

      if (gestureDetected && detectedGesture != null) {
        canDetectGesture = false;
        checkUserInput(detectedGesture!);
        Future.delayed(Duration(milliseconds: gestureCooldown), () {
          gestureDetected = false;
          canDetectGesture = true;
          resetArrowColors();
        });
      }
    });
  }

  /// Checks for forward or backward tilt
  void checkForwardBackwardTilt(double xVal) {
    double gestureThreshold = widget.useESenseSensor
        ? gestureThresholdESense
        : gestureThresholdDevice;

    gestureThreshold *= 1 / widget.sensitivity;
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

  /// Checks for left or right tilt
  void checkLeftRightTilt(double yVal) {
    double gestureThreshold = widget.useESenseSensor
        ? gestureThresholdESense
        : gestureThresholdDevice;
    gestureThreshold *= 1 / widget.sensitivity;
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

  /// Handles tap on the icon to start the game
  void handleIconTap() {
    if (!gameStarted) {
      setState(() {
        gameStarted = true;
        startNewGame();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HowToPlayPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Column(
            children: [
              Text('Highscore: $highscore',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 15),
              Text('Score: $score',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Expanded(
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularIcon(
                  icon: Icons.arrow_upward,
                  color: forwardArrowColor,
                  onTap: handleIconTap,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularIcon(
                      icon: Icons.arrow_back,
                      color: leftArrowColor,
                      onTap: handleIconTap,
                    ),
                    const SizedBox(width: 130),
                    CircularIcon(
                      icon: Icons.arrow_forward,
                      color: rightArrowColor,
                      onTap: handleIconTap,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                CircularIcon(
                  icon: Icons.arrow_downward,
                  color: backwardArrowColor,
                  onTap: handleIconTap,
                ),
              ],
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                height: 50, // Set a fixed height
                child: Text(
                  statusMessage,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }
}
