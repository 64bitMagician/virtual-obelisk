import '../models/art_post.dart';
import '../models/chain.dart'; // Don't forget to import the new model

class MockRepository {
  // This simulates fetching data from a server (with a slight delay)
  Future<List<ArtPost>> getFeedPosts() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Fake network delay

    return [
      ArtPost(
        id: '1',
        artistName: 'Elena V.',
        artistRank: 'Virtuoso',
        artistAvatarUrl: 'https://i.pravatar.cc/150?u=elena',
        contentUrl: 'https://picsum.photos/id/1015/600/400', // Landscape nature
        title: 'The Silent Symphony',
        description: 'An attempt to capture the sound of silence through colors.',
        likes: 124,
      ),
      ArtPost(
        id: '2',
        artistName: 'Marcus Art',
        artistRank: 'Apprentice',
        artistAvatarUrl: 'https://i.pravatar.cc/150?u=marcus',
        contentUrl: 'https://picsum.photos/id/1016/400/600', // Portrait canyon
        title: 'Red Rocks',
        description: 'First attempt at digital painting.',
        likes: 45,
      ),
      ArtPost(
        id: '3',
        artistName: 'Sarah Jenkins',
        artistRank: 'Legend',
        artistAvatarUrl: 'https://i.pravatar.cc/150?u=sarah',
        contentUrl: 'https://picsum.photos/id/1081/600/600', // Architecture
        title: 'City of Glass',
        description: 'Reflection studies using oil on canvas.',
        likes: 890,
        isChain: true, // This is a collaborative piece
      ),
      ArtPost(
        id: '4',
        artistName: 'Davide M.',
        artistRank: 'Scholar',
        artistAvatarUrl: 'https://i.pravatar.cc/150?u=davide',
        contentUrl: 'https://picsum.photos/id/237/600/400', // Dog
        title: 'Companionship',
        description: 'Charcoal sketch.',
        likes: 210,
      ),
    ];
  }

  Future<List<Chain>> getChains() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      // Chain 1: A fully completed collaboration
      Chain(
        id: 'c1',
        title: 'The Rain in the City',
        initiatorName: 'Elena V.',
        status: 'Completed',
        steps: [
          ChainStep(
              id: 's1',
              type: 'image',
              isCompleted: true,
              contributorName: 'Elena V.',
              contentUrl: 'https://picsum.photos/id/177/600/300' // Rainy photo
          ),
          ChainStep(
              id: 's2',
              type: 'audio',
              isCompleted: true,
              contributorName: 'Marcus Art',
              contentUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
          ),
          ChainStep(
              id: 's3',
              type: 'text',
              isCompleted: true,
              contributorName: 'Sarah Jenkins',
              contentUrl: 'The rain fell hard, washing away the dust of yesterday...'
          ),
        ],
      ),

      // Chain 2: Waiting for a musician
      Chain(
        id: 'c2',
        title: 'Desert Solitude',
        initiatorName: 'Davide M.',
        status: 'Active',
        steps: [
          ChainStep(
              id: 's1',
              type: 'image',
              isCompleted: true,
              contributorName: 'Davide M.',
              contentUrl: 'https://picsum.photos/id/1016/600/300' // Canyon
          ),
          ChainStep(
            id: 's2',
            type: 'audio',
            isCompleted: false, // <-- This slot is open!
          ),
          ChainStep(
            id: 's3',
            type: 'text',
            isCompleted: false,
          ),
        ],
      ),
    ];
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'name': 'Alex Creator',
      'rank': 'Virtuoso',
      'bio': 'Exploring the boundaries of digital sound and visual chaos.',
      'avatarUrl': 'https://i.pravatar.cc/150?u=alex',
      'followers': 1205,
      'following': 45,
      'likes': 8500,
    };
  }

  Future<List<String>> getUserArtworks() async {
    // Returns a list of image URLs for the grid
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      'https://picsum.photos/id/10/400/400',
      'https://picsum.photos/id/11/400/400',
      'https://picsum.photos/id/12/400/400',
      'https://picsum.photos/id/13/400/400',
      'https://picsum.photos/id/14/400/400',
      'https://picsum.photos/id/16/400/400',
    ];
  }

  Future<Chain> getChainById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // We'll just return one of our fake chains based on ID,
    // or a default one if not found (for the mock)
    final allChains = await getChains();
    return allChains.firstWhere(
            (c) => c.id == id,
        orElse: () => allChains[0]
    );
  }
}