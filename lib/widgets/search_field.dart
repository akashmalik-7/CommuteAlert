import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    required this.hintText,
    this.controller,
    this.onTap,
    this.prefixIcon = Icons.search_rounded,
    this.readOnly = false,
    super.key,
  });

  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final IconData prefixIcon;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppTheme.primaryGreen),
      ),
    );
  }
}
