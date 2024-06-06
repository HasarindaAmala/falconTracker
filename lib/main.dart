import 'package:falcon/blootooth.dart';
import 'package:falcon/map.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const LoadingScreen());
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirstPage(),
    );
  }
}
class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Image.asset("images/back.png",width: width,height: height,fit: BoxFit.fill,),
          Positioned(
            top: height*0.9,
            left: width*0.67,
            child: TextButton(onPressed: (){
              print("pressed");
              Navigator.push(context,MaterialPageRoute(builder: (context)=>const MapPage()));
            }, child: Row(
              children: [
                Text("Get Start",style: TextStyle(color: Colors.white70,fontSize: width*0.04),),
                SizedBox(width: width*0.02,),
                Icon(Icons.arrow_forward,color: Colors.white70,size: width*0.05,),
              ],
            ),),
          )
        ],
      ),
    );
  }
}

