import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UploadDialog extends StatefulWidget {
  const UploadDialog({super.key});

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  // Simple state to simulate "selecting" a file
  String? _selectedFileName;
  bool _isUploading = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _simulateUpload() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isUploading = true);

    // Fake network delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      context.pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Art posted successfully! (Mock)")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500, // Fixed width for web
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Upload Masterpiece", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),

            // 1. The "Drop Zone" (Visual Only)
            InkWell(
              onTap: () {
                setState(() => _selectedFileName = "abstract_painting_v1.png");
              },
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedFileName == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 48, color: Colors.purple),
                    SizedBox(height: 8),
                    Text("Click to select Art"),
                  ],
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 48, color: Colors.green),
                    const SizedBox(height: 8),
                    Text(_selectedFileName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Input Fields
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description / Story",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isUploading ? null : _simulateUpload,
                  child: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Post Art"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}