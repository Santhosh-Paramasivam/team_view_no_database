import 'package:flutter/material.dart';

class CampusFindInput extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final double width;
  final bool obscureText;

  const CampusFindInput(
      {super.key,
      required this.labelText,
      required this.controller,
      required this.width, this.obscureText=false});

  static const Color lightGrey = Color(0xFFF7F8F9);
  static const Color darkGrey = Color(0xFF8391A1);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      width: this.width,
      child: TextField(
        obscureText: this.obscureText,
        controller: this.controller,
        cursorColor: darkGrey,
        style: const TextStyle(fontSize: 16, color: darkGrey),
        decoration: InputDecoration(
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
              width: 1,
              color: darkGrey,
            )),
            enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
              width: 1,
              color: darkGrey,
            )),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            filled: true,
            fillColor: lightGrey,
            label: Text(this.labelText,
                style: const TextStyle(fontSize: 16, color: darkGrey)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
            border: const OutlineInputBorder(
                borderSide: BorderSide(
              width: 1,
              color: darkGrey,
            ))),
      ),
    );
  }
}
