import 'dart:ffi' as ffi;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'customRaisedButton.dart';


class Body extends StatefulWidget {
  final int nChassis;

  const Body({Key? key, required  this.nChassis}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final List<String> pannes = [
    "L'allumage et électricité moteur (batterie, alternateur)",
    "Les plaquettes de frein ou garnissage",
    "La chaîne ou la courroie de distribution",
    "L'électronique du moteur",
    "Les disques ou tambours",
    "L'alimentation (pompe d'injection, injection)",
    "Le refroidissement du moteur",
    "Les éclairages (phares, feux, ampoules)",
    "Les pièces annexes (démarreur, débitmètre, etc.)",
    "Le chauffage et la climatisation"
  ];
  String? selectedPanne; // = "Les plaquettes de frein ou garnissage";
  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Pannes",
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Text(
                "lancer une pannes ",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              _dropDownMenueButtoon(size, pannes),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: "Description..",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(width: 1, color: Colors.black),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        width: 3, color: Color.fromRGBO(27, 146, 164, 1)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding: const EdgeInsets.all(14.0),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(height: 32),
              CustomRaisedButton(
                text: " Envoyer ",
                press: () async {
                  signIn();
                  int i = 0;
                  int numeroDeChassis =  widget.nChassis;
                  int idAm = await getAm(numeroDeChassis);
                  /*print(i);
                  print(FirebaseAuth.instance.currentUser!.uid);
                  String token =
                      await FirebaseAuth.instance.currentUser!.getIdToken();
                  print(token);*/
                  // if (idAm != -1) {
                  i = await envoyerPanne(
                      await FirebaseAuth.instance.currentUser!.getIdToken(),
                      FirebaseAuth.instance.currentUser!.uid,
                      selectedPanne!,
                      _controller.text,
                      "en cours",
                      formattedDateNow(),
                      formattedDateNow(),
                      getAm(1231313).toString(),
                      "0",
                      "Maintenance",
                      "0123456788",
                      "am@gmail.com");

                  //     }
                },
                color: const Color.fromRGBO(27, 146, 164, 0.7),
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropDownMenueButtoon(Size size, List<String> items) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        isExpanded: true,
        hint: Row(
          children: const [
            Icon(
              Icons.list,
              size: 16,
              color: Color.fromRGBO(27, 146, 164, 0.7),
            ),
            SizedBox(
              width: 4,
            ),
            Expanded(
              child: Text(
                'selectionner le type de la panne',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        items: items
            .map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ))
            .toList(),
        value: selectedPanne,
        onChanged: (value) {
          setState(() {
            selectedPanne = value as String;
          });
        },
        icon: const Icon(
          Icons.arrow_forward_ios_outlined,
        ),
        iconSize: 14,
        iconEnabledColor: const Color.fromRGBO(27, 146, 164, 0.7),
        iconDisabledColor: const Color.fromRGBO(27, 146, 164, 0.7),
        buttonHeight: 50,
        buttonWidth: size.width * 0.9,
        buttonPadding: const EdgeInsets.only(left: 14, right: 14),
        buttonDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black26,
          ),
          color: Colors.white,
        ),
        buttonElevation: 1,
        itemHeight: 40,
        itemPadding: const EdgeInsets.only(left: 14, right: 14),
        dropdownMaxHeight: size.height * 0.4,
        dropdownWidth: size.width * 0.9,
        dropdownPadding: null,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        dropdownElevation: 8,
        scrollbarRadius: const Radius.circular(40),
        scrollbarThickness: 6,
        scrollbarAlwaysShow: true,
        //  offset: const Offset(-10, 0),
      ),
    );
  }

  static Future<int> envoyerPanne(
      String token,
      String id_sender,
      String objet,
      String descriptif,
      String etat,
      String date_debut,
      String date_fin,
      String id_am,
      String etat_avancement,
      String type_tache,
      String numero_chassis,
      String email) async {
    final response = await http.post(
      Uri.parse(
          'https://autotek-server.herokuapp.com/gestionpannes/ajouter_panne/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "token": token,
        "id_sender": id_sender,
        "objet": objet,
        "descriptif": descriptif,
        "etat": etat,
        "date_debut": date_debut,
        "date_fin": date_fin,
        "id_am": "CRivUqM8fZZ9I6Iwv34qwlAdXOe2", // id_am,
        "etat_avancement": etat_avancement,
        "type_tache": type_tache,
        "numero_chassis": numero_chassis,
        "email": email
      }),
    );
    if (response.statusCode == 200) {
      print("tout va bien");
      return 1;
    } else {
      print("tout va mal");
      print(response.statusCode);
      return -1;
    }
  }

  static String formattedDateNow() {
    var now = DateTime.now();
    var formatter = DateFormat("yyyy-MM-dd");
    String formattedDate = formatter.format(now);
    return formattedDate; // 2016-01-25
  }
}

class AmId {
  int? idAm;
  AmId({idAm}) {
    idAm = idAm;
  }

  factory AmId.fromJson(Map<String, dynamic> json) => AmId(idAm: json["id_am"]);
}

Future<int> getAm(int numChassis) async {
  int id = -1;
  String _url =
      'https://autotek-server.herokuapp.com/flotte/detail_vehicule/num_chassis/';
  final response = await http.get(Uri.parse(_url + numChassis.toString()));
  if (response.statusCode == 200) {
    AmId idAm = AmId.fromJson(jsonDecode(response.body));
    if (idAm.idAm != null) {
      id = idAm.idAm!;
    }
  }
  return id;
}

Future<void> signIn() async {
  try {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: "nawel@esi.dz", password: "123456");
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      throw Exception('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      throw Exception('Wrong password provided for that user.');
    }
  }
}

//nrexcuperer la valeur ta3
