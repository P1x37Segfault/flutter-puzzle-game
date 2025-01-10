import 'package:esense_flutter/esense.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatelessWidget {
  final ValueChanged<bool> onToggleSensor;
  final ESenseManager eSenseManager;
  final String eSenseDeviceStatus;
  final Future<void> Function() onConnectESense;
  final Future<void> Function() onDisconnectESense;
  final int samplingRate;
  final ValueChanged<int> onSamplingRateChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool useESenseSensor;
  final double sensitivity;
  final ValueChanged<double> onSensitivityChanged;

  const SettingsPage({
    super.key,
    required this.useESenseSensor,
    required this.onToggleSensor,
    required this.eSenseManager,
    required this.eSenseDeviceStatus,
    required this.onConnectESense,
    required this.onDisconnectESense,
    required this.samplingRate,
    required this.onSamplingRateChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.sensitivity,
    required this.onSensitivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('General'),
            tiles: [
              SettingsTile.switchTile(
                title: const Text('Use eSense Sensor'),
                leading: Icon(
                  Icons.sensors,
                  color: useESenseSensor ? Colors.blue : null,
                ),
                initialValue: useESenseSensor,
                onToggle: (bool value) {
                  onToggleSensor(value);
                },
                enabled: eSenseManager.connected,
              ),
              SettingsTile(
                title: const Text('Sampling Rate'),
                leading: const Icon(Icons.speed),
                trailing: DropdownButton<int>(
                  value: samplingRate,
                  items: const [
                    DropdownMenuItem(value: 25, child: Text('25 Hz')),
                    DropdownMenuItem(value: 50, child: Text('50 Hz')),
                    DropdownMenuItem(value: 100, child: Text('100 Hz')),
                  ],
                  onChanged: (int? value) {
                    if (value != null) {
                      onSamplingRateChanged(value);
                    }
                  },
                ),
              ),
              SettingsTile(
                title: const Text('Theme'),
                leading: const Icon(Icons.brightness_6),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  items: const [
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text('Dark')),
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text('System')),
                  ],
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      onThemeModeChanged(value);
                    }
                  },
                ),
              ),
              SettingsTile(
                title: const Text('Sensitivity'),
                leading: const Icon(Icons.tune),
                trailing: Slider(
                  value: sensitivity,
                  min: 0.5,
                  max: 1.5,
                  divisions: 10,
                  label: sensitivity.toStringAsFixed(1),
                  onChanged: (double value) {
                    onSensitivityChanged(value);
                  },
                ),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Devices'),
            tiles: [
              SettingsTile(
                title: const Text('eSense-0390'),
                leading: Icon(
                  eSenseManager.connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: eSenseManager.connected ? Colors.blue : null,
                ),
                onPressed: (BuildContext context) async {
                  bool isPermanentlyDenied =
                      await Permission.bluetoothScan.isPermanentlyDenied ||
                          await Permission.bluetoothConnect.isPermanentlyDenied;
                  if (isPermanentlyDenied) {
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Permission Required'),
                          content: const Text(
                              'Please grant the necessary permissions to connect to the eSense device.'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Open Settings'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                openAppSettings();
                              },
                            ),
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }
                  eSenseManager.connected
                      ? onDisconnectESense()
                      : onConnectESense();
                },
                trailing: Text(eSenseDeviceStatus),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
