import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';
import '../../data/repositories/database_repository.dart'; // <--- Using the Real DB

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 1. Initialize the Real Repository
  final DatabaseRepository _repository = DatabaseRepository();

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
                // 2. HEADER SECTION (Hardcoded for now until Login is built)
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=me"),
                ),
                const SizedBox(height: 16),
                Text("Vlad (Alpha)", style: Theme.of(context).textTheme.headlineSmall),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: Text(
                    "Digital artist exploring the void. (Bio coming soon)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // 3. TAB SELECTOR (Visual only)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.grid_on, color: Colors.deepPurple),
                    Icon(Icons.bookmark_border, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. REAL ARTWORK GRID
                StreamBuilder<List<ArtPost>>(
                  stream: _repository.getFeedPosts(), // Listen to real DB
                  builder: (context, snapshot) {
                    // A. Loading
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // B. Empty or Error
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text("No art uploaded yet."),
                      );
                    }

                    // C. Data Loaded
                    final posts = snapshot.data!;

                    return GridView.builder(
                      shrinkWrap: true, // IMPORTANT for inside SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200, // Responsive grid items
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post.imageUrl, // <--- Using the Real URL from Firestore
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(color: Colors.grey[900]);
                            },
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
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