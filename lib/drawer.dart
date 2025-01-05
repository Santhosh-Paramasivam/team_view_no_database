import 'package:flutter/material.dart';

import 'search_members_page.dart';
import 'set_location_page.dart';

import 'package:logger/logger.dart';
import 'custom_logger.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_connections/singleton_auth.dart';

import 'login_page.dart';

class CampusFindDrawer extends StatelessWidget {
  final Logger logger = Logger(printer: CustomPrinter("CampusFindDrawer"));

  final FirebaseAuth _auth = AuthenticationService().firebaseAuth;

  CampusFindDrawer({super.key});

  Future<void> signOut() async {
    await _auth.signOut();
    logger.i("User Logged Out");
  }

  Widget buildDrawer(BuildContext context) {
    return const SizedBox(
        height: 50,
        child: DrawerHeader(
            margin: EdgeInsets.all(0),
            padding: EdgeInsets.all(0),
            child: Column(
              children: <Widget>[Text("Username")],
            )));
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
        backgroundColor: const Color(0xFFD9D9D9),
        child: Column(
          children: <Widget>[
            Expanded(
                child: ListView(children: <Widget>[
              buildDrawer(context),
              ListTile(
                leading: const Icon(Icons.person),
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
