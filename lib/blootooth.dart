import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class ConnectBluetooth extends StatefulWidget {
  const ConnectBluetooth({super.key});

  @override
  State<ConnectBluetooth> createState() => _ConnectBluetoothState();
}

class _ConnectBluetoothState extends State<ConnectBluetooth> {
  final _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSub;
  StreamSubscription<List<int>>? _notifySub;

  var _found = false;
  var _value = '';
  late List<int> byteInput;
  Future<void> check() async {

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.bluetoothAdvertise,
    ].request();



    if(await Permission.location.serviceStatus.isEnabled){
      print("enabled");
      var status = await Permission.location.status;
      if(status.isGranted){
        print("granted");
      }else if(status.isDenied){
        print("denied");
        Map<Permission,PermissionStatus> status = await [
          Permission.location,
        ].request();
      }

    }else{
      print("not enabeled");
      var status = await Permission.location.status;
      if(status.isGranted){
        print("granted");
      }else if(status.isDenied){
        print("denied");
        Map<Permission,PermissionStatus> status = await [
          Permission.location,
        ].request();
      }
    }

  }
  @override
  initState() {
    super.initState();
    _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    _connectSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  void _onScanUpdate(DiscoveredDevice d) {
    if (d.name == 'Falcon Tracker' ) {
      print(d.id);
      _found = true;
      _connectSub = _ble.connectToDevice(id: d.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          print("connected");
          _onConnected(d.id);
        }
      });

    }

  }

  void _onConnected(String deviceId) {
    final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse('0000181c-0000-1000-8000-00805f9b34fb'),
        characteristicId: Uuid.parse('00002a38-0000-1000-8000-00805f9b34fb'));

    _notifySub = _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
      setState(() {
        // Convert bytes to string using UTF-8 encoding

        _value = const Utf8Decoder().convert(bytes);
        print(bytes);

        // Print each line separately

      });
    });
  }

  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("test"),
      ),
      body: Center(
          child: _value.isEmpty
              ? const CircularProgressIndicator()
              : Text(_value, style: TextStyle(fontSize: 15.0))),
    );
  }

}
