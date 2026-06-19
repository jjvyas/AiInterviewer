import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/interview_provider.dart';
import '../theme.dart';

class ResumeLabsView extends ConsumerStatefulWidget {
  const ResumeLabsView({super.key});

  @override
  ConsumerState<ResumeLabsView> createState() => _ResumeLabsViewState();
}

class _ResumeLabsViewState extends ConsumerState<ResumeLabsView> {
  final TextEditingController _jobController = TextEditingController();
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    final state = ref.read(interviewProvider);
    _jobController.text = state.targetJob;
  }

  @override
  void dispose() {
    _jobController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
        withData: true, // required for web to read bytes
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Widget _buildUploadArea(dynamic state) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        border: Border.all(
          color: state.isDarkMode
              ? const Color(0xFF2D2D34).withValues(alpha: 0.5)
              : const Color(0xFFD2D7DF).withValues(alpha: 0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: state.isLoading ? null : _pickFile,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFile != null ? Icons.check_circle : Icons.upload_file,
              color: _selectedFile != null ? Colors.green : AppTheme.accentHighlight,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFile != null 
                  ? "File Selected: ${_selectedFile!.name}" 
                  : "Upload Resume (PDF, Word DOC/DOCX, or TXT)",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedFile != null
                  ? "Size: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB | Click to replace"
                  : "Select a document to extract skills & perform gap analysis",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textDark.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetJobConfig(dynamic state, dynamic notifier) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(
          color: state.isDarkMode
              ? const Color(0xFF2D2D34).withValues(alpha: 0.5)
              : const Color(0xFFD2D7DF).withValues(alpha: 0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Target Job Config",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: TextField(
                  controller: _jobController,
                  style: TextStyle(color: AppTheme.textDark, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: "Target Position Title",
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (val) => notifier.setTargetJob(val),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: state.isLoading || _selectedFile == null
                  ? null
                  : () async {
                      final bytes = _selectedFile!.bytes;
                      if (bytes == null) return;
                      final base64Bytes = base64Encode(bytes);
                      await notifier.analyzeResumeFile(base64Bytes, _selectedFile!.name);
                    },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Analyze Resume", style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhrasingSuggestions(BuildContext context, dynamic state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "AI-Enhanced Phrasing Suggestions",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentHighlight,
                ),
          ),
          const SizedBox(height: 16),
          ...state.enhancedPhrasing.entries.map<Widget>((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.panelBg,
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Original:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "AI suggestion:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.accentHighlight,
                    ),
                  ),
                  Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGapAnalysisReport(BuildContext context, dynamic state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Technical Gap Analysis Report",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentHighlight,
                ),
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: state.gapAnalysisReport ?? '',
            styleSheet: MarkdownStyleSheet(
              h1: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.5),
              h2: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accentHighlight, height: 1.4),
              p: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textDark.withValues(alpha: 0.95)),
              listBullet: TextStyle(color: AppTheme.accentHighlight),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);
    final isNarrow = MediaQuery.of(context).size.width < 850;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Resume Labs",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            "Analyze your experience against target roles and generate high-impact resume phrasing.",
            style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),

          // Main Layout Content: Top config panel, Middle side-by-side, Bottom gap analysis
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Config & Paste Section
                  if (isNarrow) ...[
                    _buildUploadArea(state),
                    const SizedBox(height: 16),
                    _buildTargetJobConfig(state, notifier),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildUploadArea(state),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: _buildTargetJobConfig(state, notifier),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 2. Phrasing Recommendations & Gap Analysis Side-by-Side
                  if (state.originalResumeText != null) ...[
<<<<<<< HEAD
                    if (isNarrow) ...[
                      _buildPhrasingSuggestions(context, state),
                      const SizedBox(height: 20),
                      _buildGapAnalysisReport(context, state),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildPhrasingSuggestions(context, state),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 1,
                            child: _buildGapAnalysisReport(context, state),
=======
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI-Enhanced Phrasing Table
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              border: Border.all(color: AppTheme.textDark, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "AI-Enhanced Phrasing Suggestions",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentHighlight,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                ...state.enhancedPhrasing.entries.map((entry) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.panelBg.withValues(alpha: 0.3),
                                      border: Border.all(color: AppTheme.textDark, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Original:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: state.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(entry.key, style: const TextStyle(fontSize: 13)),
                                        const SizedBox(height: 8),
                                        Text(
                                          "AI suggestion:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppTheme.accentHighlight,
                                          ),
                                        ),
                                        Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Technical Gap Analysis Report
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              border: Border.all(color: AppTheme.textDark, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Technical Gap Analysis Report",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentHighlight,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                MarkdownBody(
                                  data: state.gapAnalysisReport ?? '',
                                  styleSheet: MarkdownStyleSheet(
                                    h1: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.5),
                                    h2: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accentHighlight, height: 1.4),
                                    p: const TextStyle(fontSize: 13, height: 1.4),
                                    listBullet: TextStyle(color: AppTheme.accentHighlight),
                                  ),
                                ),
                              ],
                            ),
>>>>>>> ea9eb1ee3c87b75accfe4a309b3ceea5caa6f1fc
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
