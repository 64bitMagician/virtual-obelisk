import 'package:art_platform/data/models/art_post.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TextReaderWidget extends StatefulWidget {
  final ArtPost post;
  final bool postInformationVisible;
  final VoidCallback callStartHideTimer;

  const TextReaderWidget({
    super.key,
    required this.post,
    required this.postInformationVisible,
    required this.callStartHideTimer, // 🚨 ADDED CALLBACK
  });

  @override
  State<TextReaderWidget> createState() => _TextReaderWidgetState();
}

class _TextReaderWidgetState extends State<TextReaderWidget> {
  String? _fullTextContent;
  bool _isLoading = true;
  bool _isError = false;

  // Pagination State
  List<String> _pages = [];
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // Typography Settings
  final TextStyle _textStyle = const TextStyle(
    color: Colors.white70,
    fontSize: 18,
    height: 1.6,
    letterSpacing: 0.3,
  );

  // Caches the screen size so we don't recalculate math during page-turn animations!
  Size? _lastCalculatedSize;

  @override
  void initState() {
    super.initState();
    _fetchTextContent();
  }

  Future<void> _fetchTextContent() async {
    try {
      final response = await http.get(Uri.parse(widget.post.mediaUrl));

      if (response.statusCode == 200) {
        // Force UTF-8 decoding and replace invisible tabs with 4 physical spaces
        String decodedText = utf8.decode(response.bodyBytes).replaceAll('\t', '    ');

        // The Text Normalizer!
        List<String> lines = decodedText.split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].trim().isNotEmpty && lines[i].startsWith(RegExp(r'[ \t]+'))) {
            lines[i] = '    ' + lines[i].trimLeft();
          }
        }
        decodedText = lines.join('\n');

        if (mounted) {
          setState(() {
            _fullTextContent = decodedText;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load text.");
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

    if (validLinesCount == 0) return TextAlign.left;
    final double averageLineLength = totalCharacters / validLinesCount;

    return averageLineLength < 45 ? TextAlign.center : TextAlign.left;
  }

  // --- THE PAGINATION ALGORITHM ---
  void _calculatePages(Size availableSize, BuildContext context) {
    if (_fullTextContent == null || availableSize.height <= 0) return;

    final bool isPoetry = _determineAlignment(_fullTextContent!) == TextAlign.center;
    final textScaler = MediaQuery.textScalerOf(context);

    List<String> newPages = [];
    int startOffset = 0;

    while (startOffset < _fullTextContent!.length) {

      // Clean up the startOffset BEFORE we run the math so TextPainter is perfectly accurate
      while (startOffset < _fullTextContent!.length &&
          (_fullTextContent![startOffset] == '\n' || _fullTextContent![startOffset] == '\r')) {
        startOffset++;
      }

      if (startOffset < _fullTextContent!.length && _fullTextContent![startOffset] == ' ') {
        int spaceCount = 0;
        int temp = startOffset;
        while (temp < _fullTextContent!.length && _fullTextContent![temp] == ' ') {
          spaceCount++;
          temp++;
        }

        if (spaceCount == 1) {
          startOffset++;
        }
      }

      if (startOffset >= _fullTextContent!.length) break;

      int low = startOffset;
      int high = _fullTextContent!.length;
      int bestEnd = startOffset;

      while (low <= high) {
        int mid = (low + high) ~/ 2;
        String substring = _fullTextContent!.substring(startOffset, mid);

        final textPainter = TextPainter(
          text: TextSpan(text: substring, style: _textStyle),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        );
        textPainter.layout(maxWidth: availableSize.width);

        if (textPainter.size.height <= availableSize.height) {
          bestEnd = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      // Typography Backtracking Logic
      if (bestEnd < _fullTextContent!.length) {
        String currentSlice = _fullTextContent!.substring(startOffset, bestEnd);

        bool isPerfectCut = RegExp(r'\s').hasMatch(_fullTextContent![bestEnd]) ||
            RegExp(r'\s').hasMatch(currentSlice[currentSlice.length - 1]);

        int lastBlankLine = currentSlice.lastIndexOf(RegExp(r'\n\s*\n'));
        int lastNewline = currentSlice.lastIndexOf('\n');
        int lastSpace = currentSlice.lastIndexOf(RegExp(r'\s'));

        if (isPoetry) {
          if (lastBlankLine > (currentSlice.length * 0.5)) {
            bestEnd = startOffset + lastBlankLine;
          } else if (lastNewline > (currentSlice.length * 0.75)) {
            bestEnd = startOffset + lastNewline;
          } else if (!isPerfectCut && lastSpace > 0) {
            bestEnd = startOffset + lastSpace;
          }
        } else {
          if (!isPerfectCut && lastSpace > 0) {
            bestEnd = startOffset + lastSpace;
          }
        }
      }

      // Use .trimRight() to protect our beautiful new leading indents!
      newPages.add(_fullTextContent!.substring(startOffset, bestEnd).trimRight());
      startOffset = bestEnd;

      if (startOffset >= _fullTextContent!.length) break;
    }

    if (_pages.length != newPages.length || (_pages.isNotEmpty && _pages[0] != newPages[0])) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pages = newPages);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_isError || _fullTextContent == null) return const Center(child: Text('Error loading text content.', style: TextStyle(color: Colors.red)));

    final smartAlignment = _determineAlignment(_fullTextContent!);

    return Container(
      color: Colors.grey[900],
      width: double.infinity,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double horizontalPadding = 48.0;
          const double verticalPadding = 200.0;

          final availableSize = Size(
            constraints.maxWidth - horizontalPadding,
            constraints.maxHeight - verticalPadding,
          );

          if (_lastCalculatedSize != availableSize) {
            _lastCalculatedSize = availableSize;
            _calculatePages(availableSize, context);
          }

          if (_pages.isEmpty) return const SizedBox.shrink();

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 140),
                    child: Text(
                      _pages[index],
                      textAlign: smartAlignment,
                      style: _textStyle,
                    ),
                  );
                },
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                bottom: widget.postInformationVisible ? 80 : -50,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: widget.postInformationVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !widget.postInformationVisible,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // --- LEFT ARROW ---
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _currentPage > 0 ? 1.0 : 0.3,
                          child: GestureDetector(
                            onTap: _currentPage > 0 ? () {
                              widget.callStartHideTimer(); // 🚨 RESET TIMER!
                              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            } : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_left, color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // --- PAGE INDICATOR ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Page ${_currentPage + 1} of ${_pages.length}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // --- RIGHT ARROW ---
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.3,
                          child: GestureDetector(
                            onTap: _currentPage < _pages.length - 1 ? () {
                              widget.callStartHideTimer(); // 🚨 RESET TIMER!
                              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            } : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_right, color: Colors.white),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}