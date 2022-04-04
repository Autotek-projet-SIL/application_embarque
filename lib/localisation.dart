import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:location/location.dart' as loc;
import 'package:AutotekCar/Map.dart';
import 'package:permission_handler/permission_handler.dart';

class geolocalisation extends StatefulWidget {
  const geolocalisation() : super();

  @override
  State<geolocalisation> createState() => _geolocalisationState();
}

class _geolocalisationState extends State<geolocalisation> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    //check these settings and try to optimise them
    location.changeSettings(interval: 100,distanceFilter: 0.1 , accuracy: loc.LocationAccuracy.high);
    location.enableBackgroundMode(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('live location'),),
      body: Column(
        children: [
          TextButton(onPressed: (){
            _getLocation();
          }, child: Text('add my location')),
          TextButton(onPressed: (){
            _listenLocation();
          }, child: Text('enable live location')),
          TextButton(onPressed: (){
            _stopListening();
          }, child: Text('stop live location')),
          Expanded(
              child:StreamBuilder(
                stream: FirebaseFirestore.instance.collection('CarLocation').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot){
                  if (!snapshot.hasData){
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      itemBuilder: (context, index){
                        return ListTile(
                        //  title: Text(snapshot.data!.docs[index]['id'].toString()),
                          subtitle: Row(
                            children: [
                              Text(snapshot.data!.docs[index]['latitude'].toString()),
                              SizedBox(width: 20,),
                              Text(snapshot.data!.docs[index]['longitude'].toString()),
                            ],
                          ),
                          trailing: IconButton(
                            icon:Icon(Icons.directions),
                            onPressed: (){
                              Navigator.of(context).push(
                                  MaterialPageRoute(builder:(context)=> MyMap(snapshot.data!.docs[index].id))
                              );},
                          ),
                        );
                      }
                  );
                },
              )
          )
        ],
      ),
    );
  }

  _getLocation()async{
    try{
      final loc.LocationData _locationResult = await location.getLocation();
      await FirebaseFirestore.instance.collection('CarLocation').doc('car1').set({
        'latitude': _locationResult.latitude,
        'longitude':_locationResult.longitude,
        'id':'car1'
      },SetOptions(merge:true));
    }catch(e){

    }
  }

 Future<void> _listenLocation()async{
    _locationSubscription = location.onLocationChanged.handleError((onError){
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription= null;
      });

    }).listen((loc.LocationData currentlocation)async{
      await FirebaseFirestore.instance.collection('CarLocation').doc('car1').set({
        'latitude': currentlocation.latitude,
        'longitude':currentlocation.longitude,
        'id':'car1'
      },SetOptions(merge:true));
    });
  }

  _stopListening(){
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }
  _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('done');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}

