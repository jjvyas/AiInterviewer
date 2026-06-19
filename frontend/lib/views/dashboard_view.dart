import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/interview_provider.dart';
import '../theme.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  String _formatDate(String? isoString) {
    if (isoString == null) return "Recent Date";
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return "Recent";
    }
  }

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
      rank = "Mid Engineer";
    } else if (mocksCount > 0) {
      rank = "Junior Dev";
    } else {
      rank = "Not Rated";
    }

<<<<<<< HEAD
    final isNarrow = MediaQuery.of(context).size.width < 950;

    // Domain Tags List (Pill drop filters)
    final domainTags = ['All Domains', 'Frontend', 'Backend', 'DevOps', 'Full-Stack'];

    // 1. Center Panel Widgets
    Widget centerPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Title
        Text(
          "Welcome Back, Developer",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          "Analyze mock parameters, optimize phrasing, and review historical performance.",
          style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.6), fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Domain Filters & Call to Action Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row of domain tags
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: domainTags.map((tag) {
                    final isSelected = tag == 'All Domains'; // Mock first selected
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: AppTheme.accentHighlight.withValues(alpha: 0.2),
                        backgroundColor: AppTheme.cardBg.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.accentHighlight : AppTheme.textDark.withValues(alpha: 0.6),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.accentHighlight : AppTheme.borderColor,
                            width: 1.0,
                          ),
                        ),
                        onSelected: (_) {},
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Accented glowing CTA button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentHighlight.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
=======
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
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.rocket_launch, size: 16),
                label: const Text("New Mock", style: TextStyle(fontSize: 13)),
                onPressed: () => notifier.setView('setup'),
<<<<<<< HEAD
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: AppTheme.accentHighlight,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // History Wide List Cards Section
        const Text(
          "Historical Chronological Ledger",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        
        if (mocksCount == 0)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                "No completed mock evaluations yet. Launch an interview to log telemetry.",
                style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          Column(
            children: state.pastInterviews.map<Widget>((mock) {
              final score = mock['overall_score'] as int;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  border: Border.all(color: AppTheme.borderColor, width: 1.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Icon circle
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.accentHighlight.withValues(alpha: 0.15),
                      child: Icon(Icons.computer, color: AppTheme.accentHighlight, size: 20),
                    ),
                    const SizedBox(width: 16),

                    // Title and metadata subline
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${mock['experience_tier']} ${mock['domain']} Mock",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Date: ${_formatDate(mock['created_at'])}",
                                style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.5), fontSize: 11),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppTheme.textDark.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                mock['domain'] ?? 'Backend',
                                style: TextStyle(color: AppTheme.accentHighlight, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Avatar Stack Cluster
                    if (!isNarrow) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 54,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppTheme.goldAccent,
                              child: const Text("AI", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                            Positioned(
                              left: 16,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: AppTheme.accentHighlight,
                                child: Text(
                                  state.currentUser?.email?.substring(0, 1).toUpperCase() ?? "U",
                                  style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
=======
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
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
                              ),
                            ),
                            Text("$score%"),
                          ],
                        ),
<<<<<<< HEAD
                      ),
                    ],

                    // Glowing Progress Bar (Score)
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("$score%", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentHighlight, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          height: 6,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
=======
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
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: score / 100.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.accentHighlight,
<<<<<<< HEAD
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentHighlight.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
=======
                                borderRadius: BorderRadius.circular(6),
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
<<<<<<< HEAD

                    // Action Icon
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textDark.withValues(alpha: 0.5)),
                      onPressed: () {
                        notifier.viewPastEvaluation(
                          mock['report'] ?? '# Mock Report',
                          score,
                          mock['domain'] ?? 'Backend',
                          mock['experience_tier'] ?? 'Mid',
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );

    // 2. Right Column Widgets
    Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Widget 1: Quick-Note glowing gradient (Coach Tip)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.goldAccent.withValues(alpha: 0.45),
                AppTheme.accentHighlight.withValues(alpha: 0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentHighlight.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldAccent.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppTheme.accentHighlight, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    "Elite Coach Advice",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "When addressing architectural questions, explicitly describe caching matrices and horizontal partitioning details to score completeness >= 0.85.",
                style: TextStyle(fontSize: 12, color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Widget 2: File Upload Zone Module
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.panelBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor, width: 1.2),
          ),
          child: InkWell(
            onTap: () => notifier.setView('resume_labs'),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 36, color: AppTheme.accentHighlight),
                const SizedBox(height: 12),
                const Text(
                  "Analyze Experience",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  "Configure customized mock parameters",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textDark.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 16),
                
                // Format tags row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['PDF', 'DOCX', 'TXT'].map((ext) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(ext, style: TextStyle(fontSize: 9, color: AppTheme.textDark.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Widget 3: Analytics Circular progress and minimalist sparkline chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Telemetry Summary",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Circular Progress Ring
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: avgScore / 100.0,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentHighlight),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$avgScore%",
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 13),
                            ),
                            Text(
                              "Avg Score",
                              style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.5), fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Detail metrics stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prep Rank: $rank",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Total Mocks: $mocksCount Completed",
                          style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.5), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Sparkline graph
              const Text(
                "Mock Score Sparkline",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 8),
              
              Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.panelBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
=======
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
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
                ),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: mocksCount < 2
                    ? Center(
                        child: Text(
                          "No scores data plotted yet.",
                          style: TextStyle(fontSize: 10, color: AppTheme.textDark.withValues(alpha: 0.5)),
                        ),
                      )
                    : CustomPaint(
                        painter: SparklinePainter(
                          state.pastInterviews
                              .map<double>((e) => (e['overall_score'] as int).toDouble())
                              .toList()
                              .reversed
                              .toList(),
                          AppTheme.accentHighlight,
                        ),
                      ),
              ),
            ],
          ),
<<<<<<< HEAD
        ),
      ],
    );

    // Main layout responsive grid selection
    Widget finalContent;
    if (isNarrow) {
      finalContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          centerPanel,
          const SizedBox(height: 32),
          rightColumn,
=======
          Icon(icon, size: 36, color: iconColor),
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
        ],
      );
    } else {
      finalContent = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: centerPanel,
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: rightColumn,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: finalContent,
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double dx = size.width / (data.length - 1);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    for (int i = 0; i < data.length; i++) {
      final double x = i * dx;
      final double y = size.height - ((data[i] - minVal) / range * size.height * 0.7 + size.height * 0.15);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw fill area beneath the line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
