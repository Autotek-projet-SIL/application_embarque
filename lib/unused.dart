/*
void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
    if (mounted) {
    setState(() => _hasPermissions = status == PermissionStatus.granted);
    }
    });
    }
Widget _buildManualReader() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: <Widget>[
        ElevatedButton(
          child: Text('Read Value'),
          onPressed: () async {
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






            _buildManualReader(),
             _buildPositionReader(),


        MaterialButton(onPressed: () => {
          if(currentBearing == 0 ){initcurrentBearing()},
          log('data:'+ _traductionListePoints(arrayOfLatitude,arrayOfLongetudes).toString() ),

        })



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
*/

/*
void initcurrentBearing() async{
  tmp = await FlutterCompass.events!.first;
  currentBearing = tmp.heading!;
}
*/

/*
Future  td(double angle) async{
  tmp = await FlutterCompass.events!.first;
  log('tmp data:'+ tmp.heading.toString() );

  var a = true;

  double startBearing = tmp.heading!;
  double endbearing = ((startBearing+angle+180) % 360) - 180 ;


  while(a){
    tmp = await FlutterCompass.events!.first;

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

    log('diff' + ((((tmp.heading! - endbearing + 540) % 360) - 180)).toString());
    if(((((tmp.heading! - endbearing + 540) % 360) - 180)  < 0)) {a = false ;return true;};
  };

  tmp = await FlutterCompass.events!.first;
  currentBearing = tmp.heading!;

}


  List<double> arrayOfLatitude = [0.0,1.0,0.0,0.2165157,0.2165158,1,58.2165157,42.2165557,22.2165857,72.2166157,12.2169157];
  List<double> arrayOfLongetudes = [0.0,1.0,0.0,0.8286838,0.8286839,1,44.8286838,11.825838,18.1285838,4.2325838,4.8225838];

*/
