import 'package:flutter/material.dart';
import 'search_members_page.dart';
import 'set_location_page.dart';
import 'firebase_connections/singleton_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'custom_logger.dart';
import 'package:logger/logger.dart';

// To remove
import 'drawer.dart';

class AppOptions extends StatelessWidget {
  AppOptions({super.key});

  final FirebaseAuth _auth = AuthenticationService().firebaseAuth;

  final Logger logger = Logger(printer: CustomPrinter("AppOptions"));

  Future<void> signOut() async {
    await _auth.signOut();
    logger.i("User Logged Out");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Options Menu"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Column(children: [
          MenuButton("Search members and venues", (context) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage()));
          }),
          MenuButton("Log Out", (context) {
            signOut();
            Navigator.pop(context);
          }),
          MenuButton("Set Location", (context) {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => const LocationSetPage()));
          }),
          // MenuButton("Drawer Page", (context) {
          //   Navigator.push(
          //       context, MaterialPageRoute(builder: (context) => CampusFindDrawerPage()));
          // }),
        ]));
  }
}

class MenuButton extends StatelessWidget {
  final String label;
  final void Function(BuildContext) onPressed;

  const MenuButton(this.label, this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: TextButton(
          style: const ButtonStyle(
              shape: WidgetStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ))),
          onPressed: () => this.onPressed(context),
          child: Text(
            this.label,
            style: const TextStyle(fontSize: 18, color: Colors.blue),
          )),
    );
  }
}
