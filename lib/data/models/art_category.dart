import 'package:art_platform/core/constants.dart';
import 'package:flutter/material.dart';

class ArtCategory {
  final String title;
  final String categoryName;
  final IconData icon;
  final Color themeColor;
  final String imageAsset; // If you want background images

  ArtCategory({
    required this.title,
    required this.categoryName,
    required this.icon,
    required this.themeColor,
    this.imageAsset = 'default',
  });


}



// Data Source
List<ArtCategory> appCategories = [
  ArtCategory(title: artCategoriesDisplayName["drawing"]!, categoryName: artCategories[0], icon: Icons.edit, themeColor: Colors.blueAccent),
  ArtCategory(title: artCategoriesDisplayName["painting"]!, categoryName: artCategories[1], icon: Icons.palette, themeColor: Colors.redAccent),
  ArtCategory(title: artCategoriesDisplayName["digitalart"]!, categoryName: artCategories[2], icon: Icons.tablet_mac_outlined, themeColor: Colors.blueGrey),
  ArtCategory(title: artCategoriesDisplayName["pixelart"]!, categoryName: artCategories[3], icon: Icons.gamepad_outlined, themeColor: Colors.green),
  ArtCategory(title: artCategoriesDisplayName["graffiti"]!, categoryName: artCategories[4], icon: Icons.format_paint, themeColor: Colors.orangeAccent),
  ArtCategory(title: artCategoriesDisplayName["photography"]!, categoryName: artCategories[5], icon: Icons.camera_outlined, themeColor: Colors.orangeAccent),
  ArtCategory(title: artCategoriesDisplayName["music"]!, categoryName: artCategories[6], icon: Icons.music_note, themeColor: Colors.purpleAccent),
  ArtCategory(title: artCategoriesDisplayName["poetry"]!, categoryName: artCategories[7], icon: Icons.history_edu, themeColor: Colors.teal),
];