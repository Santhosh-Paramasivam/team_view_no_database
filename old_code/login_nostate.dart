import 'package:flutter/material.dart';

class Login extends StatelessWidget
{
  const Login({super.key});

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
      body: Center
      (
          child: Column
          (
            mainAxisAlignment: MainAxisAlignment.center,
            children: 
            [
              const SizedBox
              (
              width: 320,
              height: 50,
              child: TextField
              (
                decoration: InputDecoration
                (
                  contentPadding: EdgeInsets.all(5),
                  prefixIcon: Icon(Icons.person),
                  labelText: "Enter Username",
                  border: OutlineInputBorder(),
                  
                ),
              ),
              ),
              const SizedBox
              (
              width: 320,
              height: 50,
              child: TextField
              (
                decoration: InputDecoration
                (
                  contentPadding: EdgeInsets.all(5),
                  prefixIcon: Icon(Icons.person),
                  labelText: "Enter Password",
                  border: OutlineInputBorder(),
                ),
              ),
              ),
              SizedBox
              (
                width: 320,
                height: 50,
                child: TextButton
                (
                  onPressed: () => {},
                  style: const ButtonStyle
                  (
                    backgroundColor: WidgetStatePropertyAll(Colors.blue),
                    foregroundColor: WidgetStatePropertyAll(Colors.white),
                    shape: WidgetStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  ), 
                  child: const Text("Login"),
                ),
              )
          ],
        ),
      )
    );
  }
}