import 'dart:core';

enum Ranks {novice, apprentice, artisan, master, virtuoso, visionary, legend}

// ! DO NOT CHANGE ORDER, IT WILL AFFECT APPLICATION
// ! IF YOU WANT TO ADD A NEW ART CATEGORY, YOU MUST ALSO PROVIDE THE DISPLAY NAME IN THE MAP OBJECT TYPE BELLOW
const List<String> artCategories =  [
  "drawing",
  "painting",
  "digitalart",
  "pixelart",
  "graffiti",
  "photography",
  "music",
  "poetry",
];

// ! THIS REPRESENTS HOW THE CATEGORY NAME WILL BE DISPLAYED WITHIN THE APP
const Map<String, String> artCategoriesDisplayName = {
  "drawing" : "Drawing",
  "painting" : "Painting",
  "digitalart" : "Digital Art",
  "pixelart" : "Pixel Art",
  "graffiti" : "Graffiti",
  "photography" : "Photography",
  "music" : "Music",
  "poetry" : "Poetry",
};

