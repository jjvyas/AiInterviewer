import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/interview_provider.dart';
import '../theme.dart';

class EvaluationView extends ConsumerWidget {
  const EvaluationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);

    final reportMd = state.reportMarkdown ?? """# No report available.
Please complete a mock interview session first.""";

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Overall Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Interview Evaluation Report",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Detailed technical assessment for ${state.experienceTier} ${state.domain} Mock",
                    style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              
              // Score circular badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentHighlight,
                  border: Border.all(color: AppTheme.textDark, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "OVERALL SCORE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${state.overallScore}",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Markdown Content Box
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                border: Border.all(color: AppTheme.textDark, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Markdown(
                data: reportMd,
                styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accentHighlight, height: 1.6),
                  h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.5),
                  p: TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textDark),
                  tableHead: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  tableHeadAlign: TextAlign.center,
                  tableBorder: TableBorder.all(color: AppTheme.textDark, width: 1),
                  tableCellsPadding: const EdgeInsets.all(8),
                  tableBody: TextStyle(fontSize: 13, color: AppTheme.textDark),
                  listBullet: TextStyle(color: AppTheme.accentHighlight),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Return Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textDark,
                  side: BorderSide(color: AppTheme.textDark, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  notifier.setView('dashboard');
                },
                child: const Text("Return to Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
