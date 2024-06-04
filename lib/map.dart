import 'dart:async';
import 'dart:math';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_logger/simple_logger.dart';
import 'communication_handler.dart';


double originLng =80.558137;
double originLat = 7.1654932;
double desLat =7.175489;
double desLng = 80.558137;
double distance = 0;
String dis = "";
String deviceId = "";
Set<Polyline> _polylines = {};
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  SimpleLogger logger = SimpleLogger();
  CommunicationHandler? communicationHandler;
  bool isScanStarted = false;
  bool isConnected = false;
  List<DiscoveredDevice> discoveredDevices = List<DiscoveredDevice>.empty(growable: true);
  String connectedDeviceDetails = "";
  final flutterReactiveBle = FlutterReactiveBle();
  late GoogleMapController _mapController ;
  TextEditingController originController = TextEditingController();
  TextEditingController destController = TextEditingController();

   @override
  void initState() {
     check();
    // TODO: implement initState
    super.initState();
  }

  void startScan() {
    setState(() {
      isScanStarted = true;
      discoveredDevices.clear();
    });
    communicationHandler ??= CommunicationHandler();
    communicationHandler?.startScan((scanDevice) {
      logger.info("Scan device: ${scanDevice.name}");
     // var device = discoveredDevices.firstWhere((val) => val.id == scanDevice.id, );
      if (!discoveredDevices.any((val) => val.id == scanDevice.id) ) {
        logger.info("Added new device to list: ${scanDevice.name}");
        setState(() {
          discoveredDevices.add(scanDevice);
        });
      }else{
        logger.info("discoveredDevices.first");

        // setState(() {
        //   discoveredDevices.add(scanDevice);
        // });
      }
    });


  }

  Future<void> stopScan() async {
    await communicationHandler?.stopScan();
    setState(() {
      isScanStarted = false;
    });
  }

  Future<void> connectToDevice(DiscoveredDevice selectedDevice) async {
    await stopScan();
    communicationHandler?.connectToDevice(selectedDevice, (isConnected) {
      this.isConnected = isConnected;
      if (isConnected) {
        logger.info("connected to $selectedDevice");
        connectedDeviceDetails = "Connected Device Details\n\n$selectedDevice";
      } else {
        logger.info("not connected");
        connectedDeviceDetails = "";
      }
      setState(() {
        connectedDeviceDetails;
      });
    });
  }


  @override
  void dispose() {
    // TODO: implement dispose
    _mapController.dispose();
    super.dispose();
  }



  Future<void> check() async {

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.bluetoothAdvertise,
    ].request();

    logger.info("PermissionStatus -- $statuses");

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
                     icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                     position: destination,

                   ),
                 },
                 polylines: {
                   Polyline(
                     polylineId: PolylineId("path"),
                     points: latlng,
                     color: Colors.black,
                     width: 3,
                   )



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
                                  originLng =80.558137;
                                  originLat = 7.1654932;
                                  desLat =7.175489;
                                  desLng = 80.558137;
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
                 top: height*0.25,
                   left: width*0.235,
                   child:  Container(
                     width: width*0.6,
                     height: height*0.6,
                     color: Colors.redAccent,
                     child: Column(
                       children: [
                         Center(
                           child: TextButton(
                             onPressed: () {
                               isScanStarted ? stopScan() : startScan();
                             },
                             child: Text(isScanStarted ? "Stop Scan" : "Start Scan",style: TextStyle(color: Colors.white),),
                           ),
                         ),
                         SizedBox(

                           height: height*0.5,
                           width: width*0.6,
                           child: ListView.builder(
                               padding: const EdgeInsets.all(3),
                               itemCount: discoveredDevices.length,
                               itemBuilder: (BuildContext context, int index) {
                                 return Padding(
                                   padding: const EdgeInsets.all(5),
                                   child: Container(
                                     height: 60,
                                     width: 60,
                                     color: Colors.greenAccent,
                                     child: Center(
                                         child: TextButton(
                                           child: Text(discoveredDevices[index].name),
                                           onPressed: () {
                                             logger.info(discoveredDevices[index].name+ "fuck");
                                             DiscoveredDevice selectedDevice = discoveredDevices[index];
                                             connectToDevice(selectedDevice);
                                           },
                                         )),
                                   ),
                                 );
                               }),
                         ),

                       ],
                     ),
                   ),

                   // FloatingActionButton(
                   //   onPressed: (){
                   //    startScan();
                   //     setState(() {
                   //
                   //       // flutterReactiveBle.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
                   //       //   //save the device id to a variable
                   //       //   deviceId = device.id;
                   //       //   print(deviceId);
                   //       // });
                   //     });
                   //
                   //
                   //
                   //   },
                   //   backgroundColor: Colors.blueGrey,
                   //   child: Icon(Icons.bluetooth_disabled,color: Colors.white70,),
                   // ),
               ),//bluetooth
               Positioned(
                 top: height*0.18,
                 left: width*0.67,
                 child: FloatingActionButton(
                   onPressed: (){},
                   backgroundColor: Colors.blue,
                   child: Icon(Icons.download,color: Colors.white70,),
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

