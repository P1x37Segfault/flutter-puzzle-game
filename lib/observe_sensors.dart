import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_app/widgets/legend_item.dart';

class ObserveSensorsPage extends StatefulWidget {
  final int samplingRate;
  final bool useESenseSensor;
  final List<double> gyroData;
  final List<double> accData;

  const ObserveSensorsPage(
      {super.key,
      required this.gyroData,
      required this.accData,
      required this.samplingRate,
      required this.useESenseSensor});

  @override
  _ObserveSensorsPageState createState() => _ObserveSensorsPageState();
}

class _ObserveSensorsPageState extends State<ObserveSensorsPage> {
  List<FlSpot> gyroXSpots = [];
  List<FlSpot> gyroYSpots = [];
  List<FlSpot> gyroZSpots = [];
  List<FlSpot> accXSpots = [];
  List<FlSpot> accYSpots = [];
  List<FlSpot> accZSpots = [];
  double time = 0;

  var useESenseSensor = false;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        time += 0.05; // Adjusted time increment
        gyroXSpots.add(FlSpot(time, widget.gyroData[0]));
        gyroYSpots.add(FlSpot(time, widget.gyroData[1]));
        gyroZSpots.add(FlSpot(time, widget.gyroData[2]));
        accXSpots.add(FlSpot(time, widget.accData[0]));
        accYSpots.add(FlSpot(time, widget.accData[1]));
        accZSpots.add(FlSpot(time, widget.accData[2]));

        if (gyroXSpots.length > 100) {
          gyroXSpots.removeAt(0);
          gyroYSpots.removeAt(0);
          gyroZSpots.removeAt(0);
          accXSpots.removeAt(0);
          accYSpots.removeAt(0);
          accZSpots.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observe Sensors'), // Updated title
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Gyroscope (deg/s)',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Added padding
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: gyroXSpots,
                        isCurved: false,
                        color: Colors.red,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: gyroYSpots,
                        isCurved: false,
                        color: Colors.green,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: gyroZSpots,
                        isCurved: false,
                        color: Colors.blue,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Accelerometer (m/s²)',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Added padding
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: accXSpots,
                        isCurved: false,
                        color: Colors.red,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: accYSpots,
                        isCurved: false,
                        color: Colors.green,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: accZSpots,
                        isCurved: false,
                        color: Colors.blue,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LegendItem(color: Colors.red, text: 'X-axis'),
                SizedBox(width: 10),
                LegendItem(color: Colors.green, text: 'Y-axis'),
                SizedBox(width: 10),
                LegendItem(color: Colors.blue, text: 'Z-axis'),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.useESenseSensor
                  ? 'Using eSense Sensor'
                  : 'Using Phone Sensor',
            ),
            Text('Sampling rate: ${widget.samplingRate} Hz'),
          ],
        ),
      ),
    );
  }
}
