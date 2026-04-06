import 'dart:typed_data';
import 'package:art_platform/core/constants.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/tools/mimeFileDetector.dart';
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
  bool _isUploading = false;
  XFile? _fileInstance;
  Uint8List? _fileAsBytes;
  MediaType? _mediaType;

  // --- THUMBNAIL STATE VARIABLES ---
  XFile? _additionalMediaInstance;
  Uint8List? _additionalMediaBytes;
  String? _additionalMediaFileName;

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

  Future<void> _pickThumbnail() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      Uint8List bytesContent = await file.readAsBytes();
      setState(() {
        _additionalMediaInstance = file;
        _additionalMediaFileName = file.name;
        _additionalMediaBytes = bytesContent;
      });
    }
  }

  // picks an image from local machine and stores the byte data and name of that image
  // within the state variables of our UploadDialogState object
  Future<void> _pickImage() async {
    // Picks file from local machine gallery
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

    // if we managed to get a file
    if (file != null) {
      // Get new data from the new file so you assign it to member variables in setState()
      // get file as bytes
      Uint8List bytesContent = await file.readAsBytes();
      // get the new media type of the new file
      final newMediaType = determineMediaTypeFromFile(file.name, bytesContent);


      // new state data: selected file name, and the binary data of the file
      setState(() {
        _fileInstance = file;
        _selectedFileName = file.name; // set name of file
        _fileAsBytes = bytesContent;
        // get MediaType of file
        _mediaType = newMediaType;

        if (newMediaType == MediaType.image) {
          _additionalMediaInstance = null;
          _additionalMediaFileName = null;
          _additionalMediaBytes = null;
        }
      });
    }
  }


  Future<void> _handleUpload() async {
    final validationError = validatingPostBeforeUpload();

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() => _isUploading = true);

    String? mainFileDownloadUrl;

    try {
      print("ATTEMPTING TO UPLOAD FILE AT FIREBASE CLOUD BUCKET...");

      // We upload the Post through our storageRepo method which requires the post as byte object
      // We also provide a unique name for differentiation between Post Documents

      mainFileDownloadUrl = await _storageRepo.uploadMedia(
        _fileInstance,
        folderPath: FolderPathEnum.artworks,
      );
      print("Main File uploaded to $mainFileDownloadUrl");

      // If there is additional media to be uploaded, [additionalMediaDownloadUrl] will hold the
      // string Url to that Media.
      // If there is no additional media to be uploaded, [additionalMediaDownloadUrl] will be null
      String? additionalMediaDownloadUrl = await uploadAdditionalMediaIfItIsTheCase();


      print("Attempting to upload Data of Main Uploaded File to Firestore...");
      // So far we uploaded the raw content of the post
      // We also need to upload to Firestore the Document which represents the Post.
      // This Document contains all the information related to the Post.
      // We provide the title and description of the post from the text fields of the Dialog
      // And the imageUrl that we just fetched
      await _dbRepo.uploadMedia(
        mediaType: _mediaType!.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        mediaUrl: mainFileDownloadUrl,
        additionalMediaUrl: additionalMediaDownloadUrl,
      );
      print("Main File Data saved to Firestore");

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
      // DELETE orphan file
      if (mainFileDownloadUrl != null) {
        await _storageRepo.deleteMediaFromUrl(mainFileDownloadUrl);
      }

      // Present error message to user
      if (mounted) {
        print("UPLOAD ERROR: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to post. Check Console for details."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally { // finally executes whatever the case
      // wether the upload has completed succesfully or not, it has completed either way
      // so we set the state of _isUploading back to false, since we are not uploading anymore
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<String?> uploadAdditionalMediaIfItIsTheCase() async
  {
    // If additionalMedia has been imported in the dialog for upload:
    if (_additionalMediaInstance != null) {
      String? additionalMediaDownloadUrl;
      // check to see to which directory to upload additionalMedia based on main file type
      FolderPathEnum? folderPath;
      if(_mediaType == MediaType.video)
        folderPath = FolderPathEnum.thumbnail;
      else if (_mediaType == MediaType.audio)
        folderPath = FolderPathEnum.coverart;
      else
        throw Exception("Additional Media has been provided, but it is not suited for the main art uploaded, OR, _mediaType may be null");

      print("---- ATTEMPTING TO UPLOAD ADDITIONAL MEDIA...");
      additionalMediaDownloadUrl = await _storageRepo.uploadMedia(_additionalMediaInstance, folderPath: folderPath);
      print("---- ADDITIONAL MEDIA UPLOADED SUCCESFULLY");
      return additionalMediaDownloadUrl;
    }
    else {
      print("INFO: No Additional Media has been picked for uploading...");
      return null;
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
                  child: _fileInstance == null // if no file has been provided
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
                  // If main art has been provided, we will display the image + it's local machine name (if it has one)
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _mediaType==MediaType.image ? Image.memory(_fileAsBytes!) : Icon(Icons.file_copy), // displays image based on Byte data Uint8List (list of Bytes)
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

              // --- DYNAMIC THUMBNAIL PICKER ---
              if (_mediaType == MediaType.audio || _mediaType == MediaType.video) ...[
                _mediaType==MediaType.audio ? const Text("Add Cover Art (Optional)", style: TextStyle(fontWeight: FontWeight.bold)) : const Text("Add Thumbnail (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickThumbnail,
                  child: Container(
                    height: 100, // Smaller than the main picker
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      border: Border.all(color: Colors.grey, style: BorderStyle.none),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _additionalMediaInstance == null
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 32, color: Colors.grey),
                        SizedBox(height: 4),
                        Text("Click to select image", style: TextStyle(color: Colors.grey)),
                      ],
                    )
                        : Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(_additionalMediaBytes!, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Expanded(
                          child: Text(
                            _additionalMediaFileName ?? (_mediaType == MediaType.audio ? "Cover Art Image" : "Thumbnail Image"),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

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
                maxLength: 1000,
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
                    onPressed: (_isUploading || _fileInstance == null) ? null : _handleUpload,
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

  String? validatingPostBeforeUpload() {

    const int maxTitleLength = 100;
    const int maxDescriptionLength = 1000;
    const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB

    // Title validation
    if (_titleController.text.trim().isEmpty) {
      return "Please enter a title.";
    }

    final title = _titleController.text.trim();
    if (title.length > maxTitleLength) {
      return "Title is too long (max $maxTitleLength characters).";
    }

    // Description validation
    final description = _descriptionController.text.trim();
    if (description.length > maxDescriptionLength) {
      return "Description is too long (max $maxDescriptionLength characters).";
    }

    // Category validation
    if (_selectedCategory == null) {
      return "Please select a category.";
    }

    // Main file validation
    if (_fileInstance == null) {
      return "Please select a file to upload.";
    }

    // Media type validation
    if (_mediaType == null) {
      return "Unsupported media type.";
    }

    // File size validation
    if (_fileAsBytes != null && _fileAsBytes!.length > maxFileSizeBytes) {
      return "File is too large. Maximum size is 25MB.";
    }

    // Additional media validation
    if (_additionalMediaInstance != null &&
        !(_mediaType == MediaType.audio || _mediaType == MediaType.video)) {
      return "Additional media is only allowed for audio or video posts.";
    }

    return null; // everything is valid
  }

}