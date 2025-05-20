import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/services/haptic_feedback_service.dart';
import 'dart:math' as math;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _animationComplete = false;
  bool _checkingAuth = true;
  String _statusMessage = "Initializing app...";
  bool _showLogo = false;
  bool _showText = false;
  bool _showBackground = false;
  bool _makeClockAnimation = false;

  late AnimationController _clockController;

  @override
  void initState() {
    super.initState();

    // Initialize clock animation controller with repeat for GIF-like animation
    _clockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(); // Make the animation repeat like a GIF

    // Provide haptic feedback with shorter delay
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedbackService.instance.feedback(HapticFeedbackType.medium);
    });

    // Show background immediately for smoother startup
    setState(() {
      _showBackground = true;
    });

    // Show logo with slight delay - reduced from 400ms to 250ms
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _showLogo = true;
        });

        // Begin clock animation with shorter delay - reduced from 600ms to 350ms
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            setState(() {
              _makeClockAnimation = true;
              // _clockController.forward(); -- Removed as we're using repeat instead
            });
          }
        });
      }
    });

    // Show text after logo animation - reduced from 1000ms to 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showText = true;
        });
      }
    });

    // Begin auth check after animations start
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _clockController.dispose();
    super.dispose();
  }

  void _checkAuthStatus() async {
    try {
      setState(() {
        _statusMessage = 'Checking login status...';
      });

      // Initial auth check - retrieve current state
      final authState = ref.read(authProvider);

      // If we already have a state, process it
      if (authState.status == AuthStatus.authenticated) {
        setState(() {
          _animationComplete = true;
          _checkingAuth = false;
          _statusMessage = 'Logged in!';
        });

        // Navigate to home screen after animation completes - increased from 500ms to 2500ms
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            context.go('/home');
          }
        });
      } else if (authState.status == AuthStatus.unauthenticated) {
        setState(() {
          _animationComplete = true;
          _checkingAuth = false;
          _statusMessage = 'Please log in';
        });

        // Navigate to login screen after animation completes - increased from 500ms to 2500ms
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _animationComplete = true;
          _checkingAuth = false;
          _statusMessage = 'Error: ${e.toString()}';
        });

        // If error, navigate to login after delay - increased from 1000ms to 2500ms
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    }
  }

  void _handleAuthStateChange(AuthState authState) {
    if (authState.status == AuthStatus.authenticated) {
      setState(() {
        _animationComplete = true;
        _checkingAuth = false;
        _statusMessage = 'Logged in!';
      });

      // Navigate to home screen after animation completes - increased from 500ms to 2500ms
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          context.go('/home');
        }
      });
    } else if (authState.status == AuthStatus.unauthenticated) {
      setState(() {
        _animationComplete = true;
        _checkingAuth = false;
        _statusMessage = 'Please log in';
      });

      // Navigate to login screen after animation completes - increased from 500ms to 2500ms
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          context.go('/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes in the build method
    ref.listen(authProvider, (previous, current) {
      _handleAuthStateChange(current);
    });

    return Scaffold(
      body: Stack(
        children: [
          // Animated background - faster fade-in
          AnimatedOpacity(
            opacity: _showBackground ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400), // Reduced from 800ms
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF8B0000), const Color(0xFF5B0000)],
                ),
              ),
            ),
          ),

          // Animated clock hand particles
          if (_makeClockAnimation)
            AnimatedBuilder(
              animation: _clockController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ClockParticlePainter(
                    progress: _clockController.value,
                    color: Colors.white,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo - faster animations with pulsating effect
                  AnimatedOpacity(
                    opacity: _showLogo ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child:
                        _showLogo
                            ? Container(
                                  height: 120,
                                  width: 120,
                                  padding: const EdgeInsets.all(16),
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
                                  child: Hero(
                                    tag: 'app_logo',
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.05, 1.05),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeInOut,
                                )
                            : Container(),
                  ),

                  const SizedBox(height: 40),

                  // App name - faster animation
                  AnimatedOpacity(
                    opacity: _showText ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: const Text(
                      'Deadline Alert',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Status text - faster animation
                  AnimatedOpacity(
                    opacity: _showText ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                            _statusMessage,
                            key: ValueKey(_statusMessage),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .fadeIn(duration: 400.ms)
                          .then()
                          .fadeOut(delay: 1800.ms, duration: 300.ms),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Loading indicator - faster animation with continuous loop
                  if (_checkingAuth) LoadingIndicator(isLoading: _checkingAuth),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final bool isLoading;

  const LoadingIndicator({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleY(
                begin: 0.5,
                end: 1.0,
                delay: Duration(milliseconds: index * 100),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              ),
        ),
      ),
    );
  }
}

class ClockParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount = 40;

  ClockParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;

    // Calculate the angle based on progress
    final angle = 2 * math.pi * progress;

    // Paint for the particles
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Paint for the clock hands
    final handPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw particles - reduced the movement speed by decreasing the multiplier
    for (int i = 0; i < particleCount; i++) {
      final particleAngle = (i / particleCount) * 2 * math.pi;
      final distance =
          radius *
          (0.8 +
              0.15 *
                  math.sin(
                    particleAngle * 3 +
                        progress * 6, // Reduced from 5 and 10 to 3 and 6
                  ));
      final particleProgress = math.min(
        1.0,
        math.max(
          0.0,
          progress * 2.0, // Reduced from 2.5 to slow down particle appearance
        ),
      );

      final particleSize = 3.0 * particleProgress;

      if (particleProgress > 0) {
        final particlePos = Offset(
          center.dx + distance * math.cos(particleAngle),
          center.dy + distance * math.sin(particleAngle),
        );

        canvas.drawCircle(particlePos, particleSize, paint);
      }
    }

    // Always draw all clock hands now that we're looping
    // Draw hour hand
    final hourHandLength = radius * 0.5;
    final hourHandEnd = Offset(
      center.dx + hourHandLength * math.cos(-math.pi / 2 + angle / 12),
      center.dy + hourHandLength * math.sin(-math.pi / 2 + angle / 12),
    );

    canvas.drawLine(center, hourHandEnd, handPaint..strokeWidth = 4.0);

    // Draw minute hand
    final minuteHandLength = radius * 0.7;
    final minuteHandEnd = Offset(
      center.dx + minuteHandLength * math.cos(-math.pi / 2 + angle),
      center.dy + minuteHandLength * math.sin(-math.pi / 2 + angle),
    );

    canvas.drawLine(center, minuteHandEnd, handPaint..strokeWidth = 3.0);

    // Draw second hand
    final secondHandLength = radius * 0.8;
    final secondHandEnd = Offset(
      center.dx +
          secondHandLength *
              math.cos(
                -math.pi / 2 + angle * 6,
              ), // Reduced from 12 to 6 to slow down second hand
      center.dy +
          secondHandLength *
              math.sin(-math.pi / 2 + angle * 6), // Reduced from 12 to 6
    );

    canvas.drawLine(center, secondHandEnd, handPaint..strokeWidth = 1.5);

    // Draw center dot
    canvas.drawCircle(center, 5, paint);
  }

  @override
  bool shouldRepaint(ClockParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
