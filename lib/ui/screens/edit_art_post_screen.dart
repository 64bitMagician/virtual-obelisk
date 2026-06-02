import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:art_platform/core/constants.dart';

class EditArtPostScreen extends StatefulWidget {
  final ArtPost post;

  const EditArtPostScreen({super.key, required this.post});

  @override
  State<EditArtPostScreen> createState() => _EditArtPostScreenState();
}

class _EditArtPostScreenState extends State<EditArtPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseRepository _repo = DatabaseRepository();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  // Category State Variables
  String? _selectedCategory;
  final List<String> _categories = artCategories;
  final Map<String, String> _categoryDisplayNames = artCategoriesDisplayName;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _descriptionController = TextEditingController(text: widget.post.description);

    if (_categories.contains(widget.post.category)) {
      _selectedCategory = widget.post.category;
    } else {
      _selectedCategory = _categories.first; // Safe fallback
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _repo.editPost(
        widget.post.id,
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _selectedCategory!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post updated successfully!"), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Post"),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Category side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _titleController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Title cannot be empty" : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Category Dropdown
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

              // No extra SizedBox needed because maxLength provides natural padding

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 1000,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("Save Changes"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}