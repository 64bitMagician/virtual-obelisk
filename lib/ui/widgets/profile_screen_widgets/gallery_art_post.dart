import 'package:art_platform/data/models/art_post.dart';
import 'package:flutter/material.dart';

enum FetchType { network, local }

class GalleryArtPost extends StatelessWidget {
  final ArtPost post;

  const GalleryArtPost({required this.post, super.key});

  // Getters
  MediaType get postType => post.mediaType;

  @override
  Widget build(BuildContext context) {
    // determine icon post type
    IconData? icon = _determineIconToUseOnPost();

    String gallery_image;
    FetchType fetchType;
    // Getting multiple values from function through Record Dart Feature
    (fetchType, gallery_image) = _determineFetchTypeAndImageAssetToUpload();

    if (fetchType == FetchType.local) // if gallery image received localy
      return _createLocalGalleryImage(gallery_image, icon: icon);
    else if (fetchType == FetchType.network) // if gallery image received from network
      return _createNetworkGalleryImage(gallery_image, icon: icon);

    // in case something bad happens
    return Image.asset("assets/icons/error_image.png");
  }

  Widget _createLocalGalleryImage(String localImageUrl, {IconData? icon}) {
    bool chain_icon = _checkIfChainPost();

    return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(localImageUrl, fit: BoxFit.cover),
          if (chain_icon) Positioned(bottom: 5, left: 5, child: getChainIcon()),
          if (icon != null) Positioned(bottom: 5, right: 5, child: getMediaTypeIconWidget(icon)),
        ]
    );
  }

  Widget _createNetworkGalleryImage(String imageUrl, {IconData? icon}) {
    bool chain_icon = _checkIfChainPost();

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          // the wrapped Widget, the Image
          imageUrl, // Pass the URL to the image
          // the way the image is inscribed within the available space
          // cover makes sure of no blank edges
          // but may give up on parts of the image if the right ratio is not met
          fit: BoxFit.cover,
          // loadingBuilder specifies the widget to display to the user while an image is still loading
          // this is within the grid (not the UserGalleryScreen)
          loadingBuilder: (contex, child, progress) {
            // child parameter represents the complete fetched image
            // when progress is null, the image has finished loading
            if (progress == null) return child;
            // And while the image is not finished loading (is loading)
            // we are returning this custom Circular Progress Indicator
            return Container(color: Colors.grey[900], child: const Center(child: CircularProgressIndicator()));
          },
          // The errorBuilder property requires a callback function, that asks to
          // return a widget to be displayed instead of the error that has occured,
          // only in case an error has occured
          // We will simply display a broken image icon
          errorBuilder: (context, err, stack) => const Icon(Icons.broken_image),
        ),
        if (chain_icon) Positioned(bottom: 5, left: 5, child: getChainIcon()),
        if (icon != null) Positioned(bottom: 5, right: 5, child: getMediaTypeIconWidget(icon)),
      ],
    );
  }

  // determine the icon to use depending on post type
  IconData? _determineIconToUseOnPost() {
    if (postType == MediaType.audio) // audio -> audio icon
      return Icons.music_note_outlined;
    else if (postType == MediaType.video) // video -> video icon
      return Icons.movie_outlined;
    else if (postType == MediaType.text)
      return Icons.text_snippet_outlined; // text -> text icon
    else if (postType == MediaType.image)
      return Icons.image_outlined;

    return null;
  }

  // This method checks if the artpost belongs to a chain
  bool _checkIfChainPost() {
    if (post.chainId != null)
      return true;

    return false;
  }

  // This function Returns a record (multiple values)
  (FetchType, String) _determineFetchTypeAndImageAssetToUpload() {
    String? gallery_image;
    FetchType? fetchType;

    if (post.mediaType==MediaType.image) // if an image, no additionalMediaUrl, we take it directly from network
    {
      gallery_image = post.mediaUrl;
      fetchType = FetchType.network;
    }
    else if (postType == MediaType.audio) // if an audio post
    {
      // if no additional asset provided, we provide the default one locally
      if (post.additionalMediaUrl == "default") {
        fetchType = FetchType.local;
        gallery_image = "assets/icons/default-audio-coverart.png";
      } else // if additional asset has been provided, we provide the url to it
      {
        fetchType = FetchType.network;
        gallery_image = post.additionalMediaUrl;
      }
    } else if (postType == MediaType.video) // if an video post
    {
      // if no additional asset provided, we provide the default one locally
      if (post.additionalMediaUrl == "default") {
        fetchType = FetchType.local;
        gallery_image = "assets/icons/default-video-gallery-asset.png";
      } else // if additional asset has been provided, we provide the url to it
      {
        fetchType = FetchType.network;
        gallery_image = post.additionalMediaUrl;
      }
    } else if (postType == MediaType.text) // if an text post
    {
      // if no additional asset provided, we provide the default one locally
      if (post.additionalMediaUrl == "default") {
        fetchType = FetchType.local;
        gallery_image = "assets/icons/default-text-gallery-asset.png";
      } else // if additional asset has been provided, we provide the url to it
      {
        fetchType = FetchType.network;
        gallery_image = post.additionalMediaUrl;
      }
    }

    return (fetchType!, gallery_image!);
  }

  Widget getMediaTypeIconWidget(IconData icon) {
    return Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20));
  }

  Widget getChainIcon() {
    return Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: Icon(Icons.link_outlined, color: Colors.white, size: 20));
  }
}
