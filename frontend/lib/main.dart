import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'providers/interview_provider.dart';
import 'services/local_storage.dart';

// Import Views
import 'views/dashboard_view.dart';
import 'views/setup_view.dart';
import 'views/terminal_view.dart';
import 'views/evaluation_view.dart';
import 'views/profile_view.dart';
import 'views/login_view.dart';
import 'views/resume_labs_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local interview history persistence
  await HiveStorage.init();

  // Safe Supabase initialization for mock/production configuration
  try {
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://yfzmdwusatnmgslvpsqg.supabase.co',
      ),
      publishableKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_IFAJdiG9yUTuG0q8m5B-8g_lmZelLuj',
      ),
    );
  } catch (e) {
    debugPrint('Supabase initialize graceful fallback: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interviewProvider);
    AppTheme.isDarkState = state.isDarkMode;
    return MaterialApp(
      title: 'AI Interview Prep Coach',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: (state.currentUser == null && !state.isDemoMode)
          ? const LoginView()
          : const MainShellLayout(),
    );
  }
}

class MainShellLayout extends ConsumerWidget {
  const MainShellLayout({super.key});

  Widget _buildSidebarContent(
    BuildContext context,
    InterviewState state,
    InterviewNotifier notifier,
  ) {
    final bool isSessionActive =
        state.activeInterviewId != null && state.currentStep < 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Brand Section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.terminal,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "InterviewerAI",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Elite Prep Coach",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        Divider(
          height: 1,
          color: state.isDarkMode
              ? const Color(0xFF2D2D34)
              : const Color(0xFFD2D7DF),
          thickness: 1.5,
        ),

        // Navigation menu items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSidebarItem(
                context: context,
                title: "Dashboard Overview",
                icon: Icons.dashboard,
                viewKey: 'dashboard',
                currentView: state.currentView,
                isDisabled: isSessionActive,
                onTap: () {
                  notifier.setView('dashboard');
                  if (MediaQuery.of(context).size.width < 800) {
                    Navigator.pop(context);
                  }
                },
              ),
              _buildSidebarItem(
                context: context,
                title: "Setup Mock Interview",
                icon: Icons.settings_suggest,
                viewKey: 'setup',
                currentView: state.currentView,
                isDisabled: isSessionActive,
                onTap: () {
                  notifier.setView('setup');
                  if (MediaQuery.of(context).size.width < 800) {
                    Navigator.pop(context);
                  }
                },
              ),
              _buildSidebarItem(
                context: context,
                title: "Active Terminal",
                icon: Icons.computer,
                viewKey: 'terminal',
                currentView: state.currentView,
                isDisabled:
                    state.activeInterviewId == null || state.currentStep >= 7,
                onTap: () {
                  notifier.setView('terminal');
                  if (MediaQuery.of(context).size.width < 800) {
                    Navigator.pop(context);
                  }
                },
              ),
              _buildSidebarItem(
                context: context,
                title: "Resume Labs",
                icon: Icons.work,
                viewKey: 'resume_labs',
                currentView: state.currentView,
                isDisabled: isSessionActive,
                onTap: () {
                  notifier.setView('resume_labs');
                  if (MediaQuery.of(context).size.width < 800) {
                    Navigator.pop(context);
                  }
                },
              ),
              _buildSidebarItem(
                context: context,
                title: "Profile & History Ledger",
                icon: Icons.person,
                viewKey: 'profile',
                currentView: state.currentView,
                isDisabled: isSessionActive,
                onTap: () {
                  notifier.setView('profile');
                  if (MediaQuery.of(context).size.width < 800) {
                    Navigator.pop(context);
                  }
                },
              ),
              _buildSidebarItem(
                context: context,
                title: state.isDarkMode ? "Light Mode" : "Dark Mode",
                icon: state.isDarkMode
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
                viewKey: 'theme_toggle',
                currentView: '',
                onTap: () => notifier.toggleTheme(),
              ),
              _buildSidebarItem(
                context: context,
                title: "Sign Out",
                icon: Icons.logout,
                viewKey: 'logout',
                currentView: '',
                onTap: () {
                  if (MediaQuery.of(context).size.width < 800) {
                    Navigator.pop(context);
                  }
                  _showSignOutConfirmation(context, state, notifier);
                },
              ),
            ],
          ),
        ),

        Divider(
          height: 1,
          color: state.isDarkMode
              ? const Color(0xFF2D2D34)
              : const Color(0xFFD2D7DF),
          thickness: 1.5,
        ),

        // Bottom Session Status Card
        Container(
          padding: const EdgeInsets.all(20),
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: state.isDemoMode
                    ? Colors.orangeAccent.withValues(alpha: 0.8)
                    : Theme.of(context).colorScheme.primary,
                child: Icon(
                  state.isDemoMode
                      ? Icons.science_outlined
                      : Icons.cloud_done_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isDemoMode ? "Demo Mode Active" : "Online Mode",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      state.isDemoMode
                          ? "Client offline sync active"
                          : "AI cloud sync active",
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 750;
    final bool isTablet = screenWidth >= 750 && screenWidth < 1100;
    final double sidebarWidth = isTablet ? 80.0 : 260.0;

    // Map currentView string to actual view Widget
    Widget activeViewWidget;
    String viewTitle = 'Dashboard';
    switch (state.currentView) {
      case 'dashboard':
        activeViewWidget = const DashboardView();
        viewTitle = 'Dashboard Overview';
        break;
      case 'setup':
        activeViewWidget = const SetupView();
        viewTitle = 'Setup Mock Interview';
        break;
      case 'terminal':
        activeViewWidget = const TerminalView();
        viewTitle = 'Active Terminal';
        break;
      case 'evaluation':
        activeViewWidget = const EvaluationView();
        viewTitle = 'Evaluation Report';
        break;
      case 'profile':
        activeViewWidget = const ProfileView();
        viewTitle = 'Profile & History Ledger';
        break;
      case 'resume_labs':
        activeViewWidget = const ResumeLabsView();
        viewTitle = 'Resume Labs';
        break;
      default:
        activeViewWidget = const DashboardView();
        viewTitle = 'Dashboard';
    }

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(
                viewTitle,
                style: TextStyle(
                  color: state.isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: state.isDarkMode
                  ? const Color(0xFF09090C)
                  : const Color(0xFFF1F5F9),
              elevation: 0,
              iconTheme: IconThemeData(
                color: state.isDarkMode ? Colors.white : Colors.black87,
              ),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: Container(
                color: state.isDarkMode
                    ? const Color(0xFF09090C)
                    : const Color(0xFFF1F5F9),
                child: SafeArea(
                  child: _buildSidebarContent(context, state, notifier),
                ),
              ),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          color: state.isDarkMode
              ? const Color(0xFF09090C)
              : const Color(0xFFF1F5F9),
          gradient: state.isDarkMode
              ? const RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF140D36), // Vibrant deep indigo center glow
                    Color(0xFF04040A), // Extremely dark charcoal space edge
                  ],
                  stops: [0.0, 0.9],
                )
              : null,
        ),
        child: Row(
          children: [
            if (!isMobile)
              // Responsive Left Navigation Sidebar wrapped in glass blur
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    width: sidebarWidth,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        right: BorderSide(
                          color: state.isDarkMode 
                              ? const Color(0xFF2D2D34).withValues(alpha: 0.5) 
                              : const Color(0xFFD2D7DF).withValues(alpha: 0.5), 
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Brand Section
                        Container(
                          padding: isTablet 
                              ? const EdgeInsets.symmetric(vertical: 24, horizontal: 8)
                              : const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                          child: isTablet
                              ? Center(
                                  child: Icon(Icons.terminal, color: Theme.of(context).colorScheme.primary, size: 28),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.terminal, color: Theme.of(context).colorScheme.primary, size: 28),
                                        const SizedBox(width: 8),
                                        Text(
                                          "InterviewerAI",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Elite Prep Coach",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        
                        Divider(height: 1, color: state.isDarkMode ? const Color(0xFF2D2D34) : const Color(0xFFD2D7DF), thickness: 1.5),
                        
                        // Navigation menu items
                        Expanded(
                          child: Material(
                            type: MaterialType.transparency,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              children: [
                                _buildSidebarItem(
                                  context: context,
                                  title: "Dashboard Overview",
                                  icon: Icons.dashboard,
                                  viewKey: 'dashboard',
                                  currentView: state.currentView,
                                  isMobile: isTablet,
                                  onTap: () => notifier.setView('dashboard'),
                                ),
                                _buildSidebarItem(
                                  context: context,
                                  title: "Setup Mock Interview",
                                  icon: Icons.settings_suggest,
                                  viewKey: 'setup',
                                  currentView: state.currentView,
                                  isMobile: isTablet,
                                  onTap: () => notifier.setView('setup'),
                                ),
                                _buildSidebarItem(
                                  context: context,
                                  title: "Active Terminal",
                                  icon: Icons.computer,
                                  viewKey: 'terminal',
                                  currentView: state.currentView,
                                  isDisabled: state.activeInterviewId == null,
                                  isMobile: isTablet,
                                  onTap: () => notifier.setView('terminal'),
                                ),
                                _buildSidebarItem(
                                  context: context,
                                  title: "Resume Labs",
                                  icon: Icons.work,
                                  viewKey: 'resume_labs',
                                  currentView: state.currentView,
                                  isMobile: isTablet,
                                  onTap: () => notifier.setView('resume_labs'),
                                ),
                                _buildSidebarItem(
                                  context: context,
                                  title: "Profile & History Ledger",
                                  icon: Icons.person,
                                  viewKey: 'profile',
                                  currentView: state.currentView,
                                  isMobile: isTablet,
                                  onTap: () => notifier.setView('profile'),
                                ),
                                _buildSidebarItem(
                                  context: context,
                                  title: state.isDarkMode ? "Light Mode" : "Dark Mode",
                                  icon: state.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                                  viewKey: 'theme_toggle',
                                  currentView: '',
                                  isMobile: isTablet,
                                  onTap: () => notifier.toggleTheme(),
                                ),
                                _buildSidebarItem(
                                  context: context,
                                  title: "Sign Out",
                                  icon: Icons.logout,
                                  viewKey: 'logout',
                                  currentView: '',
                                  isMobile: isTablet,
                                  onTap: () => _showSignOutConfirmation(context, state, notifier),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        Divider(height: 1, color: state.isDarkMode ? const Color(0xFF2D2D34) : const Color(0xFFD2D7DF), thickness: 1.5),
  
                        // Bottom Session Status Card
                        Container(
                          padding: isTablet ? const EdgeInsets.all(8) : const EdgeInsets.all(20),
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                          child: isTablet
                              ? Tooltip(
                                  message: state.isDemoMode ? "Demo Mode Active - Client offline sync active" : "Online Mode - AI cloud sync active",
                                  child: Center(
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      child: Icon(state.isDemoMode ? Icons.science_outlined : Icons.cloud_done_outlined, size: 16, color: Colors.white),
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      child: Icon(state.isDemoMode ? Icons.science_outlined : Icons.cloud_done_outlined, size: 16, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            state.isDemoMode ? "Demo Mode Active" : "Online Mode",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            state.isDemoMode ? "Client offline sync active" : "AI cloud sync active",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Main View Panel wrapped in glass blur
            Expanded(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: SafeArea(top: !isMobile, child: activeViewWidget),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String viewKey,
    required String currentView,
    required VoidCallback onTap,
    bool isDisabled = false,
    bool isMobile = false,
  }) {
    final isSelected = currentView == viewKey;

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Tooltip(
          message: title,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDisabled
                    ? Colors.grey.shade400
                     : (isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected
                ? BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 1.5)
                : BorderSide.none,
          ),
          tileColor: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
          leading: Icon(
             icon,
             color: isDisabled
                 ? Colors.grey.shade400
                 : (isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
          ),
          title: Text(
             title,
             style: TextStyle(
               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
               color: isDisabled ? Colors.grey.shade400 : Theme.of(context).colorScheme.onSurface,
             ),
          ),
          enabled: !isDisabled,
          onTap: onTap,
        ),
      ),
    );
  }

  void _showSignOutConfirmation(
    BuildContext context,
    InterviewState state,
    InterviewNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: state.isDarkMode
              ? const Color(0xFF13131A)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: state.isDarkMode
                  ? const Color(0xFF2D2D34).withValues(alpha: 0.5)
                  : const Color(0xFFD2D7DF).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              Text(
                "Sign Out",
                style: TextStyle(
                  color: state.isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            state.isDemoMode
                ? "Are you sure you want to sign out of Demo Mode? Any local mock interview history completed during this session will be lost."
                : "Are you sure you want to sign out of your account?",
            style: TextStyle(
              color: state.isDarkMode
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.black54,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: state.isDarkMode ? Colors.white60 : Colors.black45,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Sign Out"),
            ),
          ],
        );
      },
    );
  }
}
