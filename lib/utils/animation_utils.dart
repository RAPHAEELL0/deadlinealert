import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deadlinealert/services/haptic_feedback_service.dart';

/// Utility class for animations and microinteractions
class AnimationUtils {
  /// Provides haptic feedback based on the action type
  static void hapticFeedback(HapticFeedbackType type) {
    // Forward the haptic feedback to the dedicated service
    HapticFeedbackService.instance.feedback(type);
  }

  /// Returns the appropriate curve for a given animation type
  static Curve getCurve(AnimationType type) {
    switch (type) {
      case AnimationType.bouncy:
        return Curves.easeOutBack;
      case AnimationType.snappy:
        return Curves.easeOutBack;
      case AnimationType.smooth:
        return Curves.easeOutCubic;
      case AnimationType.slowStart:
        return Curves.easeInOut;
      case AnimationType.slowEnd:
        return Curves.easeOutQuart;
      default:
        return Curves.easeOutCubic;
    }
  }
}

/// Reusable animated container for microinteractions
class AnimatedPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;
  final bool repeat;
  final bool active;

  const AnimatedPulse({
    super.key,
    required this.child,
    this.color = Colors.transparent,
    this.duration = const Duration(milliseconds: 800),
    this.repeat = true,
    this.active = true,
  });

  @override
  State<AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<AnimatedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.repeat && widget.active) {
      _controller.repeat(reverse: true);
    } else if (widget.active) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        if (widget.repeat) {
          _controller.repeat(reverse: true);
        } else {
          _controller.forward();
        }
      } else {
        _controller.stop();
      }
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
        return Transform.scale(
          scale: widget.active ? _animation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Animated error shake widget
class AnimatedShake extends StatefulWidget {
  final Widget child;
  final bool shake;
  final VoidCallback? onAnimationComplete;

  const AnimatedShake({
    super.key,
    required this.child,
    this.shake = false,
    this.onAnimationComplete,
  });

  @override
  State<AnimatedShake> createState() => _AnimatedShakeState();
}

class _AnimatedShakeState extends State<AnimatedShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _animation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        if (widget.onAnimationComplete != null) {
          widget.onAnimationComplete!();
        }
      }
    });

    if (widget.shake) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward();
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
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: widget.child,
        );
      },
    );
  }
}

/// Completion checkmark animation
class AnimatedCheckmark extends StatefulWidget {
  final bool complete;
  final Color color;
  final double size;

  const AnimatedCheckmark({
    super.key,
    required this.complete,
    this.color = Colors.green,
    this.size = 100,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    if (widget.complete) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.complete != oldWidget.complete) {
      if (widget.complete) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: CheckmarkPainter(
            value: _animation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// Custom painter for checkmark drawing
class CheckmarkPainter extends CustomPainter {
  final double value;
  final Color color;

  CheckmarkPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.width / 10;

    final path = Path();

    // First line of the checkmark (bottom to middle)
    if (value < 0.5) {
      final normalizedValue = value * 2; // Scale 0-0.5 to 0-1
      path.moveTo(size.width * 0.2, size.height * 0.5);
      path.lineTo(
        size.width * (0.2 + normalizedValue * 0.2),
        size.height * (0.5 + normalizedValue * 0.2),
      );
    } else {
      path.moveTo(size.width * 0.2, size.height * 0.5);
      path.lineTo(size.width * 0.4, size.height * 0.7);

      // Second line of the checkmark (middle to top)
      final normalizedValue = (value - 0.5) * 2; // Scale 0.5-1 to 0-1
      path.lineTo(
        size.width * (0.4 + normalizedValue * 0.4),
        size.height * (0.7 - normalizedValue * 0.5),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

/// Simple confetti animation widget
class ConfettiEffect extends StatefulWidget {
  final bool active;
  final Widget child;

  const ConfettiEffect({super.key, required this.active, required this.child});

  // Add this method to control confetti programmatically
  void triggerConfetti(BuildContext context) {
    final state = context.findAncestorStateOfType<_ConfettiEffectState>();
    state?.triggerConfetti();
  }

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Confetti> _confetti = [];
  final Random _random = Random();
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _generateConfetti();

    if (widget.active) {
      _showConfetti = true;
      _controller.forward();
    }
  }

  // Add this method to trigger confetti programmatically
  void triggerConfetti() {
    if (mounted) {
      setState(() {
        _showConfetti = true;
        _generateConfetti();
        _controller.reset();
        _controller.forward();
      });

      // Hide the confetti after animation ends
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _showConfetti = false;
          });
        }
      });
    }
  }

  void _generateConfetti() {
    _confetti.clear();
    for (int i = 0; i < 30; i++) {
      _confetti.add(
        Confetti(
          color: Color.fromRGBO(
            _random.nextInt(255),
            _random.nextInt(255),
            _random.nextInt(255),
            0.8,
          ),
          size: 4 + _random.nextDouble() * 4,
          position: Offset(
            _random.nextDouble() * 400,
            -20 - _random.nextDouble() * 80,
          ),
          velocity: Offset(
            -1.5 + _random.nextDouble() * 3,
            1.5 + _random.nextDouble() * 2,
          ),
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: -0.08 + _random.nextDouble() * 0.16,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(ConfettiEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _generateConfetti();
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showConfetti)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: ConfettiPainter(
                  confetti: _confetti,
                  progress: _controller.value,
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Confetti data class
class Confetti {
  final Color color;
  final double size;
  Offset position;
  final Offset velocity;
  double rotation;
  final double rotationSpeed;

  Confetti({
    required this.color,
    required this.size,
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update(double dt) {
    position += velocity * dt * 100;
    rotation += rotationSpeed * dt * 100;
  }
}

/// Custom painter for confetti
class ConfettiPainter extends CustomPainter {
  final List<Confetti> confetti;
  final double progress;

  ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var confetti in this.confetti) {
      // Update confetti position based on animation progress
      confetti.update(progress);

      // Only draw confetti that's within the screen bounds
      if (confetti.position.dy < size.height + 50) {
        final paint = Paint()..color = confetti.color;

        canvas.save();
        canvas.translate(confetti.position.dx, confetti.position.dy);
        canvas.rotate(confetti.rotation);

        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: confetti.size,
            height: confetti.size,
          ),
          paint,
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Types of animations for microinteractions
enum AnimationType { bouncy, snappy, smooth, slowStart, slowEnd }
