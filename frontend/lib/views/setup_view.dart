import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/interview_provider.dart';
import '../theme.dart';

class SetupView extends ConsumerWidget {
  const SetupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);

    final domains = [
      {'name': 'Frontend', 'desc': 'Virtual DOM, State management, Core Web Vitals, SSR.', 'icon': Icons.web},
      {'name': 'Backend', 'desc': 'APIs, Relational/NoSQL databases, Concurrency, Kafka.', 'icon': Icons.dns},
      {'name': 'Full-Stack', 'desc': 'End-to-end flow, Hydration, JWT & Cookies, latency.', 'icon': Icons.layers},
      {'name': 'DevOps', 'desc': 'CI/CD pipelines, Kubernetes, Docker, Terraform, Prometheus.', 'icon': Icons.cloud_done},
    ];

    final tiers = ['Junior', 'Mid', 'Senior', 'Lead'];

    final isNarrow = MediaQuery.of(context).size.width < 750;

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Configure Your Mock Session",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          "InterviewerAI adapts complexity and difficulty matrices to matches your selected parameters.",
          style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 32),
        
        // Select Domain Title
        const Text(
          "1. Select Engineering Domain Matrix",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Domain Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isNarrow ? 1 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isNarrow ? 2.8 : 2.2,
          ),
          itemCount: domains.length,
          itemBuilder: (context, index) {
            final domain = domains[index];
            final name = domain['name'] as String;
            final desc = domain['desc'] as String;
            final icon = domain['icon'] as IconData;
            final isSelected = state.domain == name;

            return InkWell(
              onTap: () => notifier.setDomain(name),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.accentHighlight.withValues(alpha: 0.1) 
                      : AppTheme.cardBg.withValues(alpha: 0.3),
                  border: Border.all(
                    color: isSelected ? AppTheme.accentHighlight : AppTheme.borderColor,
                    width: isSelected ? 2.0 : 1.2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.accentHighlight.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ] : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isSelected 
                          ? AppTheme.accentHighlight.withValues(alpha: 0.15) 
                          : AppTheme.panelBg.withValues(alpha: 0.5),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSelected ? AppTheme.accentHighlight : AppTheme.textDark.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark.withValues(alpha: 0.6),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        
        // Select Experience Tier Title
        const Text(
          "2. Choose Experience Tier",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Tiers Chips
        Wrap(
          spacing: 12.0,
          runSpacing: 8.0,
          children: tiers.map((tier) {
            final isSelected = state.experienceTier == tier;
            return ChoiceChip(
              label: Text(
                tier,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : AppTheme.textDark.withValues(alpha: 0.7),
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.accentHighlight,
              backgroundColor: AppTheme.cardBg.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.accentHighlight : AppTheme.borderColor,
                  width: 1.0,
                ),
              ),
              onSelected: (_) => notifier.setExperienceTier(tier),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),

        // Launch Action Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentHighlight.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      await notifier.startInterview();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentHighlight,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("Launch Mock Interview Session", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: mainContent,
      ),
    );
  }
}
