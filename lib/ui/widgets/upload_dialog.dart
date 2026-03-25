import 'dart:typed_data';
import 'package:art_platform/core/constants.dart';
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

  // Connections to Storage and Firestore Firebase
  final StorageRepository _storageRepo = StorageRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // Image Picker for picking image from local machine
  final ImagePicker _picker = ImagePicker();
  String? _selectedFileName;
  Uint8List? _fileBytes;
  bool _isUploading = false;

  // Added state variables for category selection
  String? _selectedCategory;
  // list passed by reference to 'artCategories' constant from "constants.dart"
  final List<String> _categories = artCategories;
  final Map<String, String> _categoryDisplayNames = artCategoriesDisplayName;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // picks an image from local machine and stores the byte data and name of that image
  // within the state variables of our UploadDialogState object
  Future<void> _pickImage() async {
    // Picks image from local machine gallery
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    // if we managed to get an image
    if (image != null) {
      // conevrt it to bytes
      final Uint8List bytes = await image.readAsBytes();
      // new state data: selected image name, and the binary data of the image
      setState(() {
        _selectedFileName = image.name;
        _fileBytes = bytes;
      });
    }
  }


  Future<void> _handleUpload() async {
    // if there is no text in the post name field or no data for the post (image)
    // OR if no category is selected, we display a message and return
    if (_titleController.text.isEmpty || _fileBytes == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image, enter a title, and choose a category")),
      );
      return;
    }

    // if image is provided and name as well
    // set state to is uploading and rebuild
    setState(() => _isUploading = true);

    try {
      // A unique name for the Post Document on Firebase Storage must be provided
      // Because we need to differentiate between posts...
      final String uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName';

      // We upload the Post through our storageRepo method which requires the post as byte object
      // We also provide a unique name for differentiation between Post Documents
      final String downloadUrl = await _storageRepo.uploadArt(_fileBytes!, uniqueName);
      print("Step 1 Complete: Image uploaded to $downloadUrl");

      // So far we uploaded the raw content of the post
      // We also need to upload to Firestore the Document which represents the Post.
      // This Document contains all the information related to the Post.
      // We provide the title and description of the post from the text fields of the Dialog
      // And the imageUrl that we just fetched
      await _dbRepo.uploadArt(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        imageUrl: downloadUrl,
      );
      print("Step 2 Complete: Data saved to Firestore");

      // Display SnackBar Message
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
      // wether the upload has completed succesfully or not, it has completed either way
      // so we set the state of _isUploading back to false, since we are not uploading anymore
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // The Visual Dialog
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView( // Added scroll view to prevent overflow on smaller screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload Masterpiece",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // InkWell is like a button configured to change it's state (usually color), and add
              // add some animation effects upon different behaviours of pressing (hold, tap, double tap etc...)
              InkWell(
                onTap: _pickImage, // it will pick an image from local machine
                // it changes the state variable such that we have the image object as byte object
                // and the name of the uploaded image aswell
                child: Container( // the area of the InkWell
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _fileBytes == null // if no file has been provided
                  // we will display an icon with text to suggest to click on the InkWell
                  // such that we trigger the _pickImage method
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 48, color: Colors.deepPurple),
                      SizedBox(height: 8),
                      Text("Click to select Art"),
                    ],
                  )
                  // If image has been provided, we will display the image + it's local machine name (if it has one)
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(_fileBytes!), // displays image based on Byte data Uint8List (list of Bytes)
                        ),
                      ),
                      Text(
                        // displays the name of the image (the name fetched from the local machine)
                        // if it does not have a name, the text will be replaced with "Image" word.
                        _selectedFileName ?? "Image",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Text Fields for providing Title and Description for Posts
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
              const SizedBox(height: 16),

              // --- NEW CATEGORY SELECTION UI ---
              const Text(
                "Select Category",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownMenu<String>(
                initialSelection: _selectedCategory,
                // text to show when nothing is selected
                hintText: 'Select a category',
                expandedInsets: EdgeInsets.zero,
                enableSearch: true,
                dropdownMenuEntries: _categories.map<DropdownMenuEntry<String>>((String category) {
                  return DropdownMenuEntry<String>(
                    value: category,
                    label: _categoryDisplayNames["$category"]!,
                  );
                }).toList(), // from Iterable -> List
                // The 'newSelectedCategory' is received from the 'value:' property of a DropdownMenuEntry
                // Everytime you click on a DropdownMenuEntry, flutter checks to see the value: of that
                // And if you have an 'onSelected:' property for the DropdownMenu, it
                // will pass the value of 'value:' to the parameter of onSelected:'s function.
                // And since the 'value:' requires the Generics 'T' of the DropdownMenu class
                // (which is 'String' in our case), we are receiving a String value
                // So in a way, Each DropdownMenuEntry represents a String...
                onSelected: (String? newSelectedCategory) {
                  setState(() {
                    _selectedCategory = newSelectedCategory;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Cancel Button and Uploading Button
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
                    // We don't want to trigger _handleUpload multiple times
                    onPressed: _isUploading ? null : _handleUpload,
                    // customize button, to indicate the post is uploading and the user does not need
                    // to press on it again
                    child: _isUploading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("Post Art"), // Uploading Button
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}