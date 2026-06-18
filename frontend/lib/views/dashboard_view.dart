import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/interview_provider.dart';
import '../theme.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);

    // Calculate aggregates
    final mocksCount = state.pastInterviews.length;
    final avgScore = mocksCount > 0
        ? (state.pastInterviews.map((e) => e['overall_score'] as int).reduce((a, b) => a + b) / mocksCount).round()
        : 0;

    String rank = "Junior";
    if (avgScore >= 85) {
      rank = "Senior Developer";
    } else if (avgScore >= 70) {
      rank = "Mid-Level Engineer";
    } else if (mocksCount > 0) {
      rank = "Junior Developer";
    } else {
      rank = "Not Rated Yet";
    }

    final isNarrow = MediaQuery.of(context).size.width < 900;

    Widget headerSection = isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back, Developer",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                "Track your performance progress and start mock interviews",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textDark.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text("New Interview"),
                  onPressed: () => notifier.setView('setup'),
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back, Developer",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Track your performance progress and start mock interviews",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textDark.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.rocket_launch),
                label: const Text("New Interview"),
                onPressed: () => notifier.setView('setup'),
              ),
            ],
          );

    Widget metricsSection = isNarrow
        ? Column(
            children: [
              _buildMetricCard(
                context,
                "Mocks Completed",
                "$mocksCount",
                Icons.assignment_turned_in,
                AppTheme.accentHighlight,
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                context,
                "Average Score",
                mocksCount > 0 ? "$avgScore%" : "--",
                Icons.trending_up,
                AppTheme.cardBg,
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                context,
                "Overall Rank",
                rank,
                Icons.military_tech,
                AppTheme.panelBg,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  "Mocks Completed",
                  "$mocksCount",
                  Icons.assignment_turned_in,
                  AppTheme.accentHighlight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  "Average Score",
                  mocksCount > 0 ? "$avgScore%" : "--",
                  Icons.trending_up,
                  AppTheme.cardBg,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  "Overall Rank",
                  rank,
                  Icons.military_tech,
                  AppTheme.panelBg,
                ),
              ),
            ],
          );

    Widget panelsSection = isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgressTracker(context, mocksCount, state),
              const SizedBox(height: 20),
              _buildQuickStartSection(notifier),
              const SizedBox(height: 16),
              _buildEliteCoachTip(),
            ],
          )
        : Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildProgressTracker(context, mocksCount, state),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildQuickStartSection(notifier),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildEliteCoachTip(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerSection,
        const SizedBox(height: 32),
        metricsSection,
        const SizedBox(height: 32),
        panelsSection,
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: isNarrow
          ? SingleChildScrollView(child: content)
          : content,
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppTheme.textDark, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          Icon(icon, size: 36, color: AppTheme.textDark.withValues(alpha: 0.8)),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(BuildContext context, int mocksCount, dynamic state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        border: Border.all(color: AppTheme.textDark, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Recent Progress Tracker",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (mocksCount == 0)
            Container(
              height: 150,
              alignment: Alignment.center,
              child: Text(
                "No interview metrics recorded yet. Complete a mock to view charts.",
                style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.6)),
              ),
            )
          else
            Column(
              children: state.pastInterviews.map<Widget>((mock) {
                final score = mock['overall_score'] as int;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${mock['experience_tier']} ${mock['domain']} Mock",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("$score%"),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.textDark, width: 1),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: score / 100.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.accentHighlight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStartSection(dynamic notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.textDark, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description, size: 36, color: AppTheme.textDark),
          const SizedBox(height: 12),
          Text(
            "Resume Labs",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload your resume to perform gap analysis and inject customized experience parameters into interviews.",
            style: TextStyle(fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textDark,
              ),
              onPressed: () => notifier.setView('resume_labs'),
              child: const Text("Open Resume Labs"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEliteCoachTip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        border: Border.all(color: AppTheme.textDark, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 28, color: AppTheme.accentHighlight),
          const SizedBox(height: 8),
          const Text(
            "Elite Coach Tip",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            "When answering system architecture questions, explicitly describe the trade-offs (e.g., latency vs. write throughput) to score a completeness metric >= 0.8.",
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
