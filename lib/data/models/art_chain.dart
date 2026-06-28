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

    DateTime createdDate = DateTime.now();
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdDate = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime expirationDate = DateTime.now().add(const Duration(days: 7));
    if (data['expiresAt'] != null && data['expiresAt'] is Timestamp) {
      expirationDate = (data['expiresAt'] as Timestamp).toDate();
    }

    bool adminClosed = data['isClosed'] ?? false;
    bool timeExpired = DateTime.now().isAfter(expirationDate);

    return ArtChain(
      id: doc.id,
      title: data['title'] ?? 'Untitled Chain',
      description: data['description'] ?? '',
      createdAt: createdDate,
      expiresAt: expirationDate,
      isClosed: adminClosed || timeExpired,
        categoryNodes: List<String>.from(data['categoryNodes'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isClosed': isClosed,
      'categoryNodes': categoryNodes,
    };
  }
}