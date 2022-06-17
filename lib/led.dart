import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:developer';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:servo_app/home.dart';
import 'package:tflite/tflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'bndbox.dart';
import 'camera.dart';
import 'main.dart';
import 'models.dart';
import 'package:pausable_timer/pausable_timer.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice? server;

  final List<CameraDescription>? cameras;

  const ChatPage({this.cameras , this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {

  bool isInterrupted = false;
  int debutInterruption = 0;
  int finInterruption = 0;
  String panneauActuel = "";
  int compteur = 0;
  String panneauExec = "";
  bool executerMaintenant = false;




  List<dynamic> _recognitions = [];
  int _imageHeight = 0;
  int _imageWidth = 0;
  String _model = "";



  Position? _position;
  Position? _currentPosition;
  double? _distance;

  List<double> arrayOfLatitude = [0.0,1.0,0.0,0.2165157,0.2165158,1,58.2165157,42.2165557,22.2165857,72.2166157,12.2169157];
  List<double> arrayOfLongetudes = [0.0,1.0,0.0,0.8286838,0.8286839,1,44.8286838,11.825838,18.1285838,4.2325838,4.8225838];




  double currentBearing = 0;
  var mySubscription;
  late CompassEvent tmp ;

  String panneauPrecedent = "";
  double confience = 1;



  bool _hasPermissions = false;
  CompassEvent? _lastRead;
  DateTime? _lastReadAt;

  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = <_Message>[];
  String _messageBuffer = '';

  final TextEditingController textEditingController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;

  bool isDisconnecting = false;

  @override
  initState(){
    super.initState();


    BluetoothConnection.toAddress(widget.server!.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
/*

    FirebaseFirestore.instance
        .collection('CarLocation')
        .doc('car1')
        .snapshots(includeMetadataChanges: true)
        .listen((DocumentSnapshot documentSnapshot) {
      var newdest = documentSnapshot.data()!["new_dest"];
      if (newdest) {
        //get the lat and long and actual position and send them to traductionlistpoint

        //set newdest to false

      }
    }*/

  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = null;
    }
    super.dispose();
  }

  double _value = 90.0;
  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    onSelect(ssd);
    /*

    return
      Scaffold(
        body
            : Stack(
          children: [

            Camera(
              cameras,
              _model,
              setRecognitions,

            ),
            BndBox(
                _recognitions == null ? [] : _recognitions,
                math.max(_imageHeight, _imageWidth),
                math.min(_imageHeight, _imageWidth),
                screen.height,
                screen.width,
                _model),
          ],
        ),
      );
*/
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                    (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:
                _message.whom == clientID ? Colors.greenAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting chat to ' + widget.server!.name! + '...')
              : isConnected
              ? Text('Live chat with ' + widget.server!.name!)
              : Text('Chat log with ' + widget.server!.name!))),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100,),
            Row(
              children: <Widget>[

                Flexible(
                  child: Container(
                    height: 200,
                    color: Colors.white,

                    margin: const EdgeInsets.only(left: 16.0),
                    child: TextField(

                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: const TextStyle(fontSize: 15.0 , color: Colors.black),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: isConnecting
                            ? 'Wait until connected...'
                            : isConnected
                            ? 'Type your message...'
                            : 'Chat got disconnected',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      enabled: true, // is connected
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8.0),
                  child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: true // is connected
                          ? () => _sendMultipleMessages(textEditingController.text)
                          : null),
                ),
              ],
            ),
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: list),
            ),/*
            _buildManualReader(),
             _buildPositionReader(),*/
            SizedBox(child:Stack(
              children: [

                /*Camera(
                  cameras,
                  _model,
                  setRecognitions,

                ),
                BndBox(
                    _recognitions == null ? [] : _recognitions,
                    400,
                    400,
                    400,
                    400,
                    _model),*/
              ],
            ),height: 100,width: 100,),
            MaterialButton(onPressed: () => {
                if(currentBearing == 0 ){initcurrentBearing()},
                log('data:'+ _traductionListePoints(arrayOfLatitude,arrayOfLongetudes).toString() ),

            })

          ],
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
        if(_messageBuffer.contains("w")){
          finInterruption += 10000;
          print("aaaaaaaaaaaaaa");
        }
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  _sendMultipleMessages (String text) async{

    var speed = 200;
    var lines = text.split(new RegExp("\\r?\\n")).where((i) => i != "").toList();
    var splitArray = lines.map((e) => e.trim().split(" ")).toList();
    var arrayOfCommands = splitArray.map((e) => e.first).toList();
    var arrayOfarguments = splitArray.map((e) => e.length > 1 ? double.parse(e[1]) : 50).toList();
    var arrayOfDuration = _conversionToSeconds(arrayOfCommands, arrayOfarguments,speed);



    log('data:'+ arrayOfCommands.toString() );
    log('data:'+ arrayOfarguments.toString() );
    log('data:'+ arrayOfDuration.toString() );

    var arrayOfCommandsCompiled = _analyseLexicale(arrayOfCommands);


    log('data:'+ arrayOfCommandsCompiled.toString() );


    if(arrayOfCommandsCompiled[0].length > 1){
      log('data:'+ arrayOfCommandsCompiled[0] );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(arrayOfCommandsCompiled[0].length),
      ));
    }else {

      for (var i = 0 ; i < arrayOfCommandsCompiled.length ; i++) {

        log('data:' + arrayOfCommandsCompiled[i] + ' duration:'+arrayOfDuration[i].toString() + ' arg:'+arrayOfarguments[i].toString());
        _sendMessage(arrayOfCommandsCompiled[i]);


        if(arrayOfCommandsCompiled[i] == 'L'  ){await tg(arrayOfarguments[i].toDouble());}
        else if(arrayOfCommandsCompiled[i] == 'R'){await td(arrayOfarguments[i].toDouble());}
        else{
          int startTime = new DateTime.now().millisecondsSinceEpoch;
          var endTime;
          do{

            if(executerMaintenant){
              if(panneauExec == "stop"){
              _sendMessage("S");
              debutInterruption = new DateTime.now().millisecondsSinceEpoch;
              await Future.delayed(Duration(milliseconds: 3000));
              finInterruption = new DateTime.now().millisecondsSinceEpoch;
              _sendMessage("F");}
              if(panneauExec == "dont stop" || panneauExec == "no parking") {
                debutInterruption = new DateTime.now().millisecondsSinceEpoch;
                await Future.delayed(Duration(milliseconds: 7000));
                finInterruption = new DateTime.now().millisecondsSinceEpoch;
              }
              if(panneauExec == "speed limit 80" || panneauExec == "speed limit 60" ) {
                debutInterruption = new DateTime.now().millisecondsSinceEpoch;
                _sendMessage("A");
                finInterruption = new DateTime.now().millisecondsSinceEpoch;
              }
              if(panneauExec == "speed limit 40") {
                debutInterruption = new DateTime.now().millisecondsSinceEpoch;
                _sendMessage("D");
                finInterruption = new DateTime.now().millisecondsSinceEpoch;
              }


              executerMaintenant = false ;
              panneauExec = "";
              compteur = 0 ;
            }
            await Future.delayed(Duration(milliseconds: 500));

            endTime =  new DateTime.now().millisecondsSinceEpoch;
          }while((endTime - startTime) - (finInterruption - debutInterruption)  < arrayOfDuration[i]);
          log("temp  interrupt ${(finInterruption - debutInterruption)}" );
          log("Temp instruction ${(endTime - startTime) - (finInterruption - debutInterruption)}");





          debutInterruption = 0 ;
          finInterruption = 0 ;
          //await Future.delayed(Duration(milliseconds: arrayOfDuration[i]));

        }


      }
    }

  }



  List<dynamic> _conversionToSeconds(List<dynamic> arrayOfCommands , List<dynamic> arrayOfarguments , int speed){
    var arrayOfDuration = [];
    for(var i = 0 ; i < arrayOfCommands.length ; i++ ){
      switch (arrayOfCommands.elementAt(i)) {
        case 'STOP' : arrayOfDuration.add(arrayOfarguments[i]);
        break;
        case 'FORWARD' : arrayOfDuration.add(    ((-12.5*speed + 6000)*arrayOfarguments[i]).toInt()   );
        break;
        case 'BACKWARD' : arrayOfDuration.add(((-12.5*speed + 6000)*arrayOfarguments[i]).toInt());
        break;
        case 'LEFT' : arrayOfDuration.add((arrayOfarguments[i]*1000/90 ).toInt());
        break;
        case 'RIGHT': arrayOfDuration.add((arrayOfarguments[i]*1000/90 ).toInt());
        break;
        case 'ACCELERER': arrayOfDuration.add(50); speed = 240;
        break;
        case 'DECELERER': arrayOfDuration.add(50); speed = 200;
        break;
        case 'NORMALSPEED': arrayOfDuration.add(50); speed = 200;
        break;
        case 'RONDPOINT': arrayOfDuration.add(  (arrayOfarguments[i]*3500).toInt() );
        break;
        default:
          var str = 'Erreur a la ligne ${i+1} , "' +arrayOfCommands.elementAt(i) +'" n''appartient pas au langauage' ;
          return [str];
      }
    }
    return arrayOfDuration;
  }

  List<dynamic> _analyseLexicale(List<String> arrayOfCommands){
    var res = [];
    for(var i = 0 ; i < arrayOfCommands.length ;i++){
      switch (arrayOfCommands.elementAt(i)) {
        case 'STOP' : res.add('S');
        break;
        case 'FORWARD' : res.add('F');
        break;
        case 'BACKWARD' : res.add('B');
        break;
        case 'LEFT' : res.add('L');
        break;
        case 'RIGHT': res.add('R');
        break;
        case 'ACCELERER': res.add('A');
        break;
        case 'DECELERER': res.add('D');
        break;
        case 'NORMALSPEED': res.add('N');
        break;
        case 'RONDPOINT': res.add('P');
        break;
        default:
          var str = 'Erreur a la ligne ${i+1} , "' +arrayOfCommands.elementAt(i) +'" n''appartient pas au langauage' ;
          return [str];
      }
    }
    return res;
  }

  List<dynamic> _traductionListePoints(List<double> arrayOfLatitudes,List<double> arrayOfLongetudes ){
    var bearing = currentBearing;

    var arrayOfCommands = [];
    for(var i = 0 ; i < arrayOfLatitudes.length -1;i++){
      var secondBearing = Geolocator.bearingBetween(arrayOfLatitudes[i], arrayOfLongetudes[i],arrayOfLatitudes[i+1], arrayOfLongetudes[i+1]);

      if ((((bearing - secondBearing + 540) % 360) - 180) > 0) {
        arrayOfCommands.add( "LEFT "  +(((bearing - secondBearing + 540) % 360) - 180).toString());
        bearing = secondBearing;
      } else {
        arrayOfCommands.add( "RIGHT  "  +(-(((bearing - secondBearing + 540) % 360) - 180)).toString());
        bearing = secondBearing;
      }
      arrayOfCommands.add("FORWARD "+Geolocator.distanceBetween(arrayOfLatitudes[i], arrayOfLongetudes[i],arrayOfLatitudes[i+1], arrayOfLongetudes[i+1]).toString());
    }

    return arrayOfCommands;
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(utf8.encode(text + "\r\n") as Uint8List);
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Location Permission Required'),
          ElevatedButton(
            child: Text('Request Permissions'),
            onPressed: () {
              Permission.locationWhenInUse.request().then((ignored) {
                _fetchPermissionStatus();
              });
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            child: Text('Open App Settings'),
            onPressed: () {
              openAppSettings().then((opened) {
                //
              });
            },
          )
        ],
      ),
    );
  }

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => _hasPermissions = status == PermissionStatus.granted);
      }
    });
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        double? direction = snapshot.data!.heading;

        // if direction is null, then device does not support this sensor
        // show error message
        if (direction == null)
          return Center(
            child: Text("Device does not have sensors !"),
          );

          return Center(child: Text(direction.toString()),);


      },
    );
  }
  Widget _buildManualReader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          ElevatedButton(
            child: Text('Read Value'),
            onPressed: () async {
              var x = await tg(30);
              log(x.toString());
              final CompassEvent tmp = await FlutterCompass.events!.first;
              setState(() {
                _lastRead = tmp;
                _lastReadAt = DateTime.now();
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$_lastRead',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  Text(
                    '$_lastReadAt',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  void initcurrentBearing() async{
    tmp = await FlutterCompass.events!.first;
    currentBearing = tmp.heading!;
  }
  Future  td(double angle) async{
    tmp = await FlutterCompass.events!.first;
    log('tmp data:'+ tmp.heading.toString() );

    var a = true;

    double startBearing = tmp.heading!;
    double endbearing = ((startBearing+angle+180) % 360) - 180 ;


    while(a){
      tmp = await FlutterCompass.events!.first;
     // log('current bearing'+startBearing.toString() + 'second bearing ' + endbearing.toString());

      log('diff' + ((((tmp.heading! - endbearing + 540) % 360) - 180)).toString());
      if(((((tmp.heading! - endbearing + 540) % 360) - 180)  > 0)) {a = false ;return true;};
    };

    tmp = await FlutterCompass.events!.first;
    currentBearing = tmp.heading!;



 }

  Future  tg(double angle) async{
    tmp = await FlutterCompass.events!.first;
    log('tmp data:'+ tmp.heading.toString() );

    var a = true;

    double startBearing = tmp.heading!;
    double endbearing = ((startBearing-angle+180) % 360) - 180 ;


    while(a){
      tmp = await FlutterCompass.events!.first;
      //log('current bearing'+startBearing.toString() + 'second bearing ' + endbearing.toString());

      log('diff' + ((((tmp.heading! - endbearing + 540) % 360) - 180)).toString());
      if(((((tmp.heading! - endbearing + 540) % 360) - 180)  < 0)) {a = false ;return true;};
    };

    tmp = await FlutterCompass.events!.first;
    currentBearing = tmp.heading!;

  }

 _buildPositionReader()  {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          ElevatedButton(
            child: Text('Set point'),
            onPressed: () async {
              final tmpPos  =  await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
              setState(() {
                _position = tmpPos;
              });
            },
          ),
          ElevatedButton(
            child: Text('Get distance'),
            onPressed: () async {
              final tmpCurr = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
              setState(() {
                _currentPosition = tmpCurr;
                _distance = Geolocator.distanceBetween(_position!.latitude, _position!.longitude, _currentPosition!.latitude, _currentPosition!.longitude);
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ancre: '+_position.toString(),
                    style: Theme.of(context).textTheme.caption,
                  ),
                  Text(
                    'position ' + _currentPosition.toString(),
                    style: Theme.of(context).textTheme.caption,
                  ),
                  Text(
                    'distance ' + _distance.toString(),
                    style: Theme.of(context).textTheme.caption,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  loadModel() async {
    String res;
    switch (_model) {
      case yolo:
        res = (await Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt",
        ))!;
        break;

      case mobilenet:
        res = (await Tflite.loadModel(
            model: "assets/mobilenet_v1_1.0_224.tflite",
            labels: "assets/mobilenet_v1_1.0_224.txt"))!;
        break;

      case posenet:
        res = (await Tflite.loadModel(
            model: "assets/posenet_mv1_075_float_from_checkpoints.tflite"))!;
        break;

      default:
        res = (await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt"))!;
    }
    print(res);
  }

  onSelect(model) {
    setState(() {
      _model = model;
    });
    loadModel();
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
    if(_recognitions.length > 0) {
      if("crosswalk" == _recognitions[0]["detectedClass"].toString()){
      _sendMessage("D");
      log("Decelerer");
      }
      if(_recognitions[0]["detectedClass"].toString().contains("speed")){
        _sendMessage("A");
        log("Accelerer");

      }
      if("stop" == _recognitions[0]["detectedClass"].toString()){
        _sendMessage("S");
        log("Stop");
      }

      log('_recognitions.length > 0');
     log("Egalité des panneaux " + panneauActuel+" == " + _recognitions[0]["detectedClass"].toString() + (panneauActuel == _recognitions[0]["detectedClass"].toString()).toString());
      if(panneauActuel == _recognitions[0]["detectedClass"].toString())
      {compteur++;
      log('panneau qui se repete ,compteur $compteur');
        }
      else{
        panneauActuel = _recognitions[0]["detectedClass"].toString();
        compteur = 0;
        log("panneauActuel mis a jour: $panneauActuel");
      }

      if(compteur == 5 && panneauActuel != ""){
        panneauExec = panneauActuel;
        log("executer le panneau $panneauExec");
      }

      log((_recognitions[0]["detectedClass"]).toString());
    }else{
      if(panneauActuel == "")
        {
          log("on est plus sur qu'il n'y a plus de panneau compteur : $compteur");
          compteur++;
          if(compteur == 5 && panneauExec != "")
          {
            log('le panneau n\'est plus visible on l\'execute maintenant ');
            executerMaintenant = true;

            compteur = 0 ;

          }

        }
      else
      {
        log("pas de panneau compteur remis a zero");
        panneauActuel = "";
        compteur = 0;
      }


    };
  }








}