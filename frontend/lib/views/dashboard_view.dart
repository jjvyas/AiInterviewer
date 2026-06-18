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
        ? (state.pastInterviews
                      .map((e) => e['overall_score'] as int)
                      .reduce((a, b) => a + b) /
                  mocksCount)
              .round()
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

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    // Header Content
    Widget header = isMobile
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

    // Metrics widgets list
    List<Widget> metricCards = [
      _buildMetricCard(
        context,
        "Mocks Completed",
        "$mocksCount",
        Icons.assignment_turned_in,
        AppTheme.accentHighlight,
      ),
      _buildMetricCard(
        context,
        "Average Score",
        mocksCount > 0 ? "$avgScore%" : "--",
        Icons.trending_up,
        AppTheme.cardBg,
      ),
      _buildMetricCard(
        context,
        "Overall Rank",
        rank,
        Icons.military_tech,
        AppTheme.panelBg,
      ),
    ];

    Widget metricsWidget = isMobile
        ? Column(
            children: metricCards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: card,
                  ),
                )
                .toList(),
          )
        : Row(
            children: metricCards
                .map(
                  (card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: card,
                    ),
                  ),
                )
                .toList(),
          );

    // Chart content
    Widget chartCard = Container(
      padding: const EdgeInsets.all(20),
      height: 300, // Fixed height for vertical layout compatibility
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        border: Border.all(color: AppTheme.textDark, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Progress Tracker",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (mocksCount == 0)
            Expanded(
              child: Center(
                child: Text(
                  "No interview metrics recorded yet. Complete a mock to view charts.",
                  style: TextStyle(
                    color: AppTheme.textDark.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: state.pastInterviews.map((mock) {
                  final score = mock['overall_score'] as int;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${mock['experience_tier']} ${mock['domain']} Mock",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("$score%"),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: state.isDarkMode
                                ? const Color(0xFF222228)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
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
            ),
        ],
      ),
    );

    // Resume labs promo card
    Widget resumeCard = Container(
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
                backgroundColor: state.isDarkMode
                    ? AppTheme.accentHighlight
                    : Colors.white,
                foregroundColor: state.isDarkMode
                    ? Colors.white
                    : AppTheme.textDark,
              ),
              onPressed: () => notifier.setView('resume_labs'),
              child: const Text("Open Resume Labs"),
            ),
          ),
        ],
      ),
    );

    // Tip card
    Widget tipCard = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: state.isDarkMode
            ? AppTheme.panelBg
            : Colors.white.withValues(alpha: 0.5),
        border: Border.all(color: AppTheme.textDark, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 28,
            color: AppTheme.accentHighlight,
          ),
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

    Widget dashboardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 32),
        metricsWidget,
        const SizedBox(height: 32),
        if (isMobile) ...[
          chartCard,
          const SizedBox(height: 20),
          resumeCard,
          const SizedBox(height: 20),
          tipCard,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: chartCard),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  children: [resumeCard, const SizedBox(height: 16), tipCard],
                ),
              ),
            ],
          ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: dashboardContent,
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isAccent = color == AppTheme.accentHighlight;
    final textColor = isAccent ? Colors.white : AppTheme.textDark;
    final iconColor = isAccent
        ? Colors.white.withValues(alpha: 0.8)
        : AppTheme.textDark.withValues(alpha: 0.8);

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
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          Icon(icon, size: 36, color: iconColor),
        ],
      ),
    );
  }
}
