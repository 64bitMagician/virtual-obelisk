import 'package:art_platform/data/models/art_post.dart';
import 'package:flutter/material.dart';

/// Feature a Pull-up Handle to add the Post Information on the screen, without obscuring the art,
/// or interfering with the Video/Audio Players
class PostInfo extends StatefulWidget {
  final ArtPost post;
  final bool isVisible;

  const PostInfo({super.key, required this.post, required this.isVisible});

  @override
  State<PostInfo> createState() => _PostInfoState();
}

class _PostInfoState extends State<PostInfo> {
  // Local state to track if the user has pulled the info up
  bool _isExpanded = false;

  // Thigs gets triggered when you interact with the Pull-Up Handle
  // Pulling up -> _isExpanded == true
  // Pulling down -> _isExpended == false
  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We grab the screen width so we can manually apply it later
    final double screenWidth = MediaQuery.of(context).size.width;

    // this variable makes it so the PullUp Handler, when Expanded, does not get affected by the
    // timer going out of the parent, which normally hides this current widget
    final actuallyVisible = widget.isVisible || _isExpanded;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      bottom: actuallyVisible ? 0 : -250,
      left: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: actuallyVisible ? 1.0 : 0.0,

        // IgnorePointer prevents the widget from eating clicks when it fades out
        child: IgnorePointer(
          ignoring: !actuallyVisible,
          child: Container(
            decoration: BoxDecoration(
              gradient: _isExpanded
                  ? const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.black54, Colors.transparent],
              )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                // 1. THE DRAGGER BUTTON
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.delta.dy < -2 && !_isExpanded) _toggleExpand();
                      else if (details.delta.dy > 2 && _isExpanded) _toggleExpand();
                    },
                    child: InkWell(
                      onTap: _toggleExpand,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            const Text("Info", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. THE POST INFO
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.delta.dy > 2 && _isExpanded) _toggleExpand();
                    },
                    child: SizedBox(
                      width: screenWidth,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundImage: widget.post.authorAvatar == "default"
                                      ? const AssetImage('assets/icons/user-profile-icon.png') as ImageProvider
                                      : NetworkImage(widget.post.authorAvatar),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "by ${widget.post.authorName}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),

                            // --- SCROLLABLE DESCRIPTION ---
                            if (widget.post.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                // Restrict the maximum height so it doesn't cover the whole screen!
                                // This limits the box to 30% of the screen height.
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                                ),
                                child: SingleChildScrollView(
                                  // Bouncing physics feels native and smooth on mobile
                                  physics: const BouncingScrollPhysics(),
                                  child: Text(
                                    widget.post.description,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.4, // Adds nice line spacing for readability
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}