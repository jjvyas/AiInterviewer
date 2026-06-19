import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/interview_provider.dart';
import '../theme.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  int _activeTab = 0; // 0 for History, 1 for Resume Profile
  final ScrollController _resumeScrollController = ScrollController();

  @override
  void dispose() {
    _resumeScrollController.dispose();
    super.dispose();
  }

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

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.accentHighlight.withValues(alpha: 0.15) 
              : Colors.transparent,
          border: Border.all(
            color: isActive 
                ? AppTheme.accentHighlight 
                : AppTheme.borderColor,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.accentHighlight : AppTheme.textDark.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? AppTheme.textDark : AppTheme.textDark.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(dynamic state, dynamic notifier) {
    if (state.pastInterviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 48, color: AppTheme.textDark.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                "No interviews completed yet.",
                style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.pastInterviews.length,
      itemBuilder: (context, index) {
        final mock = state.pastInterviews[index];
        final score = mock['overall_score'] as int;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.borderColor, width: 1.2),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentHighlight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment, color: AppTheme.accentHighlight),
            ),
            title: Text(
              "${mock['experience_tier']} ${mock['domain']} Mock",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Taken on: ${_formatDate(mock['created_at'])}",
                  style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.6), fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.panelBg,
                    border: Border.all(color: AppTheme.borderColor, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Score: $score%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: score >= 80 ? AppTheme.accentHighlight : AppTheme.goldAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: AppTheme.textDark.withValues(alpha: 0.7)),
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
    );
  }

  Widget _buildResumeTab(dynamic state, dynamic notifier) {
    if (state.originalResumeText == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          border: Border.all(color: AppTheme.borderColor, width: 1.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 56,
              color: AppTheme.textDark.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              "No Resume Analyzed Yet",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Upload and analyze your resume in Resume Labs to extract skills, improve phrasing, and get a technical gap analysis.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textDark.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => notifier.setView('resume_labs'),
              icon: const Icon(Icons.rocket_launch, size: 18),
              label: const Text("Go to Resume Labs"),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target Job Title Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentHighlight.withValues(alpha: 0.15),
                AppTheme.goldAccent.withValues(alpha: 0.15),
              ],
            ),
            border: Border.all(color: AppTheme.borderColor, width: 1.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentHighlight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.work, color: AppTheme.accentHighlight),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Target Job Position",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark.withValues(alpha: 0.5),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.targetJob,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Extracted Text Block
        Text(
          "Extracted Resume Content",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.panelBg,
            border: Border.all(color: AppTheme.borderColor, width: 1.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Scrollbar(
            controller: _resumeScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _resumeScrollController,
              child: MarkdownBody(
                data: state.originalResumeText!,
                styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.4),
                  h2: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentHighlight, height: 1.3),
                  h3: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.2),
                  p: TextStyle(fontSize: 12.5, height: 1.45, color: AppTheme.textDark.withValues(alpha: 0.9)),
                  listBullet: TextStyle(color: AppTheme.accentHighlight),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // AI Phrasing Recommendations
        if (state.enhancedPhrasing.isNotEmpty) ...[
          Text(
            "Resume Phrasing Optimizations",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.enhancedPhrasing.length,
            itemBuilder: (context, index) {
              final key = state.enhancedPhrasing.keys.elementAt(index);
              final val = state.enhancedPhrasing[key];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  border: Border.all(color: AppTheme.borderColor, width: 1.0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Original",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      key,
                      style: TextStyle(fontSize: 13, color: AppTheme.textDark.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: AppTheme.accentHighlight, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "AI-Enhanced Option",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentHighlight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      val ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        // Gap Analysis Markdown
        if (state.gapAnalysisReport != null) ...[
          Text(
            "Technical Gap Analysis",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              border: Border.all(color: AppTheme.borderColor, width: 1.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: MarkdownBody(
              data: state.gapAnalysisReport!,
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.5),
                h2: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accentHighlight, height: 1.4),
                h3: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.3),
                p: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textDark.withValues(alpha: 0.9)),
                listBullet: TextStyle(color: AppTheme.accentHighlight),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Metadata Card (Frosted glassmorphism)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.panelBg,
              border: Border.all(color: AppTheme.borderColor, width: 1.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Avatar with premium neon glow border
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.accentHighlight, AppTheme.goldAccent],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.black,
                    child: const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.currentUser?.userMetadata?['full_name'] ?? state.currentUser?.userMetadata?['name'] ?? 'Developer User',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.currentUser?.email ?? 'Unknown Email',
                        style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.7), fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentHighlight.withValues(alpha: 0.15),
                              border: Border.all(color: AppTheme.accentHighlight.withValues(alpha: 0.4)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Active Prep",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentHighlight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatJoinDate(state.currentUser?.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark.withValues(alpha: 0.5),
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

          // Custom capsule/tab toggles
          Row(
            children: [
              _buildTabButton(0, "Interview History", Icons.history),
              const SizedBox(width: 12),
              _buildTabButton(1, "Extracted Resume", Icons.description),
            ],
          ),
          const SizedBox(height: 24),

<<<<<<< HEAD
          // Render active tab content
          _activeTab == 0
              ? _buildHistoryTab(state, notifier)
              : _buildResumeTab(state, notifier),
=======
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
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
        ],
      ),
    );
  }
}
