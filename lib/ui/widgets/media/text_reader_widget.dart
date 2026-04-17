import 'package:art_platform/data/models/art_post.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TextReaderWidget extends StatefulWidget {
  final ArtPost post;
  final bool postInformationVisible;

  const TextReaderWidget({
    super.key,
    required this.post,
    required this.postInformationVisible,
  });

  @override
  State<TextReaderWidget> createState() => _TextReaderWidgetState();
}

class _TextReaderWidgetState extends State<TextReaderWidget> {
  String? _textContent;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchTextContent();
  }

  Future<void> _fetchTextContent() async {
    try {
      // Download the raw text from the Firebase Storage URL
      final response = await http.get(Uri.parse(widget.post.mediaUrl));

      if (response.statusCode == 200) {
        // Decode the text (utf8 ensures emojis and special characters work!)
        if (mounted) {
          setState(() {
            _textContent = response.body;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load text. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching text: $e");
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    }
  }

  // --- THE AUTO-FORMATTING MAGIC ---
  // Analyzes the text to determine if it's a poem or prose
  TextAlign _determineAlignment(String text) {
    final lines = text.split('\n');
    int totalCharacters = 0;
    int validLinesCount = 0;

    for (var line in lines) {
      if (line.trim().isNotEmpty) {
        totalCharacters += line.trim().length;
        validLinesCount++;
      }
    }

    // Prevent division by zero on empty files
    if (validLinesCount == 0) return TextAlign.left;

    final double averageLineLength = totalCharacters / validLinesCount;

    // If the average line is short (under 45 characters), it's probably a poem!
    if (averageLineLength < 45) {
      return TextAlign.center;
    } else {
      return TextAlign.left;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_isError || _textContent == null) {
      return const Center(
        child: Text('Error loading text content.', style: TextStyle(color: Colors.red)),
      );
    }

    // Calculate our smart alignment
    final TextAlign smartAlignment = _determineAlignment(_textContent!);

    return Container(
      color: Colors.grey[900], // Consistent dark theme
      width: double.infinity,
      height: double.infinity,
      // We use InteractiveViewer so users can pinch-to-zoom if the text is too small!
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 3.0,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          // Generous padding makes reading much more comfortable
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 250),
          child: Text(
            _textContent!,
            textAlign: smartAlignment,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 18,
              height: 1.6, // 160% line height is the gold standard for reading
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}