import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_connections/singleton_firestore.dart';
import 'firebase_connections/singleton_auth.dart';
import 'package:logger/logger.dart';
import 'custom_logger.dart';

class FirestoreCall extends StatelessWidget {
  final TextEditingController _emailInputController = TextEditingController();
  final TextEditingController _passwordInputController = TextEditingController();

  final FirebaseAuth _auth = AuthenticationService().firebaseAuth;
  final FirebaseFirestore _firestore = FirestoreService().firestore;
  final Logger logger = Logger(printer: CustomPrinter("LoginPage"));

  void queryUsers() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Firestore Testing")),
      body: Center(
          child: Row(
        children: [
          TextField(
            controller: _emailInputController,
          ),
          TextButton(onPressed: queryUsers, child: Text("Query Firestore")),
        ],
      )),
    );
  }
}
