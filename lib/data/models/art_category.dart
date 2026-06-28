import 'package:art_platform/core/constants.dart';
import 'package:flutter/material.dart';

class ArtCategory {
  final String title;
  final String categoryName;
  final IconData icon;
  final Color themeColor;
  final String imageAsset;

  ArtCategory({
    required this.title,
    required this.categoryName,
    required this.icon,
    required this.themeColor,
    this.imageAsset = 'default',
  });


}


// ! The order and indexing is very important. It must coincide with 'artCategories' List's order (from constants.dart).
List<ArtCategory> appCategories = [
  ArtCategory(title: artCategoriesDisplayName["ascii_art"]!, categoryName: artCategories[0], icon: Icons.data_object_outlined, themeColor: Colors.grey),
  ArtCategory(title: artCategoriesDisplayName["dance"]!, categoryName: artCategories[1], icon: Icons.radio, themeColor: Colors.deepPurple),
  ArtCategory(title: artCategoriesDisplayName["digitalart"]!, categoryName: artCategories[2], icon: Icons.tablet_mac_outlined, themeColor: Colors.blueGrey),
  ArtCategory(title: artCategoriesDisplayName["drawing"]!, categoryName: artCategories[3], icon: Icons.edit, themeColor: Colors.blueAccent),
  ArtCategory(title: artCategoriesDisplayName["graffiti"]!, categoryName: artCategories[4], icon: Icons.format_paint, themeColor: Colors.orangeAccent),
  ArtCategory(title: artCategoriesDisplayName["lyrics"]!, categoryName: artCategories[5], icon: Icons.lyrics_outlined, themeColor: Colors.brown),
  ArtCategory(title: artCategoriesDisplayName["music"]!, categoryName: artCategories[6], icon: Icons.music_note, themeColor: Colors.purpleAccent),
  ArtCategory(title: artCategoriesDisplayName["painting"]!, categoryName: artCategories[7], icon: Icons.palette, themeColor: Colors.redAccent),
  ArtCategory(title: artCategoriesDisplayName["photography"]!, categoryName: artCategories[8], icon: Icons.camera_outlined, themeColor: Colors.orangeAccent),
  ArtCategory(title: artCategoriesDisplayName["pixelart"]!, categoryName: artCategories[9], icon: Icons.gamepad_outlined, themeColor: Colors.green),
  ArtCategory(title: artCategoriesDisplayName["poetry"]!, categoryName: artCategories[10], icon: Icons.history_edu, themeColor: Colors.teal),
  ArtCategory(title: artCategoriesDisplayName["prose"]!, categoryName: artCategories[11], icon: Icons.book_outlined, themeColor: Colors.brown),
  ArtCategory(title: artCategoriesDisplayName["videoart"]!, categoryName: artCategories[12], icon: Icons.local_movies_outlined, themeColor: Colors.brown),
];