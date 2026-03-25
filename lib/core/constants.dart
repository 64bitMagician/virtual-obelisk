import 'dart:core';

enum Ranks {novice, apprentice, artisan, master, virtuoso, visionary, legend}

// ! DO NOT CHANGE ORDER, IT WILL AFFECT APPLICATION
const List<String> artCategories =  [
  "drawing",
  "painting",
  "pixelart",
  "graffiti",
  "photography",
  "music",
  "poetry",
];

const Map<String, String> artCategoriesDisplayName = {
  "drawing" : "Drawing",
  "painting" : "Painting",
  "pixelart" : "Pixel Art",
  "graffiti" : "Graffiti",
  "photography" : "Photography",
  "music" : "Music",
  "poetry" : "Poetry",
};

// // Extension to get user-friendly names and icons
// extension ArtCategoryExtension on ArtCategory {
//   String get label {
//     switch (this) {
//       case ArtCategory.painting:
//         return 'Painting';
//       case ArtCategory.drawing:
//         return 'Drawing';
//       case ArtCategory.graffiti:
//         return 'Graffiti';
//       case ArtCategory.music:
//         return 'Music';
//       case ArtCategory.poetry:
//         return 'Poetry';
//       case ArtCategory.photography:
//         return 'Photography';
//     }
//   }
// }

