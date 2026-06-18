import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/interview_provider.dart';
import '../theme.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    final notifier = ref.read(interviewProvider.notifier);
    bool success;

    if (_isSignUpMode) {
      success = await notifier.signUp(email, password);
      if (success) {
        // Automatically write full name metadata if supabase synchronizes it
        // Supabase trigger automatically picks up raw metadata
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please sign in.')),
        );
        setState(() {
          _isSignUpMode = false;
        });
      }
    } else {
      success = await notifier.login(email, password);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome back!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: state.isDarkMode ? const Color(0xFF09090C) : const Color(0xFFF1F5F9),
          gradient: state.isDarkMode
              ? const RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Color(0xFF2E1065), // Radial purple light in the middle
                    Color(0xFF060608), // Dark space edge
                  ],
                  stops: [0.0, 0.85],
                )
              : null,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    decoration: BoxDecoration(
                      color: AppTheme.panelBg,
                      border: Border.all(
                        color: state.isDarkMode
                            ? const Color(0xFF2D2D34).withValues(alpha: 0.5)
                            : const Color(0xFFD2D7DF).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App Branding
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.terminal,
                                color: AppTheme.accentHighlight,
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "InterviewerAI",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignUpMode
                                ? "Create your elite prep account"
                                : "Sign in to access your dashboard",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textDark.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Full Name (Sign Up only)
                          if (_isSignUpMode) ...[
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: AppTheme.textDark),
                              decoration: const InputDecoration(
                                labelText: "Full Name",
                                hintText: "Alex Mercer",
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Email
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: AppTheme.textDark),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Email Address",
                              hintText: "developer@example.com",
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            style: TextStyle(color: AppTheme.textDark),
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                              hintText: "••••••••",
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Dynamic error message alert
                          if (state.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      state.errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Submit Button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: state.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentHighlight,
                              ),
                              child: state.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(_isSignUpMode ? "Create Account" : "Sign In"),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign In / Sign Up toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUpMode
                                    ? "Already have an account?"
                                    : "Don't have an account?",
                                style: TextStyle(
                                  color: AppTheme.textDark.withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUpMode = !_isSignUpMode;
                                    ref.read(interviewProvider.notifier).setView('dashboard'); // clear errors
                                  });
                                },
                                child: Text(
                                  _isSignUpMode ? "Sign In" : "Sign Up",
                                  style: TextStyle(
                                    color: AppTheme.accentHighlight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
