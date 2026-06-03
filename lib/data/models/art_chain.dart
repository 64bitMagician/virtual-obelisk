import 'package:cloud_firestore/cloud_firestore.dart';

class ArtChain {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isClosed;
  final List<String> categoryNodes;

  ArtChain({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.expiresAt,
    required this.isClosed,
    required this.categoryNodes,
  });

  factory ArtChain.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Safely parse the Timestamps to Dart DateTimes
    DateTime createdDate = DateTime.now();
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdDate = (data['createdAt'] as Timestamp).toDate();
    }

    // Default to a 7 day expiration if somehow missing
    DateTime expirationDate = DateTime.now().add(const Duration(days: 7));
    if (data['expiresAt'] != null && data['expiresAt'] is Timestamp) {
      expirationDate = (data['expiresAt'] as Timestamp).toDate();
    }

    // A chain is considered closed if the Admin manually closed it (isClosed == true)
    // or if the current date and time is past the expiration date.
    bool adminClosed = data['isClosed'] ?? false;
    bool timeExpired = DateTime.now().isAfter(expirationDate);

    return ArtChain(
      id: doc.id,
      title: data['title'] ?? 'Untitled Chain',
      description: data['description'] ?? '',
      createdAt: createdDate,
      expiresAt: expirationDate,
      isClosed: adminClosed || timeExpired, // Automatically seals the chain when time runs out
        categoryNodes: List<String>.from(data['categoryNodes'] ?? []),
    );
  }

  // A helper method to convert it back to a Map
  // for when Admin creates a new chain and uploads it to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      // Calculate the Timestamp for X days in the future
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isClosed': isClosed,
      'categoryNodes': categoryNodes,
    };
  }
}