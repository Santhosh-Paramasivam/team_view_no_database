import 'package:flutter/material.dart';
import 'account_details.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String username = 'santhosh123';
  String password = 'santhosh123';

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      appBar: AppBar
      (
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Login Page"),
      ),
      body: Center(child: Column
      (
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>
        [
          SizedBox
          (
            width: 320,
            height: 50,
            child: TextField
            (
              decoration: const InputDecoration
              (
                prefixIcon: Icon(Icons.person),
                labelText: 'Enter Username',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.zero))
              ),
              controller: this.usernameController
            ),
          ),
          SizedBox
          (
            width: 320,
            height: 50,
            child: TextField
            (
              decoration: const InputDecoration
              (
                prefixIcon: Icon(Icons.person),
                labelText: 'Enter Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.zero))
              ),
              controller: this.passwordController
            ),
          ),
          SizedBox
          (
            width: 320,
            height: 50,
            child: TextButton
            (
              style: const ButtonStyle
              (
                backgroundColor: WidgetStatePropertyAll(Colors.blue),
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                shape: WidgetStatePropertyAll<RoundedRectangleBorder>
                (
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    )
                )
              ),
              onPressed: () 
              {
                if(this.password == this.passwordController.text && this.username == this.usernameController.text)
                {
                  Navigator.push
                  (
                    context,
                    MaterialPageRoute(builder: (context) => const AccountDetails())
                  );
                }
              }, 
              child: const Text('Login')
            ),
          )
        ]
      )),
    );
  }
}