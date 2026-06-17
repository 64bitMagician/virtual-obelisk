import 'package:flutter/material.dart';
import 'package:art_platform/automation/database_seeder.dart';

class SeedDatabaseDialog extends StatefulWidget {
  const SeedDatabaseDialog({super.key});

  @override
  State<SeedDatabaseDialog> createState() => _SeedDatabaseDialogState();
}

class _SeedDatabaseDialogState extends State<SeedDatabaseDialog> {
  bool _isSeeding = false;

  Future<void> _runSeeder() async {
    setState(() => _isSeeding = true);

    try {
      final seeder = DatabaseSeeder();
      await seeder.runSeed();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Seed Complete! Database populated."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSeeding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Seed Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Seed Database?"),
      content: const Text(
        "This will generate 5 fake users and 10 fake art posts. "
            "This operation might take a few moments.",
      ),
      actions: [
        TextButton(
          onPressed: _isSeeding ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSeeding ? null : _runSeeder,
          child: _isSeeding
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Text("Yes, Seed Data"),
        ),
      ],
    );
  }
}