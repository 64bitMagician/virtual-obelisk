import 'package:flutter/material.dart';
import 'package:art_platform/automation/database_seeder.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isSeeding = false;

  Future<void> _runSeeder() async {
    // Show confirmation dialog before doing anything destructive/heavy
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seed Database?"),
        content: const Text(
            "This will generate 20 fake users and 50 fake art posts. "
                "Make sure your Firestore Security Rules are temporarily set to 'allow read, write: if true;' "
                "OR your Admin Bypass is fully active!"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Seed it!"),
          ),
        ],
      ),
    );

    // If user cancelled or dismissed the dialog, stop here.
    if (confirm != true) return;

    // 2. Start the seeding process
    setState(() => _isSeeding = true);

    // Show a temporary snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Seeding started... Check terminal for progress.")),
    );

    try {
      final seeder = DatabaseSeeder();
      await seeder.runSeed();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Seed Complete! Database populated."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Seed Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.red[900], // Give the admin screen a distinct, serious color
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

          // THE SEEDER CARD
          Card(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.redAccent, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const Icon(Icons.data_object, color: Colors.redAccent, size: 32),
              title: const Text("Populate Mock Data (Seeder)"),
              subtitle: const Text("Generates random users, posts, and stats to test UI layouts and pagination."),
              trailing: _isSeeding
                  ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent)
              )
                  : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                ),
                onPressed: _runSeeder,
                icon: const Icon(Icons.play_arrow),
                label: const Text("RUN"),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // REPORTED ARTPOSTS
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.orange.shade300, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const Icon(Icons.gavel, color: Colors.orange, size: 32),
              title: const Text("Moderation Queue"),
              subtitle: const Text("Review user-reported artworks, issue warnings, or remove content violating platform rules."),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // Navigate to the future moderation screen!
                // context.push('/admin/moderation');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Moderation Queue coming soon!")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}