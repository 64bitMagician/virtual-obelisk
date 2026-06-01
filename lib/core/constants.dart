import 'dart:core';

enum Ranks {novice, apprentice, artisan, master, virtuoso, visionary, legend}

// enum with storage folders. This is for determining in which folder to store the uploaded art
// used in upload_dialog.dart
enum FolderPathEnum {artworks, coverart, thumbnail, avatars}

enum MediaReaderConfiguration {HOME_FEED, CATEGORY_FEED, PROFILE_FEED, REPORTED_ARTPOSTS_FEED}

// ! DO NOT CHANGE ORDER, IT WILL AFFECT APPLICATION
// ! IF YOU WANT TO ADD A NEW ART CATEGORY, YOU MUST ALSO PROVIDE THE DISPLAY NAME IN THE MAP OBJECT TYPE BELLOW
const List<String> artCategories =  [
  "drawing",
  "painting",
  "digitalart",
  "pixelart",
  "graffiti",
  "photography",
  "videoart",
  "music",
  "poetry",
  "prose"
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
  "videoart" : "Video Art",
  "prose" : "Prose",
};

// Artist Point Reward Values:
int upload_artpost_artist_points_reward = 50;
int gain_follower_artist_points_reward = 10;
int get_like_artist_points_reward = 10;

