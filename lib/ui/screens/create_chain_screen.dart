import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:art_platform/core/constants.dart';

class CreateChainScreen extends StatefulWidget {
  const CreateChainScreen({super.key});

  @override
  State<CreateChainScreen> createState() => _CreateChainScreenState();
}

class _CreateChainScreenState extends State<CreateChainScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseRepository _repo = DatabaseRepository();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _lifespanController = TextEditingController(text: "7");

  final List<String?> _chainNodes = [];

  final List<String> _categories = artCategories;
  final Map<String, String> _categoryDisplayNames = artCategoriesDisplayName;

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _lifespanController.dispose();
    super.dispose();
  }

  List<String> _getAvailableCategories(int currentIndex) {
    return _categories.where((category) {
      return !_chainNodes.contains(category) || _chainNodes[currentIndex] == category;
    }).toList();
  }

  Future<void> _submitChain() async {
    if (!_formKey.currentState!.validate()) return;

    if (_chainNodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must add at least one category node to the chain")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final int days = int.parse(_lifespanController.text.trim());

      final List<String> finalSequence = _chainNodes.whereType<String>().toList();

      await _repo.createChain(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        lifespanDays: days,
        categoryNodes: finalSequence,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Art Chain Launched Successfully"), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Launch Art Chain"),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 100,
                decoration: const InputDecoration(labelText: "Chain Title", border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Prompt Description", border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lifespanController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: "Lifespan (Days)", border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),

              const Divider(height: 48, thickness: 2),

              const Text("Chain Sequence Builder", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Define the exact order of art categories. You cannot use the same category twice.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),

              if (_chainNodes.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _chainNodes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final availableCategories = _getAvailableCategories(index);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 12.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            radius: 16,
                            child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _chainNodes[index],
                            decoration: const InputDecoration(
                              labelText: "Select Category",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: availableCategories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(_categoryDisplayNames[category] ?? category),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _chainNodes[index] = newValue;
                              });
                            },
                            validator: (value) => value == null ? "Please select a category" : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _chainNodes.removeAt(index);
                            });
                          },
                        )
                      ],
                    );
                  },
                ),

              const SizedBox(height: 16),

              if (_chainNodes.length < _categories.length)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    side: BorderSide(color: Colors.deepPurple.shade300, width: 2),
                  ),
                  onPressed: () {
                    setState(() {
                      _chainNodes.add(null);
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.deepPurpleAccent),
                  label: const Text("Add New Node", style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
                ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitChain,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.rocket_launch),
                  label: Text(_isLoading ? "Launching..." : "Launch Chain"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}