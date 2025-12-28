import 'package:flutter/material.dart';
import '../../data/repositories/mock_repository.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final MockRepository _repository = MockRepository();

  // We need two things: Profile Info AND Their Art
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<String>> _artworksFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _repository.getUserProfile();
    _artworksFuture = _repository.getUserArtworks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900), // Web constraint
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Load Header
                FutureBuilder<Map<String, dynamic>>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    return ProfileHeader(user: snapshot.data!);
                  },
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // 2. Tab Selector (Visual only for now)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.grid_on, color: Colors.purple),
                    Icon(Icons.bookmark_border, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Art Grid
                FutureBuilder<List<String>>(
                  future: _artworksFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    return GridView.builder(
                      shrinkWrap: true, // IMPORTANT for inside SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(), // Let the page scroll, not the grid
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200, // Responsive grid items
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            snapshot.data![index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}