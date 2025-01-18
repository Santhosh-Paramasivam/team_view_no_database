import 'package:flutter/material.dart';

import 'search_members_page.dart';
import 'set_location_page.dart';

import 'package:logger/logger.dart';
import 'custom_logger.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_connections/singleton_auth.dart';

import 'login_page.dart';

import 'session_data/session_details.dart';
import 'custom_utils/string_shortener.dart';

import 'custom_widgets/cf_login_input.dart';
import 'custom_widgets/cf_status_input.dart';

import 'firebase_connections/singleton_firestore.dart';

import 'firebase_connections/firestore_error_messages.dart';
import 'firebase_connections/auth_error_messages.dart';

import 'custom_widgets/cf_toast.dart';

class CampusFindDrawer extends StatefulWidget {
  const CampusFindDrawer({super.key});

  @override
  State<CampusFindDrawer> createState() => _CampusFindDrawerState();
}

class _CampusFindDrawerState extends State<CampusFindDrawer> {
  final TextEditingController statusFieldController = TextEditingController();

  final Logger logger = Logger(printer: CustomPrinter("CampusFindDrawer"));

  final FirebaseAuth _auth = AuthenticationService().firebaseAuth;
  bool updateStatus = false;

  Future<void> signOut() async {
    SessionDetails.clearSessionDetails();
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      logger.e("Authentication Error : [${e.code}] [${e.credential}] ${e.message}");
      putToast("Error : ${AuthUserErrorMessages.errorCodeTranslations[e.code]}");
    }
    logger.i("User Logged Out");
  }

  Future<void> setStatus(String newStatus) async {
    try {
      await FirestoreService()
          .firestore
          .collection('institution_members')
          .doc(SessionDetails.userDocID)
          .update({'status': newStatus});
    } on FirebaseException catch (e) {
      putToast(
          "Error Updating Location : ${FirestoreUserErrorMessages.errorCodeTranslations[e.code]}");
      logger.e("${e.code} ${e.message}");
    }
  }

  Widget buildDrawer(BuildContext context) {
    return SizedBox(
        height: 80,
        child: DrawerHeader(
            margin: const EdgeInsets.all(0),
            padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
            child: Column(children: <Widget>[
              Row(children: <Widget>[
                const SizedBox(width: 5),
                const Icon(Icons.person),
                const SizedBox(width: 13),
                Text(SessionDetails.name)
              ]),
              updateStatus
                  ? Column(children: <Widget>[
                      const SizedBox(
                        height: 5,
                      ),
                      CampusFindStatusInput(
                          labelText: SessionDetails.status,
                          controller: statusFieldController,
                          width: 250,
                          height: 36,
                          fontSize: 14,
                          onPressed: () {
                            setState(() {
                              SessionDetails.status = statusFieldController.text;
                              setStatus(statusFieldController.text);
                              logger.d("Updated status");
                              updateStatus = false;
                            });
                          })
                    ])
                  : Row(children: [
                      const SizedBox(
                        width: 5,
                      ),
                      Text("Status : ${stringShortener(SessionDetails.status, 16)}"),
                      SizedBox(
                          height: 30,
                          width: 30,
                          child: IconButton(
                              padding: const EdgeInsets.all(0),
                              iconSize: 15,
                              onPressed: () {
                                setState(() {
                                  updateStatus = true;
                                });
                              },
                              icon: const Icon(Icons.edit)))
                    ]),
            ])));
  }

  Widget buildDrawerFooter(BuildContext context) {
    return Align(
        alignment: FractionalOffset.bottomCenter,
        child: Column(children: <Widget>[
          const Divider(height: 1),
          ListTile(
            minTileHeight: 50,
            leading: const Icon(Icons.logout),
            title: const Text("Log Out"),
            onTap: () {
              signOut();
              Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
            },
          )
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: <Widget>[
            Expanded(
                child: ListView(children: <Widget>[
              buildDrawer(context),
              ListTile(
                leading: const Icon(Icons.search),
                minTileHeight: 48,
                title: const Text("Search members"),
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const MemberSearchPage()));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.place),
                minTileHeight: 48,
                title: const Text("View Venues"),
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const LocationSetPage()));
                },
              ),
              const Divider(height: 1),
            ])),
            buildDrawerFooter(context)
          ],
        ));
  }
}
