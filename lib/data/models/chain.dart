class Chain {
  final String id;
  final String title;
  final String initiatorName; // Who started it
  final String status; // "Active", "Completed"
  final List<ChainStep> steps;

  Chain({
    required this.id,
    required this.title,
    required this.initiatorName,
    required this.status,
    required this.steps,
  });
}

class ChainStep {
  final String id;
  final String type; // 'image', 'audio', 'text'
  final bool isCompleted;
  final String? contributorName;
  final String? contentUrl; // URL to the image/audio or the actual text

  ChainStep({
    required this.id,
    required this.type,
    required this.isCompleted,
    this.contributorName,
    this.contentUrl,
  });
}