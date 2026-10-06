import 'package:flutter/material.dart';
import 'package:art_platform/data/repositories/database_repository.dart';

class AdminReportOverlay extends StatelessWidget {
  final String artworkId;
  final bool isVisible;

  const AdminReportOverlay({
    super.key,
    required this.artworkId,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final DatabaseRepository repo = DatabaseRepository();

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "User Reports",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const Divider(color: Colors.white30, height: 24),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: repo.getReportsForPost(artworkId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                    }
                    if (snapshot.hasError) {
                      return Text("Error loading reports: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("No reports found.\n(Deactivated manually?)",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70)),
                      );
                    }

                    final reports = snapshot.data!;
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final report = reports[index];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Reason: ${report['reason'] ?? 'None'}",
                                  style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)
                              ),
                              if (report['additionalNotes'] != null && report['additionalNotes'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                      '"${report['additionalNotes']}"',
                                      style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13)
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}