import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:team_view_no_database_windows/search_members_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_connections/singleton_firestore.dart';
import 'firebase_connections/singleton_auth.dart';

import 'session_data/session_details.dart';
import 'session_data/building_details.dart';

import 'custom_widgets/cf_button.dart';
import 'custom_widgets/cf_login_input.dart';

import 'package:logger/logger.dart';
import 'custom_logger.dart';

import 'global_config/global_config.dart';
import 'firebase_connections/auth_error_messages.dart';
import 'firebase_connections/firestore_error_messages.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController _emailInputController = TextEditingController();
  final TextEditingController _passwordInputController = TextEditingController();
  final FirebaseAuth _auth = AuthenticationService().firebaseAuth;
  final FirebaseFirestore _firestore = FirestoreService().firestore;

  final Logger logger =
      Logger(printer: CustomPrinter("LoginPage"), level: GlobalConfig.loggingLevel);

  void putToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.white,
        textColor: Colors.black,
        fontSize: 16.0);
  }

  Future<bool> loadBuildingFloorNames(String institutionID) async {
    List<String> buildings = [];
    List<String> floors = [];

    QuerySnapshot institutionSnapshot = await _firestore
        .collection('institution_buildings')
        .where('institution_id', isEqualTo: institutionID)
        .get();

    if (institutionSnapshot.docs.isEmpty) {
      putToast("Error : Institution not found");
      logger.e("No institution of the user's institution ID found");
      return false;
    }

    QueryDocumentSnapshot institutionBuildingsDetails = institutionSnapshot.docs[0];
    String institutionDocName = institutionBuildingsDetails.id;

    QuerySnapshot buildingSnapshot = await _firestore
        .collection('institution_buildings')
        .doc(institutionDocName)
        .collection('buildings')
        .get();

    if (buildingSnapshot.docs.isEmpty) {
      putToast("Error : Not buildings found in institution");
      logger.e("No buildings found for user's institution ID");
      return false;
    }

    for (QueryDocumentSnapshot buildingDetails in buildingSnapshot.docs) {
      String buildingDocName = buildingDetails.id;
      Map<String, dynamic> building = buildingDetails.data() as Map<String, dynamic>;
      logger.d('building_name ${building['building_name']}');
      buildings.add(building['building_name']);

      QuerySnapshot floorsSnapshot = await _firestore
          .collection('institution_buildings')
          .doc(institutionDocName)
          .collection('buildings')
          .doc(buildingDocName)
          .collection('floors')
          .get();

      if (floorsSnapshot.docs.isEmpty) {
        putToast("Error : No floors found in institution");
        logger.e("No floors found for user's institution ID");
        return false;
      }

      for (QueryDocumentSnapshot doc in floorsSnapshot.docs) {
        Map<String, dynamic> floor = doc.data() as Map<String, dynamic>;
        logger.i('floor_name : ${floor['floor_name']}');
        floors.add(floor['floor_name']);
      }
    }

    BuildingDetails.buildings = buildings;
    BuildingDetails.floors = floors;

    return true;
  }

  Future<bool> signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailInputController.text,
        password: _passwordInputController.text,
      );

      String currentUserID = _auth.currentUser!.uid;
      logger.d("Current UserID : $currentUserID");

      QuerySnapshot currentUser = await FirestoreService()
          .firestore
          .collection("institution_members")
          .where("id", isEqualTo: currentUserID)
          .limit(1)
          .get();

      if (currentUser.docs.isEmpty) {
        logger.e("No institution member found for the user in the database");
        putToast("Error : User not found");
        return false;
      }

      QueryDocumentSnapshot currentUserData = currentUser.docs[0];
      Map<String, dynamic> member = currentUserData.data() as Map<String, dynamic>;
      SessionDetails.email = member['email_id'];
      SessionDetails.userDocID = currentUser.docs[0].id;
      SessionDetails.id = _auth.currentUser!.uid;
      SessionDetails.institutionID = member['institution_id'];
      SessionDetails.name = member['name'];
      SessionDetails.rfidLocation = member['rfid_location'];
      SessionDetails.status = member['status'];


      logger.i("Before loading in floor names");
      bool buildingsLoading = await loadBuildingFloorNames(SessionDetails.institutionID);
      logger.i("Done loading floor names");

      return buildingsLoading;
    } on FirebaseAuthException catch (e) {
      logger.e("Authentication Error : [${e.code}] [${e.credential}] ${e.message}");
      putToast("Error : ${AuthUserErrorMessages.errorCodeTranslations[e.code]}");

      return false;
    } on FirebaseException catch (e) {
      logger.w("Firebase Exception : ${e.message} ${e.code}");
      putToast(
          "Warning : Unable to load maps, ${FirestoreUserErrorMessages.errorCodeTranslations[e.code]}");
      return false;
    } catch (e) {
      putToast("An unknown error occured : ${e.toString()}");
      logger.e("Uncaught Exception : ${e.toString()}");

      return false;
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
            CampusFindLoginInput(
              fontSize: 16,
              width: 300,
              height: 55,
              controller: _emailInputController,
              labelText: "Email Address",
            ),
            CampusFindLoginInput(
              fontSize: 16,
              width: 300,
              height: 55,
              controller: _passwordInputController,
              obscureText: true,
              labelText: "Password",
            ),
            const SizedBox(height: 20),
            CampusFindButton(
                label: "Login",
                onPressed: () async {
                  if (_passwordInputController.text.isEmpty || _emailInputController.text.isEmpty) {
                    putToast("Email and password can't be empty");
                    return;
                  }

                  if (_passwordInputController.text.length < 8) {
                    putToast("Password must be atleast 8 characters");
                    return;
                  }

                  bool authenticated = await signIn();
                  if (authenticated) {
                    _emailInputController.clear();
                    _passwordInputController.clear();

                    _emailInputController.dispose();
                    _passwordInputController.dispose();

                    logger.d(
                        "SessionDetails : ${SessionDetails.name} ${SessionDetails.id} ${SessionDetails.institutionID} ${SessionDetails.name}");

                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => const MemberSearchPage()));
                  }
                })
          ],
        )));
  }
}
