import 'package:flutter/material.dart';
import '../shared/custom_search_bar.dart';

class NewsSearchBar extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;

  const NewsSearchBar({
    Key? key,
    required this.searchQuery,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: CustomSearchBar(
        hintText: 'Search incidents...',
        onChanged: onSearchChanged,
      ),
    );
  }
}
