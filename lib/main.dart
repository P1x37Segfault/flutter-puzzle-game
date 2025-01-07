import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:esense_flutter/esense.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'about.dart';
import 'settings.dart';
import 'observe_sensors.dart';
import 'game.dart';

void main() {
  // this forces the orientation to be portrait and locks it
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then(
    (_) => runApp(const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool sampling = false;

  // eSense device status and stuff
  bool useESenseSensor = false;
  bool eSenseConnected = false;
  String eSenseDeviceStatus = '';
  int samplingRate = 100; // in Hz
  ThemeMode themeMode = ThemeMode.system;

  // sensor values
  List<double> _eSenseGyro = [0, 0, 0];
  List<double> _eSenseGyroReoriented = [0, 0, 0];
  List<double> _eSenseAcc = [0, 0, 0];
  List<double> _eSenseAccReoriented = [0, 0, 0];
  List<double> _deviceGyro = [0, 0, 0];
  List<double> _deviceAcc = [0, 0, 0];

  // init esense manager
  static const String eSenseDeviceName = 'eSense-0390';
  ESenseManager eSenseManager = ESenseManager(eSenseDeviceName);

  // number of fractional digits to display
  static const int fractionalDigits = 2;

  @override
  void initState() {
    super.initState();
    _listenToESense();
    double ms = 1000 / samplingRate;
    Duration sensorInterval = Duration(milliseconds: ms.round());
    accelerometerEventStream(samplingPeriod: sensorInterval)
        .listen((AccelerometerEvent event) {
      setState(() {
        _deviceAcc = [event.x, event.y, event.z];
      });
    });
  }

  StreamSubscription? deviceGyroSubscription;
  StreamSubscription? deviceAccSubscription;
  void _startListenToDeviceSensorEvents() {
    deviceGyroSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        setState(() {
          _deviceGyro =
              [event.x, event.y, event.z].map((e) => e * (180 / pi)).toList();
        });
      },
      cancelOnError: true,
    );
    deviceAccSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        setState(() {
          _deviceAcc = [event.x, event.y, event.z];
        });
      },
      cancelOnError: true,
    );
  }

  void _pauseListenToDeviceSensorEvents() {
    deviceGyroSubscription?.cancel();
    deviceAccSubscription?.cancel();
  }

  Future<void> _askForPermissions() async {
    if (!(await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted)) {
      // todo print to log
      return;
    }
    if (Platform.isAndroid) {
      if (!(await Permission.locationWhenInUse.request().isGranted)) {
        // todo print to log
        return;
      }
    }
  }

  Future<void> _listenToESense() async {
    await _askForPermissions();

    eSenseManager.connectionEvents.listen((event) {
      setState(() {
        eSenseConnected = false;
        switch (event.type) {
          case ConnectionType.connected:
            eSenseDeviceStatus = 'connected';
            eSenseConnected = true;
            _startListenToESenseSensorEvents();
            break;
          case ConnectionType.unknown:
            eSenseDeviceStatus = 'unknown';
            break;
          case ConnectionType.disconnected:
            eSenseDeviceStatus = 'disconnected';
            _pauseListenToESenseSensorEvents();
            break;
          case ConnectionType.device_found:
            eSenseDeviceStatus = 'device found';
            break;
          case ConnectionType.device_not_found:
            eSenseDeviceStatus = 'device not found';
            break;
        }
      });
    });
  }

  Future<void> _connectToESense() async {
    if (!eSenseConnected) {
      eSenseDeviceStatus = 'connecting...';
      bool connected = await eSenseManager.connect();

      setState(() {
        eSenseConnected = connected;
      });
    }
  }

  Future<void> _disconnectFromESense() async {
    if (eSenseConnected) {
      bool disconnected = await eSenseManager.disconnect();

      setState(() {
        eSenseConnected = !disconnected;
      });
    }
  }

  StreamSubscription? eSenseSubscription;
  void _startListenToESenseSensorEvents() async {
    // any changes to the sampling frequency must be done BEFORE listening to sensor events
    await eSenseManager.setSamplingRate(samplingRate);

    // subscribe to sensor event from the eSense device
    eSenseSubscription = eSenseManager.sensorEvents.listen((event) {
      setState(() {
        // only update state, if the event contains valid data
        if (event.gyro != null) {
          _eSenseGyro = [event.gyro![0], event.gyro![1], event.gyro![2]]
              .map((e) => (e / 131)) // value divided by gyro scale factor
              .toList();

          // re-orient to match device orientation
          _eSenseGyroReoriented = [
            _eSenseGyro[2] * (-1),
            _eSenseGyro[1] * (-1),
            _eSenseGyro[0] * (-1)
          ];
        }

        if (event.accel != null) {
          _eSenseAcc = [event.accel![0], event.accel![1], event.accel![2]]
              .map((e) =>
                  (e / 8192) *
                  9.80665) // value divided by accel scale factor * g
              .toList();

          // re-orient to match device orientation
          _eSenseAccReoriented = [
            _eSenseAcc[2] * (-1),
            _eSenseAcc[1] * (-1),
            _eSenseAcc[0] * (-1)
          ];
        }
      });
    });
  }

  void _pauseListenToESenseSensorEvents() async {
    eSenseSubscription?.cancel();
  }

  void _startSampling() {
    setState(() {
      sampling = true;
    });
    if (useESenseSensor) {
      _startListenToESenseSensorEvents();
    } else {
      _startListenToDeviceSensorEvents();
    }
  }

  void _stopSampling() {
    setState(() {
      sampling = false;
    });
    if (useESenseSensor) {
      _pauseListenToESenseSensorEvents();
    } else {
      _pauseListenToDeviceSensorEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 28, 84, 214),
                Color.fromARGB(255, 49, 143, 210)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                DefaultTextStyle(
                  style: const TextStyle(color: Colors.white),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Flutter eSense App',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'by urhrf',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 25),
                      FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Builder(
                          builder: (BuildContext context) {
                            return OutlinedButton(
                              onPressed: () {
                                _startSampling();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GamePage(
                                      gyroData: useESenseSensor
                                          ? _eSenseGyroReoriented
                                          : _deviceGyro,
                                      accData: useESenseSensor
                                          ? _eSenseAccReoriented
                                          : _deviceAcc,
                                    ),
                                  ),
                                ).then((_) {
                                  _stopSampling();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                              ),
                              child: const Text(
                                'Play',
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Builder(
                          builder: (BuildContext context) {
                            return OutlinedButton(
                              onPressed: () {
                                _startSampling();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ObserveSensorsPage(
                                      gyroData: useESenseSensor
                                          ? _eSenseGyroReoriented
                                          : _deviceGyro,
                                      accData: useESenseSensor
                                          ? _eSenseAccReoriented
                                          : _deviceAcc,
                                      useESenseSensor: useESenseSensor,
                                      samplingRate: samplingRate,
                                    ),
                                  ),
                                ).then((_) {
                                  _stopSampling();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                              ),
                              child: const Text(
                                'Check Sensors',
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Builder(
                          builder: (BuildContext context) {
                            return OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SettingsPage(
                                      useESenseGyro: useESenseSensor,
                                      onToggleGyro: (bool value) {
                                        setState(() {
                                          useESenseSensor = value;
                                        });
                                      },
                                      eSenseManager: eSenseManager,
                                      eSenseDeviceStatus: eSenseDeviceStatus,
                                      onConnectESense: _connectToESense,
                                      onDisconnectESense: _disconnectFromESense,
                                      samplingRate: samplingRate,
                                      onSamplingRateChanged: (int value) {
                                        setState(() {
                                          samplingRate = value;
                                        });
                                      },
                                      themeMode: themeMode,
                                      onThemeModeChanged: (ThemeMode mode) {
                                        setState(() {
                                          themeMode = mode;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                              ),
                              child: const Text(
                                'Settings',
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Builder(
                          builder: (BuildContext context) {
                            return OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const AboutPage()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                              ),
                              child: const Text(
                                'About',
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
