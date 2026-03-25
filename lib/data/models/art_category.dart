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
  ArtCategory(title: 'Drawing', categoryName: artCategories[0], icon: Icons.edit, themeColor: Colors.blueAccent),
  ArtCategory(title: 'Painting', categoryName: artCategories[1], icon: Icons.palette, themeColor: Colors.redAccent),
  ArtCategory(title: 'Pixel Art', categoryName: artCategories[2], icon: Icons.gamepad_outlined, themeColor: Colors.green),
  ArtCategory(title: 'Graffiti', categoryName: artCategories[3], icon: Icons.format_paint, themeColor: Colors.orangeAccent),
  ArtCategory(title: 'Photography', categoryName: artCategories[4], icon: Icons.format_paint, themeColor: Colors.orangeAccent),
  ArtCategory(title: 'Music', categoryName: artCategories[5], icon: Icons.music_note, themeColor: Colors.purpleAccent),
  ArtCategory(title: 'Poetry', categoryName: artCategories[6], icon: Icons.history_edu, themeColor: Colors.teal),
];