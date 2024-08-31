import 'package:flutter/material.dart';

class CustomDropdownButton extends StatelessWidget {
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const CustomDropdownButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4), // Rounded corners
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
          alignment: AlignmentDirectional.centerEnd,
          value: value,
          hint: const Text("Person", style: TextStyle(color: Colors.grey)),
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
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
