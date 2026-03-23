import 'dart:core';

enum Ranks {novice, apprentice, artisan, master, virtuoso, visionary, legend}

enum ArtCategory {
  painting,
  drawing,
  graffiti,
  music,
  poetry,
  photography,
}

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

