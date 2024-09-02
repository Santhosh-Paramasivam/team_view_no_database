import 'package:flutter/material.dart';
//import 'search_page.dart';
//import 'search_page_persons.dart';
import 'search_page_members.dart';
import 'status_and_visibility.dart';

class AccountDetails extends StatelessWidget
{
  AccountDetails({super.key});

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      appBar: AppBar
      (
        title: const Text("Welcome Back, Santhosh"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:Column(children:
        [
          MenuButton("Status And Visibility", (context)
          {
            Navigator.push
            (
              context,
              MaterialPageRoute(builder: (context) => StatusAndVisibility())
            );
          }),
          MenuButton("Member Search Page", (context){}),
          MenuButton("Search members and venues", (context){
            Navigator.push
            (
              context,
              MaterialPageRoute(builder: (context) => SearchPage())
            );
          }),
          MenuButton("Log Out", (context){
            Navigator.pop(context);
          }),
          MenuButton("Search Page", (context){})
        ]
      )
      );
  }
}

class MenuButton extends StatelessWidget
{
  String label = "";
  //final VoidCallback onPressed; 
  //final Function(BuildContext) onPressed;
  final void Function(BuildContext) onPressed;

  MenuButton(this.label, this.onPressed, {super.key});

  @override
  Widget build(BuildContext context)
  {
    return SizedBox
        (
          width: double.infinity,
          height: 60,
          child:  TextButton(
            style: const ButtonStyle
            (
              shape: WidgetStatePropertyAll<RoundedRectangleBorder>
                (
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    )
                )
            ),
            onPressed: () => this.onPressed(context), 
            child: Text(
              this.label, 
              style: const TextStyle(fontSize: 18, color: Colors.blue),)),
        );
  }
}