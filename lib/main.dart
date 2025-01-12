import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const CampusFind());
}

class CampusFind extends StatelessWidget
{
  const CampusFind({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp
    (
        title: "CampusFind",
        theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
        home: LoginPage(),
        debugShowCheckedModeBanner: false,
    );
  }
}