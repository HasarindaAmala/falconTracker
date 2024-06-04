import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:simple_logger/simple_logger.dart';
import 'package:sprintf/sprintf.dart';
import 'ble_connectin_handler.dart';

class CommunicationHandler {
  SimpleLogger logger = SimpleLogger();
  late final BleConnectionHandler bleConnectionHandler;

  // UUID
  static const String uuidFormat = "0000%s-0000-1000-8000-00805f9b34fb";

  // device information
  static final Uuid deviceInformationService = Platform.isAndroid ? Uuid.parse(sprintf(uuidFormat, ["180a"])) : Uuid.parse("180a");
  static final Uuid deviceModelNumberCharacteristic = Platform.isAndroid ? Uuid.parse(sprintf(uuidFormat, ["2a24"])) : Uuid.parse("2a24");
  static final Uuid serialNumberCharacteristic = Platform.isAndroid ? Uuid.parse(sprintf(uuidFormat, ["2a25"])) : Uuid.parse("2a25");
  static final Uuid firmwareRevisionCharacteristic = Platform.isAndroid ? Uuid.parse(sprintf(uuidFormat, ["2a26"])) : Uuid.parse("2a26");

  static final Uuid batteryLevelService = Platform.isAndroid ? Uuid.parse(sprintf(uuidFormat, ["180f"])) : Uuid.parse("180f");
  static final Uuid batteryLevelCharacteristic = Platform.isAndroid ? Uuid.parse(sprintf(uuidFormat, ["2a19"])) : Uuid.parse("2a19");

  static final Uuid temperatureService = Platform.isAndroid ? Uuid.parse(sprintf(uuidFormat, ["1809"])) : Uuid.parse("1809");
  static final Uuid temperatureMeasurement = Platform.isAndroid ? Uuid.parse(sprintf(uuidFormat, ["2a1c"])) : Uuid.parse("2a1c");

  String deviceId = "";

  CommunicationHandler() {
    bleConnectionHandler = BleConnectionHandler();
  }

  void startScan(Function(DiscoveredDevice) scanDevice) {
    bleConnectionHandler.startBluetoothScan((discoveredDevice) => {scanDevice(discoveredDevice)});
  }

  Future<void> stopScan() async {
    await bleConnectionHandler.stopScan();
  }

  void connectToDevice(DiscoveredDevice discoveredDevice, Function(bool) connectionStatus) {
    bleConnectionHandler.connectToDevice(discoveredDevice, (isConnected) {
      deviceId = discoveredDevice.id;
      connectionStatus(isConnected);
      if(isConnected) {
        readDeviceInformation(deviceInformationService, deviceModelNumberCharacteristic);
      }
    });
  }

  Future<void> readDeviceInformation(Uuid service, Uuid characteristicToRead) async {
    final characteristic = QualifiedCharacteristic(serviceId: service, characteristicId: characteristicToRead, deviceId: deviceId);
    final response = await bleConnectionHandler.flutterReactiveBle.readCharacteristic(characteristic);
    receivedCharacteristicValue(characteristic: characteristic, values: response);
  }

  Future<void> subscribeToMeasurement(Uuid service, Uuid characteristicToNotify) async {
    final characteristic = QualifiedCharacteristic(serviceId: service, characteristicId: characteristicToNotify, deviceId: deviceId);
    bleConnectionHandler.flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
      if (data.isNotEmpty) {
        receivedCharacteristicValue(characteristic: characteristic, values: data);
      }
    }, onError: (dynamic error) {
      logger.info('Error with read measurement : $error');
    });
  }

  void receivedCharacteristicValue({required QualifiedCharacteristic characteristic, required List<int> values}) {
    if (characteristic.characteristicId == deviceModelNumberCharacteristic) {
      String value = utf8.decode(values);
      logger.info('Device model: $value');
      readDeviceInformation(deviceInformationService, serialNumberCharacteristic);
    } else if (characteristic.characteristicId == serialNumberCharacteristic) {
      String value = utf8.decode(values);
      logger.info('SerialNumber: $value');
      readDeviceInformation(deviceInformationService, firmwareRevisionCharacteristic);
    } else if (characteristic.characteristicId == firmwareRevisionCharacteristic) {
      String value = utf8.decode(values);
      logger.info('Firmware: $value');
      readDeviceInformation(batteryLevelService, batteryLevelCharacteristic);
    } else if (characteristic.characteristicId == batteryLevelCharacteristic) {
      int batteryValue = values[0];
      logger.info('Battery value: $batteryValue');
      subscribeToMeasurement(temperatureService, temperatureMeasurement);
    } else if (characteristic.characteristicId == temperatureMeasurement) {
      logger.info('value from device: $values');
      if (values.isNotEmpty) parseMeasurementValues(values);
    }
  }

  Future<void> parseMeasurementValues(List<int> values) async {
    double temperatureValueCelsius = parseTemperatureValue(values, 1);

    // int unit = values[0] & 0x01;
    // temperatureUnit == 1 -> Fahrenheit; convert to Celsius
    // if (unit == 1) {
    //   temperatureValueCelsius = (temperatureValueCelsius - 32) * 5 / 9;
    // }

    logger.warning("Temperature Value Celsius: $temperatureValueCelsius");
  }

  double parseTemperatureValue(List<int> data, int startingIndex) {
    int temperatureValue = 0;
    temperatureValue = temperatureValue + ((data[startingIndex] & 0xff) << 0);
    temperatureValue = temperatureValue + ((data[startingIndex + 1] & 0xff) << 8);
    temperatureValue = temperatureValue + ((data[startingIndex + 2] & 0xff) << 16);
    temperatureValue = temperatureValue & 0x00ffffff;

    int exponent = 127;
    return convertToFloat(temperatureValue, exponent);
  }

  double convertToFloat(int temperatureValue, int exponent) {
    int exponentAdjusted = exponent - 127;
    double value = temperatureValue.toDouble() * pow(2, exponentAdjusted);
    double tempValue = value / 10;
    return tempValue;
  }
}