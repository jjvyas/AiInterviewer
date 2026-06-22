import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../services/local_storage.dart'; // exports HiveStorage

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
  final bool isDemoMode;
  final int currentDifficulty;
  
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
    this.isDemoMode = false,
    this.currentDifficulty = 2,
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
    bool? isDemoMode,
    String? originalResumeText,
    Map<String, String>? enhancedPhrasing,
    String? gapAnalysisReport,
    String? targetJob,
    int? currentDifficulty,
    bool clearCurrentUser = false,
    bool clearActiveInterviewId = false,
    bool clearReportMarkdown = false,
    bool clearOriginalResumeText = false,
    bool clearGapAnalysisReport = false,
  }) {
    return InterviewState(
      currentView: currentView ?? this.currentView,
      activeInterviewId: clearActiveInterviewId ? null : (activeInterviewId ?? this.activeInterviewId),
      currentStep: currentStep ?? this.currentStep,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      stepsHistory: stepsHistory ?? this.stepsHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      domain: domain ?? this.domain,
      experienceTier: experienceTier ?? this.experienceTier,
      timeLeft: timeLeft ?? this.timeLeft,
      overallScore: overallScore ?? this.overallScore,
      reportMarkdown: clearReportMarkdown ? null : (reportMarkdown ?? this.reportMarkdown),
      pastInterviews: pastInterviews ?? this.pastInterviews,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      isDemoMode: isDemoMode ?? this.isDemoMode,
      originalResumeText: clearOriginalResumeText ? null : (originalResumeText ?? this.originalResumeText),
      enhancedPhrasing: enhancedPhrasing ?? this.enhancedPhrasing,
      gapAnalysisReport: clearGapAnalysisReport ? null : (gapAnalysisReport ?? this.gapAnalysisReport),
      targetJob: targetJob ?? this.targetJob,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
    );
  }
}

class InterviewNotifier extends StateNotifier<InterviewState> {
  static const Map<String, Map<String, Map<int, String>>> _fallbackQuestions = {
    'Frontend': {
      'Junior': {
        1: "Explain the difference between state and props in React or Vue. When would you use one over the other?",
        2: "What is prop drilling, and how does the Context API or basic state providers help solve it?",
        3: "What are the core differences between local state, session storage, and local storage on the browser?",
        4: "What is the difference between client-side rendering (CSR) and server-side rendering (SSR) at a basic conceptual level?",
        5: "How do you style components in a modern framework? Compare standard CSS/SASS with utility-first frameworks like Tailwind."
      },
      'Mid': {
        1: "Explain the difference between the Virtual DOM and the Real DOM. How does React or Vue use it to optimize rendering?",
        2: "What is prop drilling, and what are the main state management strategies (e.g., Context API, Zustand) you would use to mitigate it?",
        3: "Explain the Critical Rendering Path. How do tools like code splitting and lazy loading improve Core Web Vitals like LCP?",
        4: "What is Cross-Site Scripting (XSS) in frontend applications? How do you securely mitigate XSS and CSRF risks when storing authentication tokens?",
        5: "Design a high-performance, real-time dashboards frontend that must update charts every 100ms. Detail your components rendering, rendering optimizations (useMemo/useCallback), and web-socket subscription state strategy."
      },
      'Senior': {
        1: "How does React's Fiber architecture or Vue's reactivity system manage scheduling and rendering priorities? Explain how to avoid blocking the main thread during heavy computations.",
        2: "Design a state management architecture for a large offline-first dashboard. How do you handle optimistic updates, local persistence (IndexedDB), and server synchronization conflicts?",
        3: "Analyze the impact of Server Components (RSC) and Hydration on modern web performance. How do you resolve hydration mismatch errors in production?",
        4: "Explain advanced security protocols for frontend applications. How do you configure Content Security Policy (CSP), handle token rotation securely, and mitigate clickjacking?",
        5: "Architect a micro-frontend shell application. How do you handle shared state, coordinate routing between micro-apps, manage dependency version clashes, and ensure independent deployment pipelines?"
      },
      'Lead': {
        1: "How do you establish code quality standards, design system governance, and automated performance budgets across multiple frontend engineering teams?",
        2: "Explain your strategy for migrating a legacy monolithic frontend to a modern framework without interrupting feature delivery. How do you manage technical debt and assess risk?",
        3: "Design an end-to-end telemetry system for tracking Core Web Vitals, runtime frontend errors, and user interactions in a global, high-traffic web application.",
        4: "How do you evaluate and integrate third-party dependencies or design-system frameworks? Explain the security, accessibility (a11y), and performance trade-offs you look for.",
        5: "Architect a continuous delivery flow for a frontend application served globally. Detail CDN caching rules, edge routing (e.g., Cloudflare Workers for A/B testing), rollback strategies, and zero-downtime deployments."
      }
    },
    'Backend': {
      'Junior': {
        1: "What is the difference between an INNER JOIN and a LEFT JOIN in SQL, and when would you use each?",
        2: "Explain the difference between HTTP GET and POST requests. What are the common status codes returned by a REST API?",
        3: "What is database normalization? Explain the difference between 1NF, 2NF, and 3NF with a basic database example.",
        4: "What is an ORM (Object-Relational Mapping)? What are the pros and cons of using an ORM versus writing raw SQL?",
        5: "How do you securely store user passwords in a database? What hashing algorithms should you use and why is salting important?"
      },
      'Mid': {
        1: "In a relational database like PostgreSQL, what is the difference between a B-Tree index and a Hash index, and when would you prefer one over the other?",
        2: "Explain the N+1 query problem in database ORMs/GraphQL. How do you identify it, and what strategies do you use to resolve it?",
        3: "Describe the Node.js event loop. How does it handle concurrency differently compared to multi-threaded engines, and how do you prevent blocking it?",
        4: "Compare Cache-aside and Write-through caching strategies. Detail the concurrency challenges (e.g., cache stampede, race conditions) and how you design to prevent them.",
        5: "Design a highly-scalable, asynchronous order processing system that can handle 100,000 requests/second. Detail your queue/broker setup (Kafka vs RabbitMQ), concurrency pooling, scaling, and database ACID transaction boundaries."
      },
      'Senior': {
        1: "Compare optimistic and pessimistic concurrency control in highly contested database systems. How do you handle deadlocks and write conflicts?",
        2: "Explain database sharding, partition keys selection, and the architectural trade-offs of using distributed databases like Spanner or CockroachDB over standard PostgreSQL replication.",
        3: "How do you implement the Saga pattern for managing distributed transactions across multiple microservices? Compare orchestration vs. choreography approaches.",
        4: "Detail how you would implement a multi-level caching system. How do you prevent cache penetration, cache breakdown, and cache stampedes under heavy traffic spikes?",
        5: "Design a high-frequency real-time notification engine. Explain your choices of transport protocols (WebSockets, SSE, gRPC), connection scaling, horizontal distribution, and persistent connection storage."
      },
      'Lead': {
        1: "How do you define and enforce service boundaries, domain-driven design (DDD) standards, and API versioning strategies across a large engineering organization?",
        2: "Explain your strategy for migrating a complex, legacy on-premise backend to a microservices architecture. How do you ensure zero-downtime, data consistency, and developer velocity?",
        3: "Design an enterprise-wide observability framework. How do you standardize distributed tracing, structured logging, and metrics aggregation across diverse technology stacks?",
        4: "How do you handle data governance, privacy compliance (GDPR/CCPA), and security audits in a backend ecosystem that processes millions of transactions?",
        5: "Architect a highly resilient cloud-native infrastructure capable of active-active multi-region deployment. Detail failover protocols, data replication lag handling, and global load balancing."
      }
    },
    'Full-Stack': {
      'Junior': {
        1: "Explain how the frontend communicates with the backend. What is JSON, and how do you handle basic API response errors on the UI?",
        2: "What are cookies, and how are they used to keep a user logged in across page refreshes?",
        3: "What is CORS (Cross-Origin Resource Sharing)? Why does the browser block requests, and how do you resolve it?",
        4: "Explain the difference between client-side validation and server-side validation. Why is server-side validation always required?",
        5: "How do you structure a simple full-stack app database? Design a basic schema for a blog (users, posts, comments)."
      },
      'Mid': {
        1: "Explain how session-based authentication differs from JWT-based authentication. Which headers or cookies are involved in securing them?",
        2: "What is client-side data hydration? How do you synchronize server-rendered HTML state with client-side state without causing layout shifts or duplicate API requests?",
        3: "Explain how you would implement optimistic UI updates on a collaborative board application. What happens if the server operation fails?",
        4: "How do you optimize network latency and resource delivery in a full-stack application (e.g. bundle size minimization, API responses, database query optimization)?",
        5: "Design a real-time collaborative document editor (like Google Docs). Explain the end-to-end data flow, state sync, database schema, and security rules."
      },
      'Senior': {
        1: "Compare BFF (Backend-for-Frontend) architecture with a unified GraphQL gateway. How do you manage schema federation, caching, and rate limiting in the gateway?",
        2: "Design a server-side rendering (SSR) pipeline with edge caching. How do you implement dynamic personalization without breaking CDN cache ratios?",
        3: "Explain how you would design a secure, cross-domain single-sign-on (SSO) flow using OAuth2 and OpenID Connect, securing tokens in the browser.",
        4: "How do you implement real-time collaborative state sync using CRDTs (Conflict-free Replicated Data Types) or OT (Operational Transformation)? Compare the architectural trade-offs.",
        5: "Design a complete end-to-end streaming media application. Explain storage caching, edge delivery, dynamic transcoding, metadata storage, and candidate playback analytics integration."
      },
      'Lead': {
        1: "How do you align frontend and backend engineering cycles, standardizing API contracts (e.g. OpenAPI, ProtoBuf) and testing flows (e.g. contract testing)?",
        2: "Explain your strategy for maintaining high-availability, scalability, and disaster recovery of a full-stack product during major global events or cloud provider outages.",
        3: "Design an end-to-end developer experience (DevEx) system from local sandbox environment running Docker/Tilt to automated preview environments on pull requests.",
        4: "How do you design, monitor, and scale authentication, authorization, and permission checks across hundreds of services and different client applications?",
        5: "Architect a scalable web platform hosting millions of user-generated content pages. Detail SEO optimizations, edge hydration, internationalization (i18n), dynamic rendering, and caching."
      }
    },
    'DevOps': {
      'Junior': {
        1: "What is Git, and what is the difference between a merge and a rebase? Explain a basic branching strategy.",
        2: "What is Docker, and why is it containerization useful? Explain how to write a basic Dockerfile to containerize a web app.",
        3: "What is a CI/CD pipeline in simple terms? What steps would you put in a pipeline to deploy a web application?",
        4: "What is SSH, and how do you use key pairs to securely access a remote Linux server?",
        5: "What are environment variables, and why should you never commit API keys or passwords directly to Git?"
      },
      'Mid': {
        1: "What is a CI/CD pipeline, and what are the differences between Blue-Green, Canary, and Rolling deployment strategies?",
        2: "Explain the difference between a Docker container and a Kubernetes Pod. What role do Ingress and Services play in pod communication?",
        3: "What is Infrastructure as Code (IaC)? How does Terraform manage environment state, and why is locking the state file critical in a team environment?",
        4: "Describe the difference between Prometheus and the ELK stack. How do you define and track SLAs, SLOs, and SLIs for a payment service?",
        5: "Design an automated, self-healing Kubernetes deployment architecture that scales dynamically based on CPU/Memory thresholds. Include your multi-stage Docker build, CI/CD pipeline, and Prometheus alerts configuration."
      },
      'Senior': {
        1: "How do you build a secure GitOps deployment pipeline using ArgoCD or Flux? Explain how secret management (e.g. HashiCorp Vault, Sealed Secrets) is handled.",
        2: "Design a service mesh architecture using Istio. Explain mutual TLS, traffic shifting, rate limiting, and observability across namespaces.",
        3: "Explain how you would write and structure reusable, multi-environment Terraform modules. How do you handle disaster recovery of Terraform state and lock files?",
        4: "Detail how you would configure a highly available Prometheus and Thanos monitoring cluster for long-term storage and cross-cluster query aggregation.",
        5: "Design an enterprise-level, secure, and isolated multi-tenant Kubernetes architecture. Explain Network Policies, RBAC, OPA Gatekeeper, and node selection standards."
      },
      'Lead': {
        1: "How do you build and foster a DevOps culture across an engineering team? Explain how you measure and optimize DORA metrics.",
        2: "Explain your strategy for migrating a complex, legacy on-premise infrastructure to a hybrid or multi-cloud ecosystem with zero downtime.",
        3: "Design an enterprise-level disaster recovery and business continuity plan. Detail RTO, RPO, backups validation, and failover/failback runs.",
        4: "How do you establish security standards, compliance (e.g., SOC2, PCI-DSS), and automated vulnerability scanning across all stages of the software supply chain?",
        5: "Architect a global-scale cloud platform with automated cost-optimization controls, budget alerts, auto-scaling thresholds, and multi-cloud management."
      }
    }
  };

  static const Map<String, Map<String, String>> _behavioralQuestions = {
    'Frontend': {
      'Junior': "Tell me about a project you worked on where you made a mistake. How did you handle it and what did you learn?",
      'Mid': "Tell me about a time when you had to optimize a legacy codebase with significant technical debt. How did you balance delivering new features while refactoring UI components, and how did you measure success?",
      'Senior': "Describe a complex technical conflict you resolved in a frontend team. What were the trade-offs, and how did you build alignment?",
      'Lead': "Tell me about a time you mentored a junior team member or led a major architectural migration. How did you influence the team and manage stakeholder expectations?"
    },
    'Backend': {
      'Junior': "Tell me about a time you had to learn a new programming language or tool quickly to complete a task. How did you go about it?",
      'Mid': "Describe a production outage or critical database performance bottleneck you encountered. How did you diagnose the issue, resolve it under pressure, and what post-mortem actions did you implement?",
      'Senior': "Tell me about a time when you had to make a high-stakes architectural decision with incomplete information. What was the decision, how did you evaluate the risks, and what was the outcome?",
      'Lead': "Describe how you led a cross-functional team through a major system redesign or database migration. How did you communicate risks, coordinate tasks, and keep the team motivated?"
    },
    'Full-Stack': {
      'Junior': "Tell me about a full-stack project you are most proud of. What was your role, and what challenges did you overcome?",
      'Mid': "Tell me about a project where you had to bridge the gap between complex database capabilities and client-side performance. How did you coordinate with product managers or frontend engineers, and how did you resolve technical conflicts?",
      'Senior': "Describe a time when you had to optimize end-to-end latency for a highly transactional feature. How did you balance the changes between frontend rendering and backend storage optimization?",
      'Lead': "Explain how you set engineering standards, API guidelines, and deployment practices for a full-stack team. How did you resolve developer friction and technical debt issues?"
    },
    'DevOps': {
      'Junior': "Tell me about a time you struggled with a deployment or build pipeline error. What steps did you take to troubleshoot and resolve it?",
      'Mid': "Explain how you handled a scenario where a deployment broke production despite passing all staging automated tests. How did you rollback, how did you audit the pipeline failure, and how did you secure alignment with the dev team?",
      'Senior': "Describe a time you architected the migration of a legacy infrastructure to a modern CI/CD flow. How did you ensure security, minimize downtime, and train other developers?",
      'Lead': "Tell me about a major security incident or complete cloud provider outage you had to manage. How did you lead the recovery effort, coordinate stakeholders, and implement structural prevention measures?"
    }
  };

  static String get _nodeBaseUrl {
    // Use BACKEND_HOST if provided at build time:
    //   flutter build apk --dart-define=BACKEND_HOST=192.168.1.x
    const customHost = String.fromEnvironment('BACKEND_HOST', defaultValue: '');
    if (customHost.isNotEmpty) return 'http://$customHost:3000/api';
    if (kIsWeb) return 'http://localhost:3000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api'; // emulator
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  static String get _aiBaseUrl {
    const customHost = String.fromEnvironment('BACKEND_HOST', defaultValue: '');
    if (customHost.isNotEmpty) return 'http://$customHost:8000/api';
    if (kIsWeb) return 'http://localhost:8000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api'; // emulator
    } catch (_) {}
    return 'http://localhost:8000/api';
  }

  final Dio _dioNode = Dio(BaseOptions(baseUrl: _nodeBaseUrl));
  final Dio _dioAI = Dio(BaseOptions(baseUrl: _aiBaseUrl));
  Timer? _timer;
  StreamSubscription? _authSubscription;

  InterviewNotifier() : super(InterviewState()) {
    _initAuth();
  }

  void _initAuth() {
    final currentSession = sb.Supabase.instance.client.auth.currentSession;
    final user = currentSession?.user;
    if (user != null) {
      final meta = user.userMetadata ?? {};
      final originalResumeText = meta['resume_text'] as String?;
      final gapAnalysisReport = meta['gap_analysis'] as String?;
      final targetJob = meta['target_job'] as String? ?? 'Senior Backend Engineer';
      Map<String, String> enhanced = {};
      if (meta['enhanced_phrasing'] != null) {
        try {
          (meta['enhanced_phrasing'] as Map).forEach((k, v) {
            enhanced[k.toString()] = v.toString();
          });
        } catch (_) {}
      }

      state = state.copyWith(
        currentUser: user,
        originalResumeText: originalResumeText,
        gapAnalysisReport: gapAnalysisReport,
        targetJob: targetJob,
        enhancedPhrasing: enhanced,
      );
      loadPastInterviews();
    } else {
      state = state.copyWith(
        clearCurrentUser: true,
        clearOriginalResumeText: true,
        clearGapAnalysisReport: true,
        enhancedPhrasing: const {},
      );
    }

    _authSubscription = sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final u = session?.user;
      if (u != null) {
        final meta = u.userMetadata ?? {};
        final originalResumeText = meta['resume_text'] as String?;
        final gapAnalysisReport = meta['gap_analysis'] as String?;
        final targetJob = meta['target_job'] as String? ?? 'Senior Backend Engineer';
        Map<String, String> enhanced = {};
        if (meta['enhanced_phrasing'] != null) {
          try {
            (meta['enhanced_phrasing'] as Map).forEach((k, v) {
              enhanced[k.toString()] = v.toString();
            });
          } catch (_) {}
        }

        state = state.copyWith(
          currentUser: u,
          originalResumeText: originalResumeText,
          gapAnalysisReport: gapAnalysisReport,
          targetJob: targetJob,
          enhancedPhrasing: enhanced,
          errorMessage: null,
        );
        loadPastInterviews();
      } else {
        state = state.copyWith(
          clearCurrentUser: true,
          clearOriginalResumeText: true,
          clearGapAnalysisReport: true,
          enhancedPhrasing: const {},
          pastInterviews: const [],
          currentView: 'dashboard',
          errorMessage: null,
        );
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
          await sb.Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'email': user.email ?? email,
            'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'User',
            'last_login_at': DateTime.now().toUtc().toIso8601String(),
          });

          await sb.Supabase.instance.client.from('login_history').insert({
            'user_id': user.id,
          });
        } catch (dbError) {
          debugPrint('Error logging login details to DB: $dbError');
        }
      }
      state = state.copyWith(isLoading: false, isDemoMode: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUp(String email, String password, {String? name}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await sb.Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: name != null && name.isNotEmpty ? {'full_name': name} : null,
      );
      state = state.copyWith(isLoading: false, isDemoMode: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      state = state.copyWith(isDemoMode: false);
      await sb.Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint("Error during signOut: $e");
    } finally {
      state = state.copyWith(
        clearCurrentUser: true,
        clearActiveInterviewId: true,
        clearReportMarkdown: true,
        clearOriginalResumeText: true,
        clearGapAnalysisReport: true,
        currentView: 'dashboard',
        pastInterviews: const [],
      );
    }
  }

  void enterDemoMode() {
    state = state.copyWith(isDemoMode: true, errorMessage: null);
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

  Future<void> setTargetJob(String targetJob) async {
    state = state.copyWith(targetJob: targetJob);
    try {
      final user = sb.Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await sb.Supabase.instance.client.auth.updateUser(
          sb.UserAttributes(
            data: {
              ...user.userMetadata ?? {},
              'target_job': targetJob,
            },
          ),
        );
      }
    } catch (authErr) {
      debugPrint('Error updating target job in metadata: $authErr');
    }
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

        // Update user metadata in Supabase to persist the resume details
        try {
          final user = sb.Supabase.instance.client.auth.currentUser;
          if (user != null) {
            await sb.Supabase.instance.client.auth.updateUser(
              sb.UserAttributes(
                data: {
                  ...user.userMetadata ?? {},
                  'resume_text': state.originalResumeText,
                  'enhanced_phrasing': state.enhancedPhrasing,
                  'gap_analysis': state.gapAnalysisReport,
                  'target_job': state.targetJob,
                },
              ),
            );
          }
        } catch (authErr) {
          debugPrint('Error updating user metadata with resume: $authErr');
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to analyze resume file: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        originalResumeText: """# Alex Mercer
**Email:** alex.mercer@devmail.com | **GitHub:** github.com/alexmercer | **Location:** San Francisco, CA

## Professional Summary
Results-driven Senior Systems Developer with 6+ years of experience specializing in backend architectures, microservices optimization, and automated cloud deployments. Proven track record of scaling database performance and streamlining CI/CD workflows.

## Core Technical Skills
* **Programming Languages:** Go (Golang), Python, TypeScript, SQL, Java
* **Frameworks & Libraries:** Node.js (Express), FastAPI, Gin, Flutter
* **Databases & Caching:** PostgreSQL, MongoDB, Redis, Elasticsearch
* **Cloud & DevOps:** AWS (ECS, RDS, S3), Docker, Terraform, GitHub Actions

## Work Experience
### Senior Backend Engineer | Techflow Solutions (2023 - Present)
* Architected and managed CI/CD deployment pipelines using GitHub Actions and Terraform on AWS ECS, reducing deployment cycle times by 40%.
* Optimized PostgreSQL database indexing and query paths, reducing slow query executions by 42% and query response latency by 150ms.
* Engineered high-throughput microservices using Go and Redis to handle up to 15,000 requests per minute with 99.9% uptime.

### Software Developer | CloudScale Corp (2020 - 2023)
* Built scalable RESTful APIs in Node.js/Express, increasing system resilience under heavy loads.
* Collaborated on migrating database architectures from monolithic clusters to microservices-based datastores.

## Education & Certifications
* **B.S. in Computer Science** | Stanford University (2016 - 2020)
* **AWS Certified Solutions Architect (Associate)**""",
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

      // Save fallback to metadata as well so it persists
      try {
        final user = sb.Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await sb.Supabase.instance.client.auth.updateUser(
            sb.UserAttributes(
              data: {
                ...user.userMetadata ?? {},
                'resume_text': state.originalResumeText,
                'enhanced_phrasing': state.enhancedPhrasing,
                'gap_analysis': state.gapAnalysisReport,
                'target_job': state.targetJob,
              },
            ),
          );
        }
      } catch (authErr) {
        debugPrint('Error updating user metadata with fallback resume: $authErr');
      }
    }
  }
  // API Call: Start a new Mock Interview Session
  Future<void> startInterview() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final dummyInterviewId = const Uuid().v4();

    int offlineDifficulty = 2;
    if (state.experienceTier == 'Junior') {
      offlineDifficulty = 1;
    } else if (state.experienceTier == 'Mid') {
      offlineDifficulty = 2;
    } else if (state.experienceTier == 'Senior') {
      offlineDifficulty = 3;
    } else if (state.experienceTier == 'Lead') {
      offlineDifficulty = 4;
    }

    if (state.isDemoMode) {
      final initialQuestion = _fallbackQuestions[state.domain]?[state.experienceTier]?[1] ??
          _fallbackQuestions[state.domain]?['Mid']?[1] ??
          "Explain your technical background.";
      state = state.copyWith(
        activeInterviewId: dummyInterviewId,
        currentStep: 1,
        currentQuestion: initialQuestion,
        currentDifficulty: offlineDifficulty,
        stepsHistory: [
          {
            'question': initialQuestion,
            'answer': null,
            'score': null
          }
        ],
        currentView: 'terminal',
        isLoading: false,
      );
      startTimer();
      return;
    }

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
      final int difficulty = (startRes.data['difficulty'] ?? offlineDifficulty) as int;

      state = state.copyWith(
        activeInterviewId: interviewId,
        currentStep: 1,
        currentQuestion: question,
        currentDifficulty: difficulty,
        stepsHistory: [
          {'question': question, 'answer': null, 'score': null}
        ],
        currentView: 'terminal',
        isLoading: false,
      );
      
      startTimer();
      await _logEvent('INTERVIEW_START', 'Started new interview $interviewId for ${state.domain}');
    } catch (e) {
      debugPrint('Error starting interview: $e');
      // Dynamic fallback for offline/disconnected states
      final initialQuestion = _fallbackQuestions[state.domain]?[state.experienceTier]?[1] ??
          _fallbackQuestions[state.domain]?['Mid']?[1] ??
          "Explain your technical background.";
      state = state.copyWith(
        activeInterviewId: dummyInterviewId,
        currentStep: 1,
        currentQuestion: initialQuestion,
        currentDifficulty: offlineDifficulty,
        stepsHistory: [
          {
            'question': initialQuestion,
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

    if (state.isDemoMode) {
      _runOfflineSubmitAnswer(answer);
      return;
    }

    try {
      final response = await _dioAI.post(
        '/evaluate',
        data: {
          'interview_id': state.activeInterviewId,
          'user_answer': answer,
          'step_order': state.currentStep,
          'current_difficulty': state.currentDifficulty,
          'domain': state.domain,
          'experience_tier': state.experienceTier,
          'resume_context': state.originalResumeText,
          'current_question': state.currentQuestion,
          'steps_history': state.stepsHistory,
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

        final newMock = {
          'id': state.activeInterviewId ?? const Uuid().v4(),
          'domain': state.domain,
          'experience_tier': state.experienceTier,
          'overall_score': scoreVal,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'report': report,
        };
        final updatedPast = [newMock, ...state.pastInterviews];

        state = state.copyWith(
          stepsHistory: updatedHistory,
          currentStep: 7,
          overallScore: scoreVal,
          reportMarkdown: report,
          currentView: 'evaluation',
          isLoading: false,
          pastInterviews: updatedPast,
        );

        // Persist to local disk so history survives sign-out
        final userId = state.currentUser?.id ?? 'anonymous';
        await HiveStorage.saveInterview(userId, newMock);

        await _logEvent('INTERVIEW_COMPLETE', 'Completed interview ${state.activeInterviewId}');
        loadPastInterviews(); // refresh profile ledger
      } else {
        // Prepare next step
        final nextQuestion = data['next_question'] ?? 'Tell me more.';
        final int nextDifficulty = (data['next_difficulty'] ?? state.currentDifficulty) as int;
        updatedHistory.add({'question': nextQuestion, 'answer': null, 'score': null});

        state = state.copyWith(
          stepsHistory: updatedHistory,
          currentStep: state.currentStep + 1,
          currentQuestion: nextQuestion,
          currentDifficulty: nextDifficulty,
          isLoading: false,
        );

        startTimer();
        await _logEvent('STEP_SUBMIT', 'Submitted step ${state.currentStep - 1} answer');
      }
    } catch (e) {
      debugPrint('Error submitting answer: $e');
      _runOfflineSubmitAnswer(answer);
    }
  }

  Future<void> endInterviewEarly() async {
    if (state.activeInterviewId == null) return;
    
    stopTimer();
    state = state.copyWith(isLoading: true, errorMessage: null);

    if (state.isDemoMode) {
      // Offline fallback for ending early
      double totalScores = 0.0;
      int count = 0;
      final updatedHistory = List<Map<String, dynamic>>.from(state.stepsHistory);
      for (var step in updatedHistory) {
        if (step['score'] != null) {
          totalScores += step['score'] as double;
          count++;
        }
      }
      final calculatedOverallScore = count > 0 ? (totalScores / count * 100).round() : 0;

      final buffer = StringBuffer();
      buffer.writeln("# Performance Evaluation Report (Session Ended Early)");
      buffer.writeln("");
      buffer.writeln("## 1. Executive Summary");
      buffer.writeln("**Overall Score:** `$calculatedOverallScore / 100` (Based on $count answered questions)");
      
      String rank = "Junior";
      if (calculatedOverallScore >= 85) {
        rank = "Senior Developer";
      } else if (calculatedOverallScore >= 70) {
        rank = "Mid-Level Engineer";
      } else {
        rank = "Junior Developer";
      }
      buffer.writeln("**Domain Performance Rank:** $rank");
      buffer.writeln("");
      buffer.writeln("*Note: This session was ended early by the candidate.*");
      buffer.writeln("");
      buffer.writeln("## 2. Question-by-Question Breakdown");
      buffer.writeln("| # | Question Prompt | Score (1-10) |");
      buffer.writeln("|---|-----------------|--------------|");
      
      for (int i = 0; i < updatedHistory.length; i++) {
        final step = updatedHistory[i];
        if (step['score'] != null) {
          final qPrompt = step['question'] as String? ?? 'Technical Question';
          final qShort = qPrompt.length > 55 ? '${qPrompt.substring(0, 52)}...' : qPrompt;
          final stepScore = step['score'] as double;
          final scoreOutOf10 = (stepScore * 10).round();
          buffer.writeln("| ${i + 1} | $qShort | $scoreOutOf10/10 |");
        }
      }
      buffer.writeln("");
      buffer.writeln("## 3. Domain-Specific Feedback Matrix");
      buffer.writeln("* **Conceptual Depth:** Needs full session context for detailed mapping.");
      buffer.writeln("* **System Design & Scaling Thinking:** Only partial answers available.");
      buffer.writeln("* **Communication & Precision:** Direct, but session was shortened.");
      buffer.writeln("");
      buffer.writeln("## 4. Actionable Upskilling Roadmap");
      buffer.writeln("* **Immediate Reading/Practice:** Focus on completing all session stages.");
      
      final mockReport = buffer.toString();

      final newMock = {
        'id': state.activeInterviewId ?? const Uuid().v4(),
        'domain': state.domain,
        'experience_tier': state.experienceTier,
        'overall_score': calculatedOverallScore,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'report': mockReport,
      };

      state = state.copyWith(
        stepsHistory: updatedHistory,
        currentStep: 7,
        overallScore: calculatedOverallScore,
        reportMarkdown: mockReport,
        currentView: 'evaluation',
        isLoading: false,
        pastInterviews: [newMock, ...state.pastInterviews],
      );

      final userId = state.currentUser?.id ?? 'anonymous';
      await HiveStorage.saveInterview(userId, newMock);
      return;
    }

    try {
      final response = await _dioAI.post(
        '/interviews/end',
        data: {
          'interview_id': state.activeInterviewId,
          'domain': state.domain,
          'experience_tier': state.experienceTier,
          'steps_history': state.stepsHistory.map((step) {
            return {
              'question': step['question'],
              'answer': step['answer'],
              'score': step['score'],
            };
          }).toList(),
        },
      );

      final data = response.data;
      final scoreVal = (data['overall_score'] ?? 0) as int;
      final report = data['report'] ?? 'No evaluation report generated.';

      final newMock = {
        'id': state.activeInterviewId ?? const Uuid().v4(),
        'domain': state.domain,
        'experience_tier': state.experienceTier,
        'overall_score': scoreVal,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'report': report,
      };

      state = state.copyWith(
        currentStep: 7,
        overallScore: scoreVal,
        reportMarkdown: report,
        currentView: 'evaluation',
        isLoading: false,
        pastInterviews: [newMock, ...state.pastInterviews],
      );

      final userId = state.currentUser?.id ?? 'anonymous';
      await HiveStorage.saveInterview(userId, newMock);
      
      await _logEvent('INTERVIEW_EARLY_END', 'Ended interview ${state.activeInterviewId} early');
      loadPastInterviews();
    } catch (e) {
      debugPrint('Error ending interview early: $e');
      // If server fails, fallback to local evaluation calculation to ensure candidate doesn't lose progress
      double totalScores = 0.0;
      int count = 0;
      final updatedHistory = List<Map<String, dynamic>>.from(state.stepsHistory);
      for (var step in updatedHistory) {
        if (step['score'] != null) {
          totalScores += step['score'] as double;
          count++;
        }
      }
      final calculatedOverallScore = count > 0 ? (totalScores / count * 100).round() : 0;
      final buffer = StringBuffer();
      buffer.writeln("# Performance Evaluation Report (Session Ended Early - Offline)");
      buffer.writeln("");
      buffer.writeln("## 1. Executive Summary");
      buffer.writeln("**Overall Score:** `$calculatedOverallScore / 100` (Based on $count answered questions)");
      buffer.writeln("**Domain Performance Rank:** ${state.experienceTier} ${state.domain} Developer");
      buffer.writeln("");
      buffer.writeln("*Note: This session was ended early, and report was compiled locally due to connection error.*");
      buffer.writeln("");
      buffer.writeln("## 2. Question-by-Question Breakdown");
      buffer.writeln("| # | Question Prompt | Score (1-10) |");
      buffer.writeln("|---|-----------------|--------------|");
      for (int i = 0; i < updatedHistory.length; i++) {
        final step = updatedHistory[i];
        if (step['score'] != null) {
          final qPrompt = step['question'] as String? ?? 'Technical Question';
          final qShort = qPrompt.length > 55 ? '${qPrompt.substring(0, 52)}...' : qPrompt;
          final stepScore = step['score'] as double;
          final scoreOutOf10 = (stepScore * 10).round();
          buffer.writeln("| ${i + 1} | $qShort | $scoreOutOf10/10 |");
        }
      }
      final mockReport = buffer.toString();

      final newMock = {
        'id': state.activeInterviewId ?? const Uuid().v4(),
        'domain': state.domain,
        'experience_tier': state.experienceTier,
        'overall_score': calculatedOverallScore,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'report': mockReport,
      };

      state = state.copyWith(
        stepsHistory: updatedHistory,
        currentStep: 7,
        overallScore: calculatedOverallScore,
        reportMarkdown: mockReport,
        currentView: 'evaluation',
        isLoading: false,
        pastInterviews: [newMock, ...state.pastInterviews],
      );

      final userId = state.currentUser?.id ?? 'anonymous';
      await HiveStorage.saveInterview(userId, newMock);
    }
  }

  void _runOfflineSubmitAnswer(String answer) {
    final updatedHistory = List<Map<String, dynamic>>.from(state.stepsHistory);
    double localScore = 0.5;
    if (updatedHistory.isNotEmpty) {
      final currentQ = updatedHistory.last['question'] as String? ?? '';
      localScore = _calculateMockScore(answer, currentQ);
      updatedHistory.last['answer'] = answer;
      updatedHistory.last['score'] = localScore;
    }

    if (state.currentStep < 6) {
      String nextQ = '';
      if (state.currentStep < 5) {
        nextQ = _fallbackQuestions[state.domain]?[state.experienceTier]?[state.currentStep + 1] ??
            _fallbackQuestions[state.domain]?['Mid']?[state.currentStep + 1] ??
            "Describe a scaling challenge in your architecture.";
      } else {
        nextQ = _behavioralQuestions[state.domain]?[state.experienceTier] ??
            _behavioralQuestions[state.domain]?['Mid'] ??
            "Tell me about a time you solved a hard technical problem.";
      }
      updatedHistory.add({'question': nextQ, 'answer': null, 'score': null});

      int nextDifficulty = state.currentDifficulty;
      if (localScore >= 0.8) {
        nextDifficulty = (state.currentDifficulty + 1).clamp(1, 5);
      } else if (localScore <= 0.4) {
        nextDifficulty = (state.currentDifficulty - 1).clamp(1, 5);
      }

      state = state.copyWith(
        stepsHistory: updatedHistory,
        currentStep: state.currentStep + 1,
        currentQuestion: nextQ,
        currentDifficulty: nextDifficulty,
        isLoading: false,
      );
      startTimer();
    } else {
      // Calculate dynamic overall score
      double totalScores = 0.0;
      int count = 0;
      for (var step in updatedHistory) {
        if (step['score'] != null) {
          totalScores += step['score'] as double;
          count++;
        }
      }
      final overallScore = count > 0 ? (totalScores / count * 100).round() : 75;

      // Dynamic Markdown Report
      final buffer = StringBuffer();
      buffer.writeln("# Performance Evaluation Report");
      buffer.writeln("");
      buffer.writeln("## 1. Executive Summary");
      buffer.writeln("**Overall Score:** `$overallScore / 100`");
      
      String rank = "Junior";
      if (overallScore >= 85) {
        rank = "Senior Developer";
      } else if (overallScore >= 70) {
        rank = "Mid-Level Engineer";
      } else {
        rank = "Junior Developer";
      }
      buffer.writeln("**Domain Performance Rank:** $rank");
      buffer.writeln("");
      buffer.writeln("**Key Assessment Metrics:**");
      buffer.writeln("- Concept precision matched: ${(overallScore >= 80 ? 'High depth' : 'Moderate depth')}");
      buffer.writeln("- Discussion of structural limits: ${(overallScore >= 75 ? 'Explicitly addressed' : 'Needs more detail')}");
      buffer.writeln("");
      buffer.writeln("## 2. Question-by-Question Breakdown");
      buffer.writeln("| # | Question Prompt | Score (1-10) |");
      buffer.writeln("|---|-----------------|--------------|");
      
      for (int i = 0; i < updatedHistory.length; i++) {
        final step = updatedHistory[i];
        final qPrompt = step['question'] as String? ?? 'Technical Question';
        final qShort = qPrompt.length > 55 ? '${qPrompt.substring(0, 52)}...' : qPrompt;
        final stepScore = step['score'] as double? ?? 0.8;
        final scoreOutOf10 = (stepScore * 10).round();
        buffer.writeln("| ${i + 1} | $qShort | $scoreOutOf10/10 |");
      }
      buffer.writeln("");
      buffer.writeln("## 3. Domain-Specific Feedback Matrix");
      buffer.writeln("* **Conceptual Depth:** Candidate demonstrates ${(overallScore >= 80 ? 'robust theoretical depth and terminology accuracy.' : 'basic understanding but lacks depth in core execution frameworks.')}");
      buffer.writeln("* **System Design & Scaling Thinking:** ${(overallScore >= 75 ? 'Excellent focus on trade-offs, scaling paths, and database limits.' : 'Needs more elaboration on capacity estimation, memory footprint, and horizontal scaling limits.')}");
      buffer.writeln("* **Communication & Precision:** Answers are structured, but can be improved with step-by-step optimization logs.");
      buffer.writeln("");
      buffer.writeln("## 4. Actionable Upskilling Roadmap");
      buffer.writeln("* **Immediate Reading/Practice:** Review advanced design patterns, indexing optimization, and cache eviction standards.");
      buffer.writeln("* **Code Exercises Suggested:** Build a sandbox replication cluster environment to monitor database read/write throughput under heavy workloads.");
      
      final mockReport = buffer.toString();

      final newMock = {
        'id': state.activeInterviewId ?? const Uuid().v4(),
        'domain': state.domain,
        'experience_tier': state.experienceTier,
        'overall_score': overallScore,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'report': mockReport,
      };
      final updatedPast = [newMock, ...state.pastInterviews];

      state = state.copyWith(
        stepsHistory: updatedHistory,
        currentStep: 7,
        overallScore: overallScore,
        reportMarkdown: mockReport,
        currentView: 'evaluation',
        isLoading: false,
        pastInterviews: updatedPast,
      );

      // Persist to local disk so history survives sign-out
      final userId = state.currentUser?.id ?? 'anonymous';
      HiveStorage.saveInterview(userId, newMock);
    }
  }

  // Load ledger list of mock interviews: merges Supabase + local disk + in-memory
  Future<void> loadPastInterviews() async {
    final user = state.currentUser;
    if (user == null) return;

    final List<Map<String, dynamic>> list = [];
    final Set<String> seenIds = {};

    // 1. Try loading from Supabase
    try {
      final response = await sb.Supabase.instance.client
          .from('interviews')
          .select('*, interview_steps(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      for (var item in (response as List)) {
        final steps = item['interview_steps'] as List?;
        String? report;
        if (steps != null) {
          final reportStep = steps.firstWhere(
            (s) => s['step_order'] == 7 || s['dynamic_question'] == 'Evaluation Report',
            orElse: () => null,
          );
          if (reportStep != null) {
            report = reportStep['user_answer'];
          }
        }
        final record = {
          'id': item['id'],
          'domain': item['domain'],
          'experience_tier': item['experience_tier'],
          'overall_score': item['overall_score'] ?? 0,
          'created_at': item['created_at'],
          'report': report,
        };
        if (seenIds.add(record['id'].toString())) {
          list.add(record);
        }
      }
    } catch (e) {
      debugPrint('Supabase unavailable, will rely on local disk: $e');
    }

    // 2. Merge local disk storage (source of truth when Supabase is down)
    try {
      final localRecords = await HiveStorage.loadInterviews(user.id);
      for (var localItem in localRecords) {
        if (seenIds.add(localItem['id'].toString())) {
          list.add(localItem);
        }
      }
    } catch (e) {
      debugPrint('Error loading local storage interviews: $e');
    }

    // 3. Merge any in-memory interviews not yet saved to disk (race condition guard)
    for (var memItem in state.pastInterviews) {
      if (seenIds.add(memItem['id'].toString())) {
        list.add(memItem);
      }
    }

    // Sort by created_at descending (newest first)
    list.sort((a, b) {
      final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    state = state.copyWith(pastInterviews: list);
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

  double _calculateMockScore(String answer, String question) {
    final cleanAns = answer.trim().toLowerCase();
    if (cleanAns.isEmpty) return 0.0;
    
    // Check for negative/empty responses using word boundaries to avoid false positives (e.g., 'passed' matching 'pass')
    final lowScoreTerms = ['idk', 'dont know', 'don\'t know', 'no idea', 'skip', 'pass', 'i do not know', 'nada', 'nothing', 'whatever', 'no clue'];
    bool hasLowScoreTerm = false;
    for (final term in lowScoreTerms) {
      final regex = RegExp('\\b${RegExp.escape(term)}\\b', caseSensitive: false);
      if (regex.hasMatch(cleanAns)) {
        hasLowScoreTerm = true;
        break;
      }
    }
    if (cleanAns.length < 12 || hasLowScoreTerm) {
      // Return a very low score for generic/placeholder answers
      return 0.1;
    }
    
    int matchCount = 0;
    
    // 1. Dynamic Question-based Keyword Matching
    // Extract words from the question that are likely key terms (length >= 3 and not a common stop word)
    final stopWords = {
      'what', 'why', 'how', 'when', 'where', 'who', 'which', 'whom', 'whose',
      'this', 'that', 'these', 'those', 'their', 'there', 'here', 'with', 'from',
      'about', 'between', 'under', 'over', 'above', 'below', 'after', 'before',
      'each', 'every', 'some', 'any', 'none', 'both', 'either', 'neither',
      'would', 'could', 'should', 'shall', 'will', 'might', 'must', 'have', 'has',
      'had', 'does', 'do', 'did', 'done', 'doing', 'been', 'being', 'were', 'was',
      'are', 'is', 'am', 'the', 'and', 'but', 'for', 'you', 'your', 'ours', 'our',
      'him', 'his', 'her', 'she', 'its', 'they', 'them', 'than', 'then', 'once',
      'only', 'very', 'just', 'more', 'most', 'such', 'through', 'to', 'too',
      'until', 'up', 'while', 'yourself', 'yourselves', 'explain', 'difference'
    };

    final questionWords = question
        .replaceAll(RegExp(r'[^\w\s\-\+]'), '')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3 && !stopWords.contains(w))
        .toSet();
        
    for (final qWord in questionWords) {
      if (cleanAns.contains(qWord)) {
        matchCount += 2; // Extra weight for answering relevant question terms
      }
    }
    
    // 2. Domain/General Tech Keywords Matching (Aligned with Frontend, Backend, Fullstack, and DevOps domains)
    final techKeywords = [
      // Backend / SQL / Databases
      'sql', 'postgresql', 'mysql', 'nosql', 'mongodb', 'redis', 'acid', 'isolation',
      'index', 'b-tree', 'gin', 'concurrency', 'event loop', 'pooling', 'cache',
      'rabbitmq', 'kafka', 'microservice', 'join', 'query', 'database', 'transaction',
      'n+1', 'restful', 'rest', 'grpc', 'graphql', 'websocket', 'http', 'schema',
      'table', 'select', 'null', 'where', 'normalization', 'relation', 'sorting',
      'thread', 'bottleneck', 'load balancer', 'performance',
      
      // Frontend / Rendering
      'virtual dom', 'dom', 'lifecycle', 'hook', 'usememo', 'usecallback', 'useeffect',
      'redux', 'context api', 'context', 'zustand', 'recoil', 'rendering path', 'code splitting',
      'lazy loading', 'web vitals', 'lcp', 'fid', 'cls', 'ssr', 'ssg', 'isr',
      'state', 'props', 'component', 'react', 'vue', 'rendering', 'html', 'css', 'js',
      'router', 'state management',
      
      // Fullstack / Auth / Security
      'jwt', 'oauth2', 'cookie', 'http-only', 'hydration', 'optimistic ui', 'latency',
      'query optimization', 'bundle', 'integration', 'cors', 'validation', 'xss', 'csrf',
      'auth', 'session', 'security', 'scale', 'trade-off',
      
      // DevOps / Cloud / Pipelines
      'ci/cd', 'blue-green', 'canary', 'rolling', 'github actions', 'jenkins',
      'docker', 'kubernetes', 'pod', 'deployment', 'ingress', 'terraform',
      'prometheus', 'grafana', 'elk', 'sla', 'slo', 'sli', 'git', 'pipeline',
      'ssh', 'variables', 'deploy', 'aws', 'gcp', 'cloud', 'yaml', 'yml', 'port'
    ];
    
    for (final kw in techKeywords) {
      if (cleanAns.contains(kw)) {
        matchCount++;
      }
    }
    
    // Calculate score: base of 0.2 + matches
    double score = 0.2 + (matchCount * 0.06);
    
    // Word count contribution
    final wordCount = cleanAns.split(RegExp(r'\s+')).length;
    if (wordCount > 60) {
      score += 0.25;
    } else if (wordCount > 30) {
      score += 0.15;
    } else if (wordCount > 15) {
      score += 0.08;
    }
    
    return score.clamp(0.1, 0.98);
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
