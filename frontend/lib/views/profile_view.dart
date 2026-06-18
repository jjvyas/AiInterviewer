import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/interview_provider.dart';
import '../theme.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return isoString;
    }
  }

  String _formatJoinDate(String? isoString) {
    if (isoString == null) return "Joined Recently";
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "Joined ${months[dt.month - 1]} ${dt.year}";
    } catch (_) {
      return "Joined Recently";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Metadata Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              border: Border.all(color: AppTheme.textDark, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.accentHighlight,
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.currentUser?.userMetadata?['full_name'] ?? state.currentUser?.userMetadata?['name'] ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.currentUser?.email ?? 'Unknown Email',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              border: Border.all(color: AppTheme.textDark),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Active Prep",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatJoinDate(state.currentUser?.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Ledger Header
          const Text(
            "Mock Interview History & Ledger",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Select any past session to review feedback metrics and roadmap recommendations.",
            style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Historical chronological ledger list
          Expanded(
            child: state.pastInterviews.isEmpty
                ? Center(
                    child: Text(
                      "No interviews completed yet.",
                      style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.6)),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.pastInterviews.length,
                    itemBuilder: (context, index) {
                      final mock = state.pastInterviews[index];
                      final score = mock['overall_score'] as int;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentHighlight,
                            child: const Icon(Icons.assignment, color: Colors.white),
                          ),
                          title: Text(
                            "${mock['experience_tier']} ${mock['domain']} Mock",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Taken on: ${_formatDate(mock['created_at'])}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: state.isDarkMode ? AppTheme.cardBg : Colors.white,
                                  border: Border.all(color: AppTheme.textDark, width: 1.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Score: $score%",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: AppTheme.textDark),
                            ],
                          ),
                          onTap: () {
                            notifier.viewPastEvaluation(
                              mock['report'] ?? '# Mock Report',
                              score,
                              mock['domain'] ?? 'Backend',
                              mock['experience_tier'] ?? 'Mid',
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
