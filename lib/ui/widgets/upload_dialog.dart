import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/storage_repository.dart';
import '../../data/repositories/database_repository.dart';

class UploadDialog extends StatefulWidget {
  const UploadDialog({super.key});

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {

  final StorageRepository _storageRepo = StorageRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  final ImagePicker _picker = ImagePicker();
  String? _selectedFileName;
  Uint8List? _fileBytes;
  bool _isUploading = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        _selectedFileName = image.name;
        _fileBytes = bytes;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_titleController.text.isEmpty || _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image and enter a title")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final String uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName';

      final String downloadUrl = await _storageRepo.uploadArt(_fileBytes!, uniqueName);
      print("Step 1 Complete: Image uploaded to $downloadUrl");

      await _dbRepo.saveArt(
        title: _titleController.text,
        description: _descriptionController.text,
        imageUrl: downloadUrl,
      );
      print("Step 2 Complete: Data saved to Firestore");

      if (mounted) {
        context.pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Posted Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print("UPLOAD ERROR: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to post. Check Console for details."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upload Masterpiece",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _fileBytes == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 48, color: Colors.deepPurple),
                    SizedBox(height: 8),
                    Text("Click to select Art"),
                  ],
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.memory(_fileBytes!),
                      ),
                    ),
                    Text(
                      _selectedFileName ?? "Image",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Inputs
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
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  // Disable button while uploading
                  onPressed: _isUploading ? null : _handleUpload,
                  child: _isUploading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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