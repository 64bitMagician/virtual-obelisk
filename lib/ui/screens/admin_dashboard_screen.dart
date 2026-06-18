import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/ban_user_dialog.dart';
import '../widgets/seed_database_dialog.dart';
import '../widgets/admin_action_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Developer Tools",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Seeder Card
          AdminActionCard(
            title: "Populate Mock Data",
            subtitle: "Generates random users and posts.",
            icon: Icons.data_object,
            themeColor: Colors.redAccent,
            onTap: () => showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const SeedDatabaseDialog(),
            ),
          ),

          const SizedBox(height: 16),

          // Moderation Card
          AdminActionCard(
            title: "Moderation Queue",
            subtitle: "Review user-reported artworks, or remove content.",
            icon: Icons.gavel,
            themeColor: Colors.orange,
            onTap: () => context.push('/admin/media_reader'),
          ),

          const SizedBox(height: 16),

          // Art Chain Card
          AdminActionCard(
            title: "Create Art Chain",
            subtitle: "Launch a new collaborative prompt for the community.",
            icon: Icons.link,
            themeColor: Colors.deepPurpleAccent,
            onTap: () => context.push('/admin/create_chain'),
          ),

          const SizedBox(height: 16),

          // Ban User Card
          AdminActionCard(
            title: "Ban User Account",
            subtitle: "Revoke a user's access to the platform and hide them from feeds.",
            icon: Icons.person_off,
            themeColor: Colors.red.shade900,
            onTap: () => showDialog(
              context: context,
              builder: (context) => const BanUserDialog(),
            ),
          ),
        ],
      ),
    );
  }
}