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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Configure Your Mock Session",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Domain Grid
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.cardBg : Colors.white.withValues(alpha: 0.4),
                      border: Border.all(
                        color: AppTheme.textDark,
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          icon,
                          size: 32,
                          color: isSelected ? AppTheme.accentHighlight : AppTheme.textDark.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textDark.withValues(alpha: 0.8),
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
          ),
          const SizedBox(height: 24),
          
          // Select Experience Tier Title
          const Text(
            "2. Choose Experience Tier",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Tiers Chips
          Row(
            children: tiers.map((tier) {
              final isSelected = state.experienceTier == tier;
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ChoiceChip(
                  label: Text(
                    tier,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.accentHighlight,
                  backgroundColor: AppTheme.panelBg.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppTheme.textDark, width: 1.2),
                  ),
                  onSelected: (_) => notifier.setExperienceTier(tier),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          // Launch Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      await notifier.startInterview();
                    },
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Launch Mock Interview Session"),
            ),
          ),
        ],
      ),
    );
  }
}
