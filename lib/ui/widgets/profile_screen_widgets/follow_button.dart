import 'package:flutter/material.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowButton extends StatefulWidget {
  final String targetUid;

  const FollowButton({super.key, required this.targetUid});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  final DatabaseRepository _repo = DatabaseRepository();
  final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _checkFollowState();
  }

  Future<void> _checkFollowState() async {
    if (currentUid == null) return;

    try {
      bool isFollowing = await _repo.isFollowing(currentUid!, widget.targetUid);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking follow state: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (currentUid == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFollowing) {
        await _repo.unfollowUser(currentUid!, widget.targetUid);
      } else {
        await _repo.followUser(currentUid!, widget.targetUid);
      }

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error toggling follow: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action failed. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        width: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return SizedBox(
      width: 200,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? Colors.grey[800] : Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: _toggleFollow,
        child: Text(
          _isFollowing ? "Following" : "Follow",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}