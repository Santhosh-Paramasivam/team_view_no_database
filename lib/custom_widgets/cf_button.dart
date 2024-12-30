import 'package:flutter/material.dart';

class CampusFindButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const CampusFindButton({super.key, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 300,
        child: TextButton(
            style: const ButtonStyle(
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)))),
                backgroundColor: WidgetStatePropertyAll(Colors.black)),
            onPressed: onPressed,
            child: Text(
              this.label,
              style: const TextStyle(color: Colors.white),
            )));
  }
}
