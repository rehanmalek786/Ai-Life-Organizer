import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _iconFade;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _scale = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.elasticOut)));
    _iconFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.35, curve: Curves.easeIn)));
    _textFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.85, curve: Curves.easeIn)));
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: widget.next),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.accent],
          ),
        ),
        child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _iconFade.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 10))],
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Opacity(
                  opacity: _textFade.value,
                  child: const Text(
                    'AI Life Organizer',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: _textFade.value,
                  child: Text('Your day, organized.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}
