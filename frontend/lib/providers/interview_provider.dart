import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class InterviewState {
  final String currentView; // 'dashboard', 'setup', 'terminal', 'evaluation', 'profile', 'resume_labs'
  final String? activeInterviewId;
  final int currentStep; // 1 to 6 (6 is behavioral, 7 is finished)
  final String? currentQuestion;
  final List<Map<String, dynamic>> stepsHistory;
  final bool isLoading;
  final String? errorMessage;
  final String domain;
  final String experienceTier;
  final int timeLeft; // countdown timer in seconds
  final int overallScore;
  final String? reportMarkdown;
  final List<Map<String, dynamic>> pastInterviews;
  final bool isDarkMode;
  final sb.User? currentUser;
  
  // Resume Labs states
  final String? originalResumeText;
  final Map<String, String> enhancedPhrasing;
  final String? gapAnalysisReport;
  final String targetJob;

  InterviewState({
    this.currentView = 'dashboard',
    this.activeInterviewId,
    this.currentStep = 1,
    this.currentQuestion,
    this.stepsHistory = const [],
    this.isLoading = false,
    this.errorMessage,
    this.domain = 'Backend',
    this.experienceTier = 'Mid',
    this.timeLeft = 600, // 10 minutes per question default
    this.overallScore = 0,
    this.reportMarkdown,
    this.pastInterviews = const [],
    this.isDarkMode = true, // Default to true (sleek dark mode from image)
    this.currentUser,
    this.originalResumeText,
    this.enhancedPhrasing = const {},
    this.gapAnalysisReport,
    this.targetJob = 'Senior Backend Engineer',
  });

  InterviewState copyWith({
    String? currentView,
    String? activeInterviewId,
    int? currentStep,
    String? currentQuestion,
    List<Map<String, dynamic>>? stepsHistory,
    bool? isLoading,
    String? errorMessage,
    String? domain,
    String? experienceTier,
    int? timeLeft,
    int? overallScore,
    String? reportMarkdown,
    List<Map<String, dynamic>>? pastInterviews,
    bool? isDarkMode,
    sb.User? currentUser,
    String? originalResumeText,
    Map<String, String>? enhancedPhrasing,
    String? gapAnalysisReport,
    String? targetJob,
  }) {
    return InterviewState(
      currentView: currentView ?? this.currentView,
      activeInterviewId: activeInterviewId ?? this.activeInterviewId,
      currentStep: currentStep ?? this.currentStep,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      stepsHistory: stepsHistory ?? this.stepsHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      domain: domain ?? this.domain,
      experienceTier: experienceTier ?? this.experienceTier,
      timeLeft: timeLeft ?? this.timeLeft,
      overallScore: overallScore ?? this.overallScore,
      reportMarkdown: reportMarkdown ?? this.reportMarkdown,
      pastInterviews: pastInterviews ?? this.pastInterviews,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currentUser: currentUser ?? this.currentUser,
      originalResumeText: originalResumeText ?? this.originalResumeText,
      enhancedPhrasing: enhancedPhrasing ?? this.enhancedPhrasing,
      gapAnalysisReport: gapAnalysisReport ?? this.gapAnalysisReport,
      targetJob: targetJob ?? this.targetJob,
    );
  }
}

class InterviewNotifier extends StateNotifier<InterviewState> {
  final Dio _dioNode = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  final Dio _dioAI = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api'));
  Timer? _timer;
  StreamSubscription? _authSubscription;

  InterviewNotifier() : super(InterviewState()) {
    _initAuth();
  }

  void _initAuth() {
    final currentSession = sb.Supabase.instance.client.auth.currentSession;
    state = state.copyWith(currentUser: currentSession?.user);
    if (currentSession?.user != null) {
      loadPastInterviews();
    }

    _authSubscription = sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      state = state.copyWith(
        currentUser: session?.user,
        errorMessage: null,
      );
      if (session?.user != null) {
        loadPastInterviews();
      } else {
        state = state.copyWith(pastInterviews: const [], currentView: 'dashboard');
      }
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final authResponse = await sb.Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      final user = authResponse.user;
      if (user != null) {
        try {
          await sb.Supabase.instance.client.from('profiles').update({
            'last_login_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', user.id);

          await sb.Supabase.instance.client.from('login_history').insert({
            'user_id': user.id,
          });
        } catch (dbError) {
          debugPrint('Error logging login details to DB: $dbError');
        }
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await sb.Supabase.instance.client.auth.signUp(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await sb.Supabase.instance.client.auth.signOut();
  }

  String? get _authHeader {
    final token = sb.Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? 'Bearer $token' : null;
  }

  Map<String, String> get _authHeaders {
    final token = sb.Supabase.instance.client.auth.currentSession?.accessToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  void setView(String view) {
    state = state.copyWith(currentView: view, errorMessage: null);
  }

  void setDomain(String domain) {
    state = state.copyWith(domain: domain);
  }

  void setExperienceTier(String tier) {
    state = state.copyWith(experienceTier: tier);
  }

  void setTargetJob(String targetJob) {
    state = state.copyWith(targetJob: targetJob);
  }

  // Timer utilities
  void startTimer() {
    _timer?.cancel();
    state = state.copyWith(timeLeft: 600); // Reset to 10 minutes
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft <= 1) {
        timer.cancel();
        submitAnswer("Time out limit reached. System auto-submitted final logs.");
      } else {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  // API Call: Ingest Resume in Resume Labs (Base64 file bytes)
  Future<void> analyzeResumeFile(String base64Bytes, String fileName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _logEvent('RESUME_UPLOAD_FILE', 'User uploaded resume file: $fileName');

      final response = await _dioNode.post(
        '/resume/upload',
        data: {
          'fileBytes': base64Bytes,
          'fileName': fileName,
          'targetJob': state.targetJob
        },
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final Map<String, String> enhanced = {};
        if (data['enhancedPhrasing'] != null) {
          (data['enhancedPhrasing'] as Map).forEach((k, v) {
            enhanced[k.toString()] = v.toString();
          });
        }

        state = state.copyWith(
          originalResumeText: data['originalText'] ?? 'No text extracted',
          enhancedPhrasing: enhanced,
          gapAnalysisReport: data['gapAnalysis'],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to analyze resume file: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        originalResumeText: "Extracted Resume Context (Fallback): Experienced software engineer specializing in backend systems, APIs, database indexing, and CI/CD pipelines.",
        enhancedPhrasing: {
          "Helped deploy systems": "Architected and managed CI/CD deployment pipelines using Github Actions and Terraform on AWS ECS.",
          "Responsible for database operations": "Optimized PostgreSQL indexes and query paths, reducing slow query executions by 42%.",
        },
        gapAnalysisReport: """# Fallback Gap Analysis Report (File: $fileName)
## Required Projects
- Build a real-time analytics pipeline with Kafka.
## Missing Tools
- Observability stacks (Prometheus, Grafana, Jaeger).
""",
        isLoading: false,
      );
    }
  }

  // API Call: Start a new Mock Interview Session
  Future<void> startInterview() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final dummyInterviewId = const Uuid().v4();

    try {
      // 1. Create session in Node.js Express service
      final sessionRes = await _dioNode.post(
        '/interviews/session',
        data: {
          'domain': state.domain,
          'experienceTier': state.experienceTier,
          'resumeContext': state.originalResumeText != null ? "Context: candidate has experience with resume text summary" : null,
        },
        options: Options(headers: {'Authorization': _authHeader}),
      );

      String interviewId = dummyInterviewId;
      if (sessionRes.statusCode == 201 && sessionRes.data['interview'] != null) {
        interviewId = sessionRes.data['interview']['id'];
      }

      // 2. Fetch initial question from FastAPI service
      final startRes = await _dioAI.post(
        '/interviews/start',
        data: {
          'interview_id': interviewId,
          'domain': state.domain,
          'experience_tier': state.experienceTier,
          'resume_context': state.originalResumeText,
        },
      );

      final question = startRes.data['question'] ?? 'Welcome! Let us start by explaining your engineering background.';

      state = state.copyWith(
        activeInterviewId: interviewId,
        currentStep: 1,
        currentQuestion: question,
        stepsHistory: [
          {'question': question, 'answer': null, 'score': null}
        ],
        currentView: 'terminal',
        isLoading: false,
      );
      
      startTimer();
      await _logEvent('INTERVIEW_START', 'Started new interview $interviewId for ${state.domain}');
    } catch (e) {
      // Dynamic fallback for offline/disconnected states
      state = state.copyWith(
        activeInterviewId: dummyInterviewId,
        currentStep: 1,
        currentQuestion: "In a relational database like PostgreSQL, what is the difference between a B-Tree index and a Hash index, and when would you prefer one over the other?",
        stepsHistory: [
          {
            'question': "In a relational database like PostgreSQL, what is the difference between a B-Tree index and a Hash index, and when would you prefer one over the other?",
            'answer': null,
            'score': null
          }
        ],
        currentView: 'terminal',
        isLoading: false,
      );
      startTimer();
    }
  }

  // API Call: Submit Candidate Response
  Future<void> submitAnswer(String answer) async {
    if (state.activeInterviewId == null) return;
    
    stopTimer();
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _dioAI.post(
        '/evaluate',
        data: {
          'interview_id': state.activeInterviewId,
          'user_answer': answer,
          'step_order': state.currentStep,
          'current_difficulty': 2, // default / calculated
          'domain': state.domain,
          'experience_tier': state.experienceTier,
          'resume_context': state.originalResumeText,
        },
      );

      final data = response.data;
      final double score = (data['completeness_score'] ?? 0.5) as double;
      final bool isComplete = (data['is_complete'] ?? false) as bool;

      // Update local history
      final updatedHistory = List<Map<String, dynamic>>.from(state.stepsHistory);
      if (updatedHistory.isNotEmpty) {
        updatedHistory.last['answer'] = answer;
        updatedHistory.last['score'] = score;
      }

      if (isComplete) {
        // Complete the mock interview
        final report = data['report'] ?? 'No evaluation report generated.';
        final scoreVal = (data['overall_score'] ?? 75) as int;

        state = state.copyWith(
          stepsHistory: updatedHistory,
          currentStep: 7,
          overallScore: scoreVal,
          reportMarkdown: report,
          currentView: 'evaluation',
          isLoading: false,
        );

        await _logEvent('INTERVIEW_COMPLETE', 'Completed interview ${state.activeInterviewId}');
        loadPastInterviews(); // refresh profile ledger
      } else {
        // Prepare next step
        final nextQuestion = data['next_question'] ?? 'Tell me more.';
        updatedHistory.add({'question': nextQuestion, 'answer': null, 'score': null});

        state = state.copyWith(
          stepsHistory: updatedHistory,
          currentStep: state.currentStep + 1,
          currentQuestion: nextQuestion,
          isLoading: false,
        );

        startTimer();
        await _logEvent('STEP_SUBMIT', 'Submitted step ${state.currentStep - 1} answer');
      }
    } catch (e) {
      // Client-side fallback mapping for offline demonstration
      final updatedHistory = List<Map<String, dynamic>>.from(state.stepsHistory);
      final localScore = _evaluateAnswerOffline(answer, state.currentQuestion ?? '', state.domain);
      
      if (updatedHistory.isNotEmpty) {
        updatedHistory.last['answer'] = answer;
        updatedHistory.last['score'] = localScore;
      }

      if (state.currentStep < 5) {
        final mockQuestions = [
          "Explain the N+1 query problem in database ORMs/GraphQL. How do you identify it, and what strategies do you use to resolve it?",
          "Describe the Node.js event loop. How does it handle concurrency differently compared to multi-threaded engines?",
          "Compare Cache-aside and Write-through caching strategies. Detail the concurrency challenges.",
          "Tell me about a production outage or critical database performance bottleneck you encountered."
        ];
        
        final nextQ = mockQuestions[state.currentStep - 1];
        updatedHistory.add({'question': nextQ, 'answer': null, 'score': null});

        state = state.copyWith(
          stepsHistory: updatedHistory,
          currentStep: state.currentStep + 1,
          currentQuestion: nextQ,
          isLoading: false,
        );
        startTimer();
      } else {
        // Calculate overall score dynamically based on step scores
        double sumScores = 0.0;
        int count = 0;
        for (var step in updatedHistory) {
          if (step['score'] != null) {
            sumScores += step['score'] as double;
            count++;
          }
        }
        final calculatedOverallScore = count > 0 ? (sumScores / count * 100).toInt() : 50;

        // Dynamic Evaluation Report
        final mockReport = """# Performance Evaluation Report

## 1. Executive Summary
**Overall Score:** `$calculatedOverallScore / 100`
**Domain Performance Rank:** ${state.experienceTier} ${state.domain} Developer

**Key Strengths:**
- Demonstrates technical terminology mapping.
- Good conceptual coverage of topics.

## 2. Question-by-Question Breakdown
| # | Question Prompt | Score (1-10) |
|---|-----------------|--------------|
${updatedHistory.asMap().entries.map((entry) {
  final idx = entry.key + 1;
  final step = entry.value;
  final stepScore = (((step['score'] ?? 0.5) as double) * 10).toInt();
  final qText = step['question'] as String;
  final displayQ = qText.length > 50 ? "${qText.substring(0, 50)}..." : qText;
  return "| $idx | $displayQ | $stepScore/10 |";
}).join('\n')}

## 3. Domain-Specific Feedback Matrix
- **Conceptual Depth:** Dynamic assessment based on keyword completeness.
- **System Design Thinking:** Relies on structural keyword references.

## 4. Actionable Upskilling Roadmap
* Review query optimization and lifecycle details.
* Practice real-time system design and trade-offs.
""";

        state = state.copyWith(
          stepsHistory: updatedHistory,
          currentStep: 7,
          overallScore: calculatedOverallScore,
          reportMarkdown: mockReport,
          currentView: 'evaluation',
          isLoading: false,
        );
      }
    }
  }

  // Load ledger list of mock interviews from Supabase
  Future<void> loadPastInterviews() async {
    final user = state.currentUser;
    if (user == null) return;
    try {
      final response = await sb.Supabase.instance.client
          .from('interviews')
          .select('*, interview_steps(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> list = [];
      if (response != null) {
        for (var item in (response as List)) {
          final steps = item['interview_steps'] as List?;
          String? report;
          if (steps != null) {
            // Find the evaluation report if it exists
            final reportStep = steps.firstWhere(
              (s) => s['step_order'] == 7 || s['dynamic_question'] == 'Evaluation Report',
              orElse: () => null,
            );
            if (reportStep != null) {
              report = reportStep['user_answer'];
            }
          }
          list.add({
            'id': item['id'],
            'domain': item['domain'],
            'experience_tier': item['experience_tier'],
            'overall_score': item['overall_score'] ?? 0,
            'created_at': item['created_at'],
            'report': report,
          });
        }
      }
      state = state.copyWith(pastInterviews: list);
    } catch (e) {
      debugPrint('Error loading past interviews from Supabase: $e');
    }
  }

  void viewPastEvaluation(String report, int score, String domain, String tier) {
    state = state.copyWith(
      reportMarkdown: report,
      overallScore: score,
      domain: domain,
      experienceTier: tier,
      currentView: 'evaluation'
    );
  }

  void toggleTheme() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  double _evaluateAnswerOffline(String answer, String question, String domain) {
    if (answer.trim().length < 5) return 0.0;
    final ansLower = answer.toLowerCase();
    
    // Basic negative/empty response check
    if (ansLower.contains("don't know") || 
        ansLower.contains("don't have") || 
        ansLower.contains("no idea") || 
        ansLower.contains("skip") ||
        ansLower.trim() == "idk" ||
        ansLower.split(' ').length < 4) {
      return 0.1; // Very low score
    }

    // Basic keyword mapping
    final Map<String, List<String>> domainKeywords = {
      'Frontend': ['virtual dom', 'lifecycle', 'hook', 'redux', 'context', 'rendering', 'lazy', 'performance'],
      'Backend': ['rest', 'graphql', 'sql', 'index', 'concurrency', 'event loop', 'cache', 'database'],
      'Full-Stack': ['auth', 'jwt', 'session', 'database', 'frontend', 'backend', 'api', 'state'],
      'DevOps': ['ci/cd', 'docker', 'kubernetes', 'terraform', 'prometheus', 'pipeline', 'deployment'],
    };

    int keywordMatches = 0;
    final keywords = domainKeywords[domain] ?? [];
    for (var kw in keywords) {
      if (ansLower.contains(kw)) {
        keywordMatches++;
      }
    }

    // Also check if any question words (longer than 4 chars) match
    final qWords = question.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(' ');
    int qMatches = 0;
    for (var qw in qWords) {
      if (qw.length > 4 && ansLower.contains(qw)) {
        qMatches++;
      }
    }

    // Score components
    double score = 0.1; // baseline
    if (keywordMatches > 0) score += 0.3 * (keywordMatches > 3 ? 3.0 : keywordMatches);
    if (qMatches > 1) score += 0.2;
    if (ansLower.length > 50) score += 0.1; // details credit
    
    return score > 1.0 ? 1.0 : score;
  }

  // Log client events directly to Express
  Future<void> _logEvent(String eventType, String message) async {
    try {
      await _dioNode.post(
        '/logs',
        data: {
          'interviewId': state.activeInterviewId,
          'eventType': eventType,
          'message': message,
          'clientState': {
            'view': state.currentView,
            'step': state.currentStep,
            'domain': state.domain,
            'experienceTier': state.experienceTier
          }
        },
        options: Options(headers: {'Authorization': _authHeader}),
      );
    } catch (_) {
      // ignore logging errors in client
    }
  }
}

final interviewProvider = StateNotifierProvider<InterviewNotifier, InterviewState>((ref) {
  return InterviewNotifier();
});
