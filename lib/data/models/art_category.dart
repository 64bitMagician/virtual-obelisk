import 'package:flutter/material.dart';

class ArtCategory {
  final String title;
  final IconData icon;
  final Color themeColor;
  final String imageAsset; // If you want background images

  ArtCategory({
    required this.title,
    required this.icon,
    required this.themeColor,
    this.imageAsset = 'default',
  });
}

// Data Source
List<ArtCategory> appCategories = [
  ArtCategory(title: 'Graffiti', icon: Icons.format_paint, themeColor: Colors.orangeAccent),
  ArtCategory(title: 'Painting', icon: Icons.palette, themeColor: Colors.redAccent),
  ArtCategory(title: 'Drawing', icon: Icons.edit, themeColor: Colors.blueAccent),
  ArtCategory(title: 'Music', icon: Icons.music_note, themeColor: Colors.purpleAccent),
  ArtCategory(title: 'Poems', icon: Icons.history_edu, themeColor: Colors.teal),
];