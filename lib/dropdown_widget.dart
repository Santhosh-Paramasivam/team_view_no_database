import 'package:flutter/material.dart';

class CustomDropdownButton extends StatelessWidget {
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final EdgeInsets padding;

  const CustomDropdownButton(
      {super.key,
      required this.value,
      required this.items,
      required this.onChanged,
      required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          padding: padding,
          alignment: AlignmentDirectional.centerEnd,
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          iconSize: 24,
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
