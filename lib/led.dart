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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:battery_plus/battery_plus.dart';

import 'bndbox.dart';
import 'camera.dart';
import 'main.dart';
import 'models.dart';
import 'package:pausable_timer/pausable_timer.dart';
import 'package:weather/weather.dart';
import 'panne.dart';



final scaffoldKey = GlobalKey<ScaffoldState>();

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


  String scriptOrCam ="";

  var _battery = Battery();


  List<dynamic> _recognitions = [];
  int _imageHeight = 0;
  int _imageWidth = 0;
  String _model = "";

  String _numeroDeChassis = "";

  bool estLouee =false;





  WeatherFactory wf = new WeatherFactory("c41339e68946f5987cb29b5d10661c19");






  bool ignorerPanneau = false ;



  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = <_Message>[];
  String _messageBuffer = '';

  final TextEditingController textEditingController =
  new TextEditingController();


  final TextEditingController textController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;

  bool isDisconnecting = false;

  @override
  initState(){
    super.initState();

    /*
    demarrerVehicule();
    arretClient();
    */


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


  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    onSelect(ssd);

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
      key:scaffoldKey,
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting chat to ' + widget.server!.name! + '...')
              : isConnected
              ? Text('Live chat with ' + widget.server!.name!)
              : Text('Chat log with ' + widget.server!.name!))),
      body: SafeArea(
        child: (scriptOrCam == "") ? choice() : (scriptOrCam == "script") ? script(list) : automatic(),
      ),
    );
  }


  //Widget du Mode script
  Widget script(List<Row> list){
    return Column(
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
        )
      ],
    );
  }


  //Widget pour choisir entre le mode script et le mode automatique
  Widget choice(){
    return  Column(
        children: [
        Text("Choisissez le type d'execution"),
    MaterialButton(child: Text("Script"),onPressed: () => setState(() {
      scriptOrCam = "script";
    })),
          MaterialButton(child: Text("auto"),onPressed: () async {
    _numeroDeChassis = textController.text;
    if(_numeroDeChassis != ""){
    var collection = FirebaseFirestore.instance.collection('CarLocation');
    var docSnapshot = await collection.doc(_numeroDeChassis).get();
    if (docSnapshot.exists) {
      int batteryLevel = 50;


      _requestPermission();
      setTemperature();

      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );

      StreamSubscription<Position> positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
              (Position? position) async {

                batteryLevel = await _battery.batteryLevel;
                log("batttery"+ batteryLevel.toString());
            await collection.doc(_numeroDeChassis).set({
              "latitude":position!.latitude,
              "longitude":position!.longitude,
              "vitesse" : position!.speed,
              "batterie" : batteryLevel
            },SetOptions(merge : true));
            print(position == null ? 'Unknown' : '${position.latitude.toString()}, ${position.longitude.toString()}');
          });





      setState(() {
        scriptOrCam = "auto";
      });
    // Call setState if needed.


      demarrerVehicule();
      arretClient();

    }else{
    scaffoldKey.currentState!.showSnackBar(const SnackBar(content: Text("Numero de chassis erroné")));
    }
    }else{
    scaffoldKey.currentState!.showSnackBar(const SnackBar(content: Text("Veuillez remplir le numero de chassis")));
    }





    }),
    Container(
      height: 30,
      color: Colors.white,

      margin: const EdgeInsets.only(left: 16.0 , right: 16.0),
    child:
    TextField(
        keyboardType: TextInputType.multiline,
        maxLines: null,
        style: const TextStyle(fontSize: 15.0 , color: Colors.black),
        controller: textController,
        decoration: InputDecoration.collapsed(
          filled: true,
        fillColor: Colors.white,
        hintText: 'Numero de chassis',
        hintStyle: const TextStyle(color: Colors.grey),
        ),
        enabled: true, // is connected
        ),
    )

    ],
    );
  }


  //Widget du mode automatique
  Widget automatic(){return
    SizedBox(child:Stack(
      children: [

        Camera(
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
                    _model),
      Positioned(child:  MaterialButton(

        child: Text("pannes"),
        onPressed:() => {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                int nChassis = int.parse(_numeroDeChassis);
                print("numero de chassis $nChassis");
                return Body(nChassis :nChassis );
              },
            ),
          )
        },
      ) , bottom: 50),

      ],
    ),height: 500,width: 500,);}

  //Converti les données reçu depuis bluetooth (binaire brut) vers une chaine de charactère
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
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }


  //Prend en entrée un script et l'envoie sous forme de message compréhensible par la voiture
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

      _sendMessage("#");
      for (var i = 0 ; i < arrayOfCommandsCompiled.length ; i++) {

        log('data:' + arrayOfCommandsCompiled[i] + ' duration:'+arrayOfDuration[i].toString() + ' arg:'+arrayOfarguments[i].toString());
        _sendMessage(arrayOfCommandsCompiled[i]);



            await Future.delayed(Duration(milliseconds: arrayOfDuration[i]));

      }
      _sendMessage("#");

    }

  }

  // Converti les unités du script vers ( metres et degrés ) vers en secondes ( ex avancer 2m -> avancer pendant 10 secondes  , tourner 50° -> tourner 5 secondes )
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
          scaffoldKey.currentState!.showSnackBar(SnackBar(content: Text(str)));

          return [str];
      }
    }
    return arrayOfDuration;
  }

  // S'assure que tout les mot présent dans le script en entrée apartiennent au languages
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
          log('str');
          return [str];
      }
    }
    return res;
  }


  /*
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
*/
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

  // Cette fonction charge le model depuis le stockage
  // Vers un objet model en memoire centrale
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


  // Cette fonction est appelé pour selectionr quel model utiliser
  onSelect(model) {
    setState(() {
      _model = model;
    });
    loadModel();
  }


  //Cette fonction est appelé quelques secondes aprés la detection d'un panneau
  //Pour signaler qu'on a depassé le panneau detecté
  // Et que nous devons continuer a traiter les nouvelle detection
  void handleTimeout(String panneau) {  // callback function
    ignorerPanneau = false;
    log("timed out $panneau");
  }





  // Cette fonction est appelé a chaque foie que le model de machine learning
  // Finit de traiter une image de la camera
  //Elle execute la les instruction associé a la detection de chaque panneau
  //Elle affiche les carré bleu sur l'ecran de la camera là ou le panneau est detecté

  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
    if(_recognitions.length > 0) {

      if(!ignorerPanneau){
        log("panneau detecte");

        // Quand on detecte un panneau dans une frame
        // On ignore la detection des panneau pendant quelques secondes
        // Parce qu'il s'agit du même panneau detecté plusieurs foies
        ignorerPanneau = true;
        Future.delayed(const Duration(milliseconds: 4000), () {

        handleTimeout(_recognitions[0]["detectedClass"].toString());

        });


        if(_recognitions.toString().contains("crosswalk")){
        arretPanneau();
        log("crosswalk");
        }
        if(_recognitions[0]["detectedClass"].toString().contains("speed")){
          _sendMessage("D");
          log("Decelerer");
        }
        if(_recognitions[0]["detectedClass"].toString().contains("main road")){
          _sendMessage("A");
          log("Accelerer");
        }
        if(_recognitions.toString().contains("stop")){
          _sendMessage("S");
          log("Stop");

          Future.delayed(const Duration(milliseconds: 2000), () {
            _sendMessage("F");
            log("Continuer apres s'etre arreté 2 seconed au panneau");
          });

        }

      }



      log('_recognitions.length > 0' + _recognitions.toString());


    };
  }


  //Cette fonction demande la permission pour utiliser la geolocaliation
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


  // Cette fonction initialise les valeur sur firebase relative au vehicule.
  void demarrerVehicule() async {
    print("demarrer vehicule est execute");
    var db = FirebaseFirestore.instance;
    final docRef =
    db.collection('CarLocation').doc(_numeroDeChassis);
    docRef.snapshots().listen(
          (event) {
        print("current data Demarrer: ${event.data()}");
        // si  deverrouiller est vrai
        if (event["loue"] && !event["arrive"]) {
          print("doc snapshot demarrer vehicule");
          estLouee = true;
          //Demarrer le vehicule : LOcataire a fait une demande
          _sendMessage("F");

        }
      },
      onError: (error) => print("Listen failed: $error"),
    );
  }


  //Cette fonction est executé quand un panneau "cross walk" est detecté ,
  // Elle arrête la voiture pour recupérer un client
  //On assume que le client est entrain d'attendre la voiture au niveau de ce panneau
  void arretPanneau() async {
    print("arretp1 "+estLouee.toString());
    if (true) {


      print("arret panneau est execute");
      var db = FirebaseFirestore.instance;
      final docRef =
      db.collection('CarLocation').doc(_numeroDeChassis);

      _sendMessage("S");

      print("stop envoye arrive mit a true");
      await docRef.set({
        "arrive": true
      }, SetOptions(merge: true));


      docRef.snapshots().listen(
            (event) async {

          print("current data arretPanneau: ${event.data()}");
          // si  deverrouiller est vrai
          if (["nom_locataire"] != "") {
            print("arret panneau flagooo");

            //Demarrer le vehicule : LOcataire a fait une demande
            var nom_locataire = event["nom_locataire"];

            _sendMessage("@${nom_locataire}@@@");


            print("arrive est mit a false      loue:" + event["loue"].toString() + "      locataire : " + event["nom_locataire"].toString());
            await docRef.set({
              "arrive": false
            }, SetOptions(merge: true));


            _sendMessage("F");
          }
        },
        onError: (error) => print("Listen failed: $error"),
      );
    }
  }


  // est appelé quand le client veut descendre du vehicule
  // Il fait un appel depuis son application sur son telephone
  void arretClient() async{
    print("arret client est executé");
    var db = FirebaseFirestore.instance;
    final docRef =
    db.collection('CarLocation').doc(_numeroDeChassis);
    docRef.snapshots().listen(
          (event) {
            print("doc snapshot arret client");

            print("current data arretClient: ${event.data()}");
        // si  deverrouiller est vrai
        if (!event["loue"] && event["arrive"]) {

          print("arret client flagoooo");

          estLouee = false;
          //Demarrer le vehicule : LOcataire a fait une demande
          _sendMessage("S");

        }
      },
      onError: (error) => print("Listen failed: $error"),
    );


  }



  // Cette fonction fait une requete vers l'api WEATHERAPI , pour recupere la temperature au coordonée de la voiture
  //Puis insère cette valeur dans la base de donnée
  void setTemperature() async {
    var collection = FirebaseFirestore.instance.collection('CarLocation');
    var docSnapshot = await collection.doc(_numeroDeChassis).get();
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    var position =await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    Weather w = await wf.currentWeatherByLocation(position.latitude, position.longitude);
    var temperature = w.temperature!.celsius!;

    await collection.doc(_numeroDeChassis).set({
      "temperature":temperature
    },SetOptions(merge : true));

  }




}

