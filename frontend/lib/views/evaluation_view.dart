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

    final isNarrow = MediaQuery.of(context).size.width < 750;

    Widget scoreBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentHighlight,
            AppTheme.goldAccent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentHighlight.withValues(alpha: 0.35),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.white24, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "OVERALL SCORE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${state.overallScore}",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );

    Widget headerSection = isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Interview Evaluation Report",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                "Detailed technical assessment for ${state.experienceTier} ${state.domain} Mock",
                style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              scoreBadge,
            ],
          )
        : Row(
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
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Detailed technical assessment for ${state.experienceTier} ${state.domain} Mock",
                    style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              scoreBadge,
            ],
          );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          headerSection,
          const SizedBox(height: 24),

          // Markdown Content Box (frosted card glassmorphism)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
<<<<<<< HEAD
                color: AppTheme.cardBg.withValues(alpha: 0.35),
                border: Border.all(color: AppTheme.borderColor, width: 1.2),
                borderRadius: BorderRadius.circular(16),
=======
                color: AppTheme.cardBg,
                border: Border.all(color: AppTheme.textDark, width: 1.5),
                borderRadius: BorderRadius.circular(12),
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
              ),
              child: Markdown(
                data: reportMd,
                styleSheet: MarkdownStyleSheet(
<<<<<<< HEAD
                  h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentHighlight, height: 1.6),
                  h2: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldAccent, height: 1.5),
                  p: TextStyle(fontSize: 13.5, height: 1.5, color: AppTheme.textDark),
=======
                  h1: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accentHighlight, height: 1.6),
                  h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.5),
                  p: TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textDark),
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
                  tableHead: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  tableHeadAlign: TextAlign.center,
                  tableBorder: TableBorder.all(color: AppTheme.borderColor, width: 1),
                  tableCellsPadding: const EdgeInsets.all(8),
<<<<<<< HEAD
                  tableBody: TextStyle(fontSize: 12.5, color: AppTheme.textDark.withValues(alpha: 0.9)),
=======
                  tableBody: TextStyle(fontSize: 13, color: AppTheme.textDark),
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
                  listBullet: TextStyle(color: AppTheme.accentHighlight),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Return Action Button
          Row(
            mainAxisAlignment: isNarrow ? MainAxisAlignment.center : MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textDark,
                  side: BorderSide(color: AppTheme.textDark, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
