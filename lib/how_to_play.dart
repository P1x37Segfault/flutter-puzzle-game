import 'package:flutter/material.dart';

class HowToPlayPage extends StatelessWidget {
  const HowToPlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome to the game! Here's how to play:",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '1. The game starts with a random sequence containing one gesture (left, right, up, down).',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '2. Watch the sequence carefully as it is displayed.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '3. Repeat the sequence using gestures: (device gyro is used by default, can be changed in the settings)',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '   - up: Tilt Forward',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '   - down: Tilt Backward',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '   - left: Tilt Left',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '   - right: Tilt Right',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '4. If you repeat the sequence correctly, a new gesture is added to the sequence and displayed. Repeat step 2.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '5. The game continues until you make a mistake. The score is the length of the sequence you repeated successfully.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Good luck and have fun!',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
