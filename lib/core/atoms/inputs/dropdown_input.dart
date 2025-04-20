import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class DropdownInputWidget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final String? hint;

  const DropdownInputWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint ?? label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
