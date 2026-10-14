import 'dart:typed_data';
import 'package:art_platform/core/constants.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/core/mime_file_detector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../data/repositories/database_repository.dart';

class UploadDialog extends StatefulWidget {
  final String? chainId;
  final List<String>? allowedCategories;

  const UploadDialog({super.key, this.chainId, this.allowedCategories});

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  IconData suggestiveFileTypeIcon = Icons.question_mark;

  double _uploadProgress = 0.0;

  final StorageRepository _storageRepo = StorageRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  final ScrollController _formScrollController = ScrollController();

  String? _selectedFileName;
  bool _isUploading = false;
  XFile? _fileInstance;
  Uint8List? _fileAsBytes;
  MediaType? _mediaType;

  XFile? _additionalMediaInstance;
  Uint8List? _additionalMediaBytes;
  String? _additionalMediaFileName;

  String? _selectedCategory;
  late final List<String> _categories;
  final Map<String, String> _categoryDisplayNames = artCategoriesDisplayName;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categories = widget.allowedCategories ?? artCategories;

    if (_categories.length == 1) {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _formScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      PlatformFile pickedFile = result.files.first;
      Uint8List bytesContent = pickedFile.bytes!;

      XFile file = XFile.fromData(
        bytesContent,
        name: pickedFile.name,
        path: pickedFile.path,
      );

      setState(() {
        _additionalMediaInstance = file;
        _additionalMediaFileName = file.name;
        _additionalMediaBytes = bytesContent;
      });
    }
  }


  Future<void> _pickMainFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        // Images
        'jpg', 'jpeg', 'png', 'gif', 'webp',
        // Audio
        'mp3', 'wav', 'ogg', 'm4a',
        // Video
        'mp4', 'mov', 'avi', 'mkv',
        // Text
        'txt'
      ],
      withData: true,
    );

    if (result != null) {
      PlatformFile pickedFile = result.files.first;
      Uint8List bytesContent = pickedFile.bytes!;

      XFile file = XFile.fromData(
        bytesContent,
        name: pickedFile.name,
        path: pickedFile.path,
      );

      final newMediaType = determineMediaTypeFromFile(file.name, bytesContent);

      IconData icon = Icons.question_mark;
      if (newMediaType == MediaType.audio) {
        icon = Icons.audio_file_outlined;
      } else if (newMediaType == MediaType.video) {
        icon = Icons.video_file_outlined;
      } else if (newMediaType == MediaType.text) {
        icon = Icons.text_snippet_outlined;
      }

      setState(() {
        _fileInstance = file;
        _selectedFileName = file.name;
        _fileAsBytes = bytesContent;
        // get MediaType of file
        _mediaType = newMediaType;
        suggestiveFileTypeIcon = icon;

          _additionalMediaInstance = null;
          _additionalMediaFileName = null;
          _additionalMediaBytes = null;
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
    String? additionalMediaDownloadUrl;

    try {
      debugPrint("ATTEMPTING TO UPLOAD FILE AT FIREBASE CLOUD BUCKET...");

      mainFileDownloadUrl = await _storageRepo.uploadMedia(
        _fileInstance,
        folderPath: FolderPathEnum.artworks,
        onProgress: (progress) {
          if (mounted){
            setState(() {
              _uploadProgress = progress;
            });
          }
        }
      );
      debugPrint("Main File uploaded to $mainFileDownloadUrl");

      // If there is additional media to be uploaded, [additionalMediaDownloadUrl] will hold the
      // string Url to that Media.
      // If there is no additional media to be uploaded, [additionalMediaDownloadUrl] will be null
      additionalMediaDownloadUrl = await uploadAdditionalMediaIfItIsTheCase();


      debugPrint("Attempting to upload Data Document of Main Uploaded File to Firestore...");
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
        chainId: widget.chainId,
      );
      debugPrint("Main File Data saved to Firestore");

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
      if (mainFileDownloadUrl != null) {
        await _storageRepo.deleteMediaFromUrl(mainFileDownloadUrl);
      }

      if (additionalMediaDownloadUrl != null) {
        await _storageRepo.deleteMediaFromUrl(additionalMediaDownloadUrl);
      }

      if (mounted) {
        debugPrint("UPLOAD ERROR: $e");
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
      if(_mediaType == MediaType.video) {
        folderPath = FolderPathEnum.thumbnail;
      } else if (_mediaType == MediaType.audio) {
        folderPath = FolderPathEnum.coverart;
      } else {
        throw Exception("Additional Media has been provided, but it is not suited for the main art uploaded, or, _mediaType may be null");
      }

      debugPrint("---- ATTEMPTING TO UPLOAD ADDITIONAL MEDIA...");
      additionalMediaDownloadUrl = await _storageRepo.uploadMedia(_additionalMediaInstance, folderPath: folderPath);
      debugPrint("---- ADDITIONAL MEDIA UPLOADED SUCCESFULLY");
      return additionalMediaDownloadUrl;
    }
    else {
      debugPrint("INFO: No Additional Media has been picked for uploading...");
      return null;
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
              "Upload Dialog",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            Flexible(
              child: Scrollbar(
                controller: _formScrollController,
                thumbVisibility: true,
                thickness: 6.0,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  controller: _formScrollController,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _pickMainFile,
                        child: Container(
                          height: 125,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _fileInstance == null
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
                                  padding: const EdgeInsets.all(8),
                                  child: _mediaType == MediaType.image
                                      ? Image.memory(_fileAsBytes!)
                                      : Icon(suggestiveFileTypeIcon, size: 48,),
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

                      if (_mediaType == MediaType.audio || _mediaType == MediaType.video) ...[
                        _mediaType == MediaType.audio
                            ? const Text("Add Cover Art (Optional)", style: TextStyle(fontWeight: FontWeight.bold))
                            : const Text("Add Thumbnail (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickThumbnail,
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
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
                        const SizedBox(height: 16),
                      ],

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _titleController,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: "Title",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            flex: 2,
                            child: DropdownMenu<String>(
                              initialSelection: _selectedCategory,
                              label: const Text("Category"),
                              expandedInsets: EdgeInsets.zero,
                              enableSearch: true,
                              menuHeight: 250,
                              dropdownMenuEntries: _categories.map<DropdownMenuEntry<String>>((String category) {
                                return DropdownMenuEntry<String>(
                                  value: category,
                                  label: _categoryDisplayNames[category]!,
                                );
                              }).toList(),
                              onSelected: (String? newSelectedCategory) {
                                setState(() {
                                  _selectedCategory = newSelectedCategory;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  onPressed: (_isUploading || _fileInstance == null) ? null : _handleUpload,
                  child: _isUploading
                      ? SizedBox(
                    width: 200,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: 6),
                        Text("${(_uploadProgress * 100).toStringAsFixed(1)}%"),
                      ],
                    ),
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

  String? validatingPostBeforeUpload() {

    const int maxTitleLength = 100;
    const int maxDescriptionLength = 1000;
    // Must match the size limit for 'artworks' in storage.rules
    const int maxFileSizeBytes = 500 * 1024 * 1024; // 500 MB

    if (_titleController.text.trim().isEmpty) {
      return "Please enter a title.";
    }

    final title = _titleController.text.trim();
    if (title.length > maxTitleLength) {
      return "Title is too long (max $maxTitleLength characters).";
    }

    final description = _descriptionController.text.trim();
    if (description.length > maxDescriptionLength) {
      return "Description is too long (max $maxDescriptionLength characters).";
    }

    if (_selectedCategory == null) {
      return "Please select a category.";
    }

    if (_fileInstance == null) {
      return "Please select a file to upload.";
    }

    if (_mediaType == null) {
      return "Unsupported media type.";
    }

    if (_fileAsBytes != null && _fileAsBytes!.length > maxFileSizeBytes) {
      return "File is too large. Maximum size is 500MB.";
    }

    if (_additionalMediaInstance != null &&
        !(_mediaType == MediaType.audio || _mediaType == MediaType.video)) {
      return "Additional media is only allowed for audio or video posts.";
    }

    return null;
  }

}