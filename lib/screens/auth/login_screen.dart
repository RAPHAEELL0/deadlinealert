import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/services/haptic_feedback_service.dart';
import 'dart:math';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isErrorShaking = false;

  // Animation controllers
  late AnimationController _backgroundAnimationController;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    // Start background animation loop
    _backgroundAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedbackService.instance.feedback(HapticFeedbackType.error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAuthenticating = true;
    });

    HapticFeedbackService.instance.feedback(HapticFeedbackType.medium);

    try {
      // Trim the email and remove any extra spaces
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await ref
          .read(authProvider.notifier)
          .signIn(email: email, password: password);

      if (mounted) {
        final authState = ref.read(authProvider);

        if (authState.status == AuthStatus.authenticated) {
          HapticFeedbackService.instance.feedback(HapticFeedbackType.success);
          context.go('/home');
        } else if (authState.errorMessage != null) {
          setState(() {
            _errorMessage = authState.errorMessage;
            _isErrorShaking = true;
            _isAuthenticating = false;
          });
          HapticFeedbackService.instance.feedback(HapticFeedbackType.error);

          // Reset shaking state after animation
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isErrorShaking = false;
              });
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _isErrorShaking = true;
          _isAuthenticating = false;
        });
        HapticFeedbackService.instance.feedback(HapticFeedbackType.error);

        // Reset shaking state after animation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isErrorShaking = false;
            });
          }
        });
      }
    } finally {
      if (mounted && !_isAuthenticating) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _continueAsGuest() {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    HapticFeedbackService.instance.feedback(HapticFeedbackType.medium);

    // Add a slight delay for visual feedback
    Future.delayed(const Duration(milliseconds: 300), () {
      // Navigate to home screen
      context.go('/home');

      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Prevent going back after logging out using the system back button
      canPop: false,
      onPopInvoked: (didPop) {
        // If already popped, we can't do anything
        if (didPop) return;

        final authState = ref.read(authProvider);
        if (authState.isAuthenticated || authState.isGuestMode) {
          // Only allow going back if authenticated or guest
          Navigator.of(context).maybePop();
        }
        // Otherwise don't pop (stay on login screen)
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _backgroundAnimationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8B0000),
                    const Color(0xFF6B0000),
                    const Color(0xFF5B0000),
                  ],
                  stops: [
                    0,
                    0.5 + (_backgroundAnimationController.value * 0.2),
                    1,
                  ],
                  transform: GradientRotation(
                    _backgroundAnimationController.value * 0.8,
                  ),
                ),
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and app name with enhanced animations
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.0, 1.0),
                              duration: 700.ms,
                              curve: Curves.easeOutBack,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                            'Deadline Alert',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(
                            begin: 0.3,
                            end: 0,
                            delay: 300.ms,
                            duration: 800.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 12),
                      Text(
                        'Never miss an important deadline again',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                      const SizedBox(height: 48),

                      // Error message with enhanced shake animation
                      if (_errorMessage != null)
                        ShakeWidget(
                              shake: _isErrorShaking,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade800.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade300.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade300,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade300,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 200.ms)
                            .slideY(begin: -0.1, end: 0, duration: 200.ms),

                      // Email field with enhanced animations
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                      const SizedBox(height: 8),
                      TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              hintStyle: const TextStyle(color: Colors.white60),
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Colors.white70,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white30,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              fillColor: Colors.white.withOpacity(0.1),
                              filled: true,
                            ),
                            onTap: () {
                              HapticFeedbackService.instance.feedback(
                                HapticFeedbackType.light,
                              );
                            },
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 400.ms)
                          .slideX(
                            begin: 0.1,
                            end: 0,
                            delay: 250.ms,
                            duration: 400.ms,
                          ),
                      const SizedBox(height: 24),

                      // Password field with enhanced animations
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
                      const SizedBox(height: 8),
                      TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: const TextStyle(color: Colors.white60),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.white70,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white30,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              fillColor: Colors.white.withOpacity(0.1),
                              filled: true,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                  HapticFeedbackService.instance.feedback(
                                    HapticFeedbackType.light,
                                  );
                                },
                              ),
                            ),
                            onTap: () {
                              HapticFeedbackService.instance.feedback(
                                HapticFeedbackType.light,
                              );
                            },
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(delay: 450.ms, duration: 400.ms)
                          .slideX(
                            begin: 0.1,
                            end: 0,
                            delay: 450.ms,
                            duration: 400.ms,
                          ),
                      const SizedBox(height: 32),

                      // Login button with enhanced animations
                      AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF8B0000),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: Colors.white
                                    .withOpacity(0.7),
                              ),
                              child:
                                  _isLoading
                                      ? _isAuthenticating
                                          ? _buildLoadingAnimation()
                                          : const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF8B0000),
                                            ),
                                          )
                                      : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 550.ms, duration: 400.ms)
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.0, 1.0),
                            delay: 550.ms,
                            duration: 400.ms,
                          ),
                      const SizedBox(height: 16),

                      // Sign up link with enhanced animations
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.white70),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedbackService.instance.feedback(
                                  HapticFeedbackType.light,
                                );
                                context.go('/signup');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Animated loading widget
  Widget _buildLoadingAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleY(
                begin: 0.4,
                end: 1.0,
                duration: 600.ms,
                delay: Duration(milliseconds: i * 200),
                curve: Curves.easeInOut,
              ),
      ],
    );
  }
}

// Add this shake animation class
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  final VoidCallback? onShakeComplete;
  final double shakeOffset;
  final Duration shakeDuration;

  const ShakeWidget({
    super.key,
    required this.child,
    this.shake = false,
    this.onShakeComplete,
    this.shakeOffset = 10.0,
    this.shakeDuration = const Duration(milliseconds: 500),
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.shakeDuration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    if (widget.shake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final sineValue = sin(4 * pi * _animation.value);
        return Transform.translate(
          offset: Offset(sineValue * widget.shakeOffset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
