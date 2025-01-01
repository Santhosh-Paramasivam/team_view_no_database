import 'package:flutter/material.dart';

import 'search_members_page.dart';
import 'set_location_page.dart';

import 'package:logger/logger.dart';
import 'custom_logger.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_connections/singleton_auth.dart';

import 'login_page.dart';

class CampusFindDrawer extends StatelessWidget {
  Logger logger = Logger(printer: CustomPrinter("CampusFindDrawer"));

  final FirebaseAuth _auth = AuthenticationService().firebaseAuth;

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
    return Container(
        child: Align(
            alignment: FractionalOffset.bottomCenter,
            child: Container(
                child: Column(children: <Widget>[
              Divider(),
              ListTile(
                title: Text("Log Out"),
                onTap: () {
                  signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                },
              )
            ]))));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
      children: <Widget>[
        Expanded(
            child: ListView(children: <Widget>[
          buildDrawer(context),
          ListTile(
            title: Text("Search members"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage()));
            },
          ),
          ListTile(
            title: Text("View Venues"),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const LocationSetPage()));
            },
          )
        ])),
        buildDrawerFooter(context)
      ],
    ));
  }
}
