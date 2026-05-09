import 'package:flutter/material.dart';
import 'smart_search_delegate.dart';

/// Simple wrapper that launches the SmartSearchDelegate when navigated to.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Launch search delegate immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showSearch(
        context: context,
        delegate: SmartSearchDelegate(),
      ).then((_) {
        // Return to previous screen when search is dismissed
        if (context.mounted) Navigator.maybePop(context);
      });
    });

    // Transparent placeholder while delegate opens
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const SizedBox.shrink(),
    );
  }
}
