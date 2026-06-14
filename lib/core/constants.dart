import 'dart:core';

enum Ranks {novice, apprentice, artisan, master, virtuoso, visionary, legend}

// enum with storage folders. This is for determining in which folder to store the uploaded art
// used in upload_dialog.dart
enum FolderPathEnum {artworks, coverart, thumbnail, avatars}

enum MediaReaderConfiguration {HOME_FEED, CATEGORY_FEED, PROFILE_FEED, REPORTED_ARTPOSTS_FEED, CHAIN_NODE_FEED}

// ! DO NOT CHANGE ORDER, IT WILL AFFECT APPLICATION. IF CHANGING ORTHER ALSO CHANGE TO art_category.dart
// ! IF YOU WANT TO ADD A NEW ART CATEGORY, YOU MUST ALSO PROVIDE THE DISPLAY NAME IN THE MAP OBJECT TYPE BELLOW
const List<String> artCategories =  [
  "ascii_art",
  "dance",
  "digitalart",
  "drawing",
  "graffiti",
  "lyrics",
  "music",
  "painting",
  "photography",
  "pixelart",
  "poetry",
  "prose",
  "videoart",
];

// ! THIS REPRESENTS HOW THE CATEGORY NAME WILL BE DISPLAYED WITHIN THE APP
const Map<String, String> artCategoriesDisplayName = {
  "ascii_art" : "ASCII_ART",
  "dance" : "Artistic Dance",
  "digitalart" : "Digital Art",
  "drawing" : "Drawing",
  "graffiti" : "Graffiti",
  "lyrics" : "Lyrics",
  "music" : "Music",
  "painting" : "Painting",
  "photography" : "Photography",
  "pixelart" : "Pixel Art",
  "poetry" : "Poetry",
  "prose" : "Prose",
  "videoart" : "Video Art",
};

// Artist Point Reward Values:
const int upload_artpost_artist_points_reward = 200;
const int gain_follower_artist_points_reward = 100;
const int get_like_artist_points_reward = 50;

// Posts per day limit
const int posts_per_day_allowed = 100;

