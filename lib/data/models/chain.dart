class Chain {
  final String id;
  final String title;
  final String initiatorName;
  final String status;
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
  final String type;
  final bool isCompleted;
  final String? contributorName;
  final String? contentUrl;

  ChainStep({
    required this.id,
    required this.type,
    required this.isCompleted,
    this.contributorName,
    this.contentUrl,
  });
}