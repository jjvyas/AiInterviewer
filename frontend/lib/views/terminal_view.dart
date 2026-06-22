import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/interview_provider.dart';
import '../theme.dart';

class TerminalView extends ConsumerStatefulWidget {
  const TerminalView({super.key});

  @override
  ConsumerState<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends ConsumerState<TerminalView> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minsStr = minutes.toString().padLeft(2, '0');
    final secsStr = seconds.toString().padLeft(2, '0');
    return "$minsStr:$secsStr";
  }

  Widget _buildInterviewerPane(BuildContext context, dynamic state) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panelBg.withValues(alpha: 0.3),
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Pane Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1.2),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.psychology, size: 20),
                SizedBox(width: 8),
                Text("AI Interviewer Dialog", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Question log stream
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.stepsHistory.length,
              itemBuilder: (context, index) {
                final step = state.stepsHistory[index];
                final isLast = index == state.stepsHistory.length - 1;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLast 
                            ? AppTheme.accentHighlight.withValues(alpha: 0.1) 
                            : AppTheme.cardBg.withValues(alpha: 0.3),
                        border: Border.all(
                          color: isLast ? AppTheme.accentHighlight : AppTheme.borderColor,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Question ${index + 1}:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 12, 
                              color: isLast ? AppTheme.accentHighlight : AppTheme.textDark.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step['question'] ?? '',
                            style: const TextStyle(fontSize: 13.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // User Answer (if answered)
                    if (step['answer'] != null) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(left: 32),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg.withValues(alpha: 0.25),
                            border: Border.all(color: AppTheme.borderColor, width: 1.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Your Response:",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(step['answer'], style: const TextStyle(fontSize: 13, height: 1.3)),
                              if (step['score'] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "Completeness Score: ${(step['score'] * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.accentHighlight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerPane(BuildContext context, dynamic state, dynamic notifier) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0B1F), // Deep space black terminal bg
        border: Border.all(color: AppTheme.accentHighlight.withValues(alpha: 0.25), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentHighlight.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sandbox Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.accentHighlight.withValues(alpha: 0.2), width: 1.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.code, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text("Candidate Answer Sandbox", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const Text(
                  "Markdown / Plaintext",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          
          // Text Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _answerController,
                maxLines: null,
                minLines: 15,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Color(0xFFC0CAF5), // Soft terminal white
                  fontSize: 14,
                  height: 1.4,
                ),
                cursorColor: AppTheme.accentHighlight,
                decoration: const InputDecoration(
                  hintText: "// Write your response here. Outline the design steps, expected parameters, and engineering trade-offs...",
                  hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Courier', fontSize: 13),
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          
          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF070512),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Pressing Submit completes this step. You cannot go back.",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
                ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final text = _answerController.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please write an answer before submitting.")),
                            );
                            return;
                          }
                          await notifier.submitAnswer(text);
                          _answerController.clear();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentHighlight,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Text("Submit Answer", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEndInterviewDialog(BuildContext context, dynamic notifier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            "End Interview Session?",
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to end this interview early? We will compile an evaluation report based on your answered questions so far. You cannot resume this session once ended.",
            style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.8), height: 1.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.borderColor, width: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                notifier.endInterviewEarly();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("End Session", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);

    final isTimerLow = state.timeLeft < 120; // less than 2 mins left
    final isNarrow = MediaQuery.of(context).size.width < 850;

    Widget header = isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Active Mock Session • Step ${state.currentStep} of 6",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isTimerLow ? Colors.red.shade100 : Colors.white.withValues(alpha: 0.5),
                      border: Border.all(
                        color: isTimerLow ? Colors.red : AppTheme.textDark,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: isTimerLow ? Colors.red : AppTheme.textDark,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(state.timeLeft),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isTimerLow ? Colors.red : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showEndInterviewDialog(context, notifier),
                    icon: const Icon(Icons.exit_to_app, size: 16),
                    label: const Text("End Session", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Active Mock Session • Step ${state.currentStep} of 6",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isTimerLow ? Colors.red.shade100 : Colors.white.withValues(alpha: 0.5),
                      border: Border.all(
                        color: isTimerLow ? Colors.red : AppTheme.textDark,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: isTimerLow ? Colors.red : AppTheme.textDark,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(state.timeLeft),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isTimerLow ? Colors.red : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showEndInterviewDialog(context, notifier),
                    icon: const Icon(Icons.exit_to_app, size: 16),
                    label: const Text("End Session", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          );

    Widget bodyContent = isNarrow
        ? DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppTheme.accentHighlight,
                  unselectedLabelColor: AppTheme.textDark.withValues(alpha: 0.6),
                  indicatorColor: AppTheme.accentHighlight,
                  tabs: const [
                    Tab(icon: Icon(Icons.psychology), text: "AI Dialogue"),
                    Tab(icon: Icon(Icons.code), text: "Answer Sandbox"),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildInterviewerPane(context, state),
                      _buildAnswerPane(context, state, notifier),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: _buildInterviewerPane(context, state),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: _buildAnswerPane(context, state, notifier),
              ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 20),
          Expanded(
            child: bodyContent,
          ),
        ],
      ),
    );
  }
}
