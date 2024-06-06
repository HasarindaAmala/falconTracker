import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';



List<int> byteInput = [0,2];
 double originLng = 0.0;
  double originLat = 0.0 ;
double desLat =7.175489;
double desLng = 80.558137;
double distance = 0;
String dis = "";

Set<Polyline> _polylines = {};
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  
  //bluetooth
  final _ble = FlutterReactiveBle();
  late int preByte;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSub;
  StreamSubscription<List<int>>? _notifySub;
  List<int> completeMessage = [];
  var _found = false;
  var _value = '';

  
  //google map
  BitmapDescriptor? customIcon;
  late Position _currentPosition;
  String? _currentAddress;
 // Position? _currentPosition;
  bool _isLoading = true;
  bool destinationMrk = false;
  late GoogleMapController _mapController ;
  TextEditingController originController = TextEditingController();
  TextEditingController destController = TextEditingController();

   @override
  void initState() {
     check();
     _loadCustomIcon();
     _getCurrentLocation();

    // TODO: implement initState
    super.initState();
  }

  void _loadCustomIcon() async {
    // Load the arrow icon image from assets
    customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(28, 28)), // Adjust the size as needed
      'images/arrowS.png', // Replace 'arrow_icon.png' with your actual image file
    );
  }

  _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      print(_currentPosition.latitude);
      setState(() {
        originLat = _currentPosition.latitude;
        originLng = _currentPosition.longitude;
        desLat = _currentPosition.latitude;
        desLng = _currentPosition.longitude;
        originController.text = "$originLat,$originLng";
        destController.text = "$desLat,$desLng";
        _isLoading = false;
      });


    });
  }


  @override
  void dispose() {
    // TODO: implement dispose
    _notifySub?.cancel();
    _connectSub?.cancel();
    _scanSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }



//bluetooth functions
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


        // Add the received bytes to the completeMessage list
        if (byteInput != null && byteInput!.toString() != bytes.toString()) {
          completeMessage.addAll(bytes);
          byteInput = bytes;
          print("completeMessage$completeMessage");
          if (completeMessage.contains(36)) { // Check for the end marker '$'

            // Convert the list of bytes to a string using UTF-8 encoding
            final asciiDecoder = AsciiDecoder();
            final result = asciiDecoder.convert(completeMessage);
            print("result:$result");
            // Split the message using the delimiter '%'
            final message = result.split('%');

            // Check if the message has the expected number of components
            if (message.length >= 3) {
              // Extract individual components
              final deviceId = message[0].trim();
              final packetId = message[1].trim();
              final longitude = message[2].trim();
              var latitude = message[3].trim();
              if (latitude != null && latitude.length > 0) {
                latitude = latitude.substring(0, 9);
              }
              //String Lat = Latitude;

              // Print or use the extracted values
              print("Device ID: $deviceId");
              print("Packet ID: $packetId");
              print("Longitude: $longitude");
              print("Latitude: $latitude");


              originController.text = originController.text;
              destController.text = "$longitude,$latitude";
              getCoordinates(originController.text, destController.text);
              // Clear the completeMessage list to prepare for the next message
              completeMessage.clear();
            } else {
              // Invalid message format
              print("Invalid message format");
              // Clear the completeMessage list to discard the current incomplete message
              completeMessage.clear();
            }
          }
        }

        // Process the complete message if it's received in full

      });
    });
    // setState(() {
    //   print("value is: $bytes");
    //   // Check if the current bytes are different from the previous ones
    //   if (byteInput != null && byteInput!.toString() != bytes.toString()) {
    //     // Convert bytes to string using UTF-8 encoding
    //     final asciiDecoder = AsciiDecoder();
    //     final result = asciiDecoder.convert(bytes);
    //
    //     print("value is: $bytes");
    //     // Split the message using the delimiter ', '
    //     final message = result.split('%');
    //
    //     // Check if the message has the expected number of components
    //     if (message.length == 4) {
    //       // Extract individual components
    //       final deviceId = message[0].trim();
    //       final packetId = message[1].trim();
    //       final longitude = message[2].trim();
    //       final latitude = message[3];
    //
    //       // Print or use the extracted values
    //       print(bytes);
    //       print(_value);
    //       print("Device ID: $deviceId");
    //       print("Packet ID: $packetId");
    //       print("Longitude: $longitude");
    //       print("Latitude: $latitude");
    //
    //       // Update the previous bytes to the current ones
    //       byteInput = bytes;
    //     } else {
    //
    //     }
    //   } else if (byteInput == null) {
    //     // Convert bytes to string using UTF-8 encoding if this is the first message
    //     final asciiDecoder = AsciiDecoder();
    //     final result = asciiDecoder.convert(bytes);
    //
    //
    //     // Split the message using the delimiter ', '
    //     final message = result.split(', ');
    //
    //     // Check if the message has the expected number of components
    //     if (message.length == 5) {
    //       // Extract individual components
    //       final deviceId = message[0].trim();
    //       final packetId = message[1].trim();
    //       final longitude = message[2].trim();
    //       final latitude = message[3].trim();
    //
    //       // Print or use the extracted values
    //       print("Device ID: $deviceId");
    //       print("Packet ID: $packetId");
    //       print("Longitude: $longitude");
    //       print("Latitude: $latitude");
    //
    //       // Update the previous bytes to the current ones
    //       byteInput = bytes;
    //     } else {
    //
    //     }
    //   }
    // });
    // _notifySub = _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
    //   setState(() {
    //     // Convert bytes to string using UTF-8 encoding
    //     final asciiDecoder = AsciiDecoder();
    //     final result = asciiDecoder.convert(bytes);
    //
    //     // Check if the current bytes are different from the previous ones
    //     if (byteInput != null && byteInput!.toString() != bytes.toString()) {
    //       final message = result.split(",");
    //       print(message.length);
    //
    //       print("prebyte: $byteInput");
    //       print("current byte: $bytes");
    //       print("ssssssss");
    //       print("result: $result");
    //       print("ssssssss");
    //
    //       // Update the previous bytes to the current ones
    //       byteInput = bytes;
    //     } else if (byteInput == null) {
    //       print("prebyte is null");
    //       print("current byte: $bytes");
    //       print("ssssssss");
    //       print("result: $result");
    //       print("ssssssss");
    //
    //       byteInput = bytes;
    //     }
    //   });
    // });


  }

  Future<void> check() async {

    Map<Permission, PermissionStatus> status = await [
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
  Widget build(BuildContext context) {
    if (customIcon == null) {
       // Placeholder while loading
    }
     final origin = LatLng(originLat,originLng );
     final destination = LatLng(desLat,desLng);

     final CameraPosition home = CameraPosition(
       target: LatLng(originLat, originLng),
       zoom: 14,
     );
     final CameraPosition dest = CameraPosition(
       target: LatLng(desLat, desLng),
       zoom: 14,
     );

     List<LatLng> latlng = [
       LatLng(originLat,originLng ),
       LatLng(desLat,desLng),

     ];


    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      // appBar: AppBar(
      //   leading: Icon(Icons.location_pin),
      //   flexibleSpace: Column(
      //     children: [
      //       TextFormField(),
      //       TextFormField(),
      //     ],
      //   ),
      //
      //
      // ),
      body:
           Stack(
             children: [
               _isLoading == true ? Center(child: CircularProgressIndicator()):
               GoogleMap(
                 zoomControlsEnabled: false,
                mapType: MapType.normal,
                initialCameraPosition: home,
                onMapCreated: (controller)=> _mapController = controller,
                 markers: {
                   Marker(

                     markerId: MarkerId("origin"),
                     icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                     position: origin,
                   ),

                   Marker(
                     markerId: MarkerId("destination"),
                     icon: customIcon!,
                     position: destination,

                   ),
                 },

                 polylines: {

                   Polyline(
                     polylineId: PolylineId("path"),
                     points: latlng,
                     color: Colors.black,
                     width: 3,
                   ),



                 },


                         ),
               Positioned(
                   top: 0.0,
                   child: Container(
                     width: width,
                     height: height*0.17,
                     color: Color(0xFF323233),
                     child: Stack(
                       children: [
                         Positioned(
                           top: height*0.115,
                             left: width*0.05,

                             child: Icon(Icons.location_on_outlined,color: Colors.redAccent,size: width*0.06,)
                         ),
                         Positioned(
                             top: height*0.055,
                             left: width*0.05,

                             child: Icon(Icons.add_circle,color: Colors.blue,size: width*0.05,)
                         ),
                         Positioned(
                             top: height*0.085,
                             left: width*0.07,
                             child: Column(
                               children: [
                                 Icon(Icons.circle,color: Colors.white24,size: width*0.015,),
                                 SizedBox(height: height*0.001,),
                                 Icon(Icons.circle,color: Colors.white24,size: width*0.015,),
                                 SizedBox(height: height*0.001,),
                                 Icon(Icons.circle,color: Colors.white24,size: width*0.015,),
                               ],
                             )
                         ),
                         Positioned(
                             top: height*0.097,
                             left: width*0.83,

                             child: IconButton(onPressed: (){
                               setState(() {
                                  originLng =originLng;
                                  originLat = originLat;
                                  desLat =desLat;
                                  desLng = desLng;
                                  originController.text = "$originLat,$originLng";
                                  destController.text = "$desLat,$desLng";
                                  calculateDistance(originLng, originLat, desLat, desLng);

                               });
                             }, icon: Icon(Icons.compare_arrows,color: Colors.white60,size: width*0.06,))
                             //
                         ),
                         Positioned(
                             top: height*0.04,
                             left: width*0.83,

                             child: IconButton(onPressed: (){

                               setState(() {
                                 getCoordinates(originController.text, destController.text);

                               });
                             }, icon: Icon(Icons.search,color: Colors.white60,size: width*0.06,))
                           //
                         ),



                             Padding(
                               padding:  EdgeInsets.fromLTRB(width*0.13, height*0.04, 0.0, 0.0),
                               child: Column(
                                 children: [
                                   Container(
                                     width: width*0.7,
                                     height: height*0.05,
                                     decoration: BoxDecoration(
                                       border: Border.all(color: Colors.white24,width: 1.0),
                                       borderRadius: BorderRadius.circular(width*0.02),
                                     ),
                                     child: Padding(
                                       padding: EdgeInsets.all(height*0.01),
                                       child: TextField(

                                         controller: originController,
                                         keyboardType: TextInputType.number,
                                         style: const TextStyle(color: Colors.white,),
                                         cursorColor: Colors.blue,
                                         decoration: const InputDecoration(
                                             hintStyle: TextStyle(color: Colors.white24,),
                                             hintText: "Enter Origin here",
                                             border:UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent,width: 1.0)),
                                           enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                                           focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),

                                         ),


                                       ),
                                     ),
                                   ),
                                   SizedBox(
                                     height: height*0.01,
                                   ),
                                   Container(
                                     width: width*0.7,
                                     height: height*0.05,
                                     decoration: BoxDecoration(
                                       border: Border.all(color: Colors.white24,width: 1.0),
                                       borderRadius: BorderRadius.circular(width*0.02),
                                     ),
                                     child: Padding(
                                       padding: EdgeInsets.all(height*0.01),
                                       child: TextField(

                                         controller: destController,
                                         cursorColor: Colors.blue,
                                         keyboardType: TextInputType.number,
                                         style: const TextStyle(color: Colors.white,),
                                         decoration: const InputDecoration(
                                             hintStyle: TextStyle(color: Colors.white24,),
                                             hintText: "Enter Dest Here",
                                             border:UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent,width: 3.0)),
                                           enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                                           focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                                         ),


                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                             )


                       ],
                     ),

                   )),//AppBar

               Positioned(
                 top: height*0.18,
                 left: width*0.67,
                 child: FloatingActionButton(
                   key: Key("get_data"),
                   onPressed: () async{
                    _getCurrentLocation();
                   },
                   backgroundColor: Colors.blue,
                   child: Icon(Icons.download,color: Colors.white70,),
                 ),
               ),

               Positioned(
                 top: height*0.18,
                 left: width*0.83,
                 child: FloatingActionButton(
                   key: Key("bluetooth"),
                   onPressed: () async{
                     _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
                   },
                   backgroundColor: _found==true? Colors.green:Colors.blue,
                   child: _found==true? Icon(Icons.bluetooth,color: Colors.white70,):Icon(Icons.bluetooth_disabled,color: Colors.white,),
                 ),
               ),


               Positioned(
                 top: height*0.18,
                   left: width*0.02,
                   child: Container(
                 width: width*0.5,
                 height: height*0.065,

                     decoration: BoxDecoration(borderRadius: BorderRadius.circular(width*0.02),color: Colors.blueAccent,),
                     child:Row(
                       children: [
                         SizedBox(width: width*0.03,),
                         Text("Distance: $dis km",style: TextStyle(color: Colors.white),),
                       ],
                     ),
               )),//distance bar
               Positioned(
                 top: height*0.87,
                 left: width*0.842,
                 child: FloatingActionButton(
                   key: Key("dest"),
                   onPressed: (){
                     _mapController.animateCamera(CameraUpdate.newCameraPosition(dest));
                   },
                   backgroundColor: Colors.blue,
                   mini: true,
                   child: Icon(Icons.flag_outlined,color: Colors.white70,),
                 ),
               ),
             ],
           ),
      floatingActionButton: FloatingActionButton(
        key: Key("origin_"),
          onPressed: ()=>_mapController.animateCamera(CameraUpdate.newCameraPosition(home)),
        backgroundColor: Colors.blue,
        mini: true,
        child: Icon(Icons.center_focus_strong_outlined,color: Colors.white70,),
      ),

    );
  }
}

void getCoordinates(String origin,String dest){

  List<String> origin_coordinates = origin.split(",");
  List<String> dest_coordinates = dest.split(",");

   originLng = double.parse(origin_coordinates[1]);
   originLat = double.parse(origin_coordinates[0]);
   desLat = double.parse(dest_coordinates[0]);
   desLng = double.parse(dest_coordinates[1]);

   calculateDistance(originLng, originLat, desLat, desLng);


}
void calculateDistance(double originLng, double originLat,double desLat,double desLng) {
  const double radius = 6371; // Earth's radius in kilometers
  double lat1 = degreesToRadians(originLat);
  double lon1 = degreesToRadians(originLng);
  double lat2 = degreesToRadians(desLat);
  double lon2 = degreesToRadians(desLng);

  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  distance = radius * c;
  dis = distance.toStringAsFixed(3);
  print("distance in Km: $distance");
}

double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

