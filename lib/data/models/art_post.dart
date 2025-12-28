class ArtPost {
  final String id;
  final String artistName;
  final String artistRank; // e.g., "Apprentice", "Virtuoso"
  final String artistAvatarUrl;
  final String contentUrl; // URL to image/video
  final String title;
  final String description;
  final int likes;
  final bool isChain; // Is this part of a collaboration chain?

  ArtPost({
    required this.id,
    required this.artistName,
    required this.artistRank,
    required this.artistAvatarUrl,
    required this.contentUrl,
    required this.title,
    required this.description,
    required this.likes,
    this.isChain = false,
  });
}