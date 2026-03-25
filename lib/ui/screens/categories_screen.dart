import 'package:art_platform/ui/widgets/category_tile.dart';
import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_category.dart';
import 'package:go_router/go_router.dart';

class CategoriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Art Types', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,     // nb of collumns
            crossAxisSpacing: 16,       // Space between cards
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,      // Aspect ratio of the cards
          ),
          itemCount: appCategories.length,
          itemBuilder: (context, index) {
            final currentCategory = appCategories[index];
            return CategoryTile(
              category: currentCategory,
              onTap: () => context.go("/categories/feed/${currentCategory.categoryName}"),
            );
          },
        ),
      ),
    );
  }
}