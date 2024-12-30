import 'package:flutter/material.dart';

import 'options_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_connections/singleton_firestore.dart';
import 'firebase_connections/singleton_auth.dart';

import 'session_data/session_details.dart';
import 'session_data/building_details.dart';

import 'custom_widgets/cf_button.dart';
import 'custom_widgets/cf_input.dart';

import 'package:logger/logger.dart';
import 'custom_logger.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController _emailInputController = TextEditingController();
  final TextEditingController _passwordInputController =
      TextEditingController();
  final FirebaseAuth _auth = AuthenticationService().firebaseAuth;
  final FirebaseFirestore _firestore = FirestoreService().firestore;

  final Logger logger = Logger(printer: CustomPrinter("LoginPage"));

  void showEnteredDetails() {
    logger.i("Email Address : ${_emailInputController.text}");
    logger.i("Password : ${_passwordInputController.text}");
  }

  Future<void> loadBuildingFloorNames(String institutionID) async {
    try {
      List<String> buildings = [];
      List<String> floors = [];

      QuerySnapshot institutionSnapshot = await _firestore
          .collection('institution_buildings')
          .where('institution_id', isEqualTo: institutionID)
          .get();

      for (QueryDocumentSnapshot doc in institutionSnapshot.docs) {
        String institutionDocName = doc.id;
        //print("docname : " + institutionDocName);

        QuerySnapshot buildingSnapshot = await _firestore
            .collection('institution_buildings')
            .doc(institutionDocName)
            .collection('buildings')
            .get();

        for (QueryDocumentSnapshot doc in buildingSnapshot.docs) {
          String buildingDocName = doc.id;
          Map<String, dynamic> building = doc.data() as Map<String, dynamic>;
          //print('building_name : ' + building['building_name']);
          buildings.add(building['building_name']);

          QuerySnapshot floors_snapshot = await _firestore
              .collection('institution_buildings')
              .doc(institutionDocName)
              .collection('buildings')
              .doc(buildingDocName)
              .collection('floors')
              .get();

          for (QueryDocumentSnapshot doc in floors_snapshot.docs) {
            Map<String, dynamic> floor = doc.data() as Map<String, dynamic>;
            //print('floor_name : ' + floor['floor_name']);
            floors.add(floor['floor_name']);
          }
        }
      }

      BuildingDetails.buildings = buildings;
      BuildingDetails.floors = floors;
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailInputController.text,
        password: _passwordInputController.text,
      );
      print(_auth.currentUser?.uid);

      String currentUserID = _auth.currentUser!.uid;
      print(currentUserID);

      QuerySnapshot snapshot1 = await FirestoreService()
          .firestore
          .collection("institution_members")
          .where("id", isEqualTo: currentUserID)
          .limit(1)
          .get();

      for (QueryDocumentSnapshot doc in snapshot1.docs) {
        Map<String, dynamic> member = doc.data() as Map<String, dynamic>;
        SessionDetails.email = member['email_id'];
        SessionDetails.id = _auth.currentUser!.uid;
        SessionDetails.institution_id = member['institution_id'];
        SessionDetails.name = member['name'];
      }

      print('before loading');
      await loadBuildingFloorNames(SessionDetails.institution_id);
      print('User signed in');
    } catch (e) {
      print('Failed to sign in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage('assets/images/CampusFindLogo.png'),
              width: 200,
            ),
            const SizedBox(height: 60),
            CampusFindInput(
              width: 300,
              controller: _emailInputController,
              labelText: "Email Address",
            ),
            CampusFindInput(
              width: 300,
              controller: _passwordInputController,
              obscureText: true,
              labelText: "Password",
            ),
            const SizedBox(height: 20),
            CampusFindButton(
                label: "Login",
                onPressed: () async {
                  await signIn();
                  showEnteredDetails();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AppOptions()));
                })
          ],
        )));
  }
}
