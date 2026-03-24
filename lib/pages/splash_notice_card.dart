import 'dart:async';
import 'package:flutter/material.dart';

class SplashNoticeCard extends StatefulWidget {
  final String nextRoute;
  const SplashNoticeCard({super.key, this.nextRoute = '/home'});

  @override
  State<SplashNoticeCard> createState() => _SplashNoticeCardState();
}

class _SplashNoticeCardState extends State<SplashNoticeCard>
    with TickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  // <-- deterministic stamp trigger
  bool _showStamp = false;

  @override
  void initState() {
    super.initState();

    // Slow & smooth (≈2.4s)
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    // Title + Card slide/fade together (0..0.82)
    _titleSlide = Tween(begin: const Offset(0, -0.40), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _c,
            curve: const Interval(0.0, 0.82, curve: Curves.easeOutCubic),
          ),
        );
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.82, curve: Curves.easeIn),
      ),
    );

    _cardSlide = Tween(begin: const Offset(0, -0.48), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _cardFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.82, curve: Curves.easeIn),
      ),
    );

    // Stamp ko 1.3s par pop-in karwao (har device par dikhai de)
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() => _showStamp = true);
    });

    // Animation ke baad route switch
    Timer(const Duration(milliseconds: 2550), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(widget.nextRoute);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFFE0F1);
    const lavender = Color(0xFFF6E9FF);
    const titleCol = Color(0xFF6D55A6);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [pink, lavender],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                final cardW = (w * 0.86).clamp(280.0, 520.0);
                final cardH = (h * 0.32).clamp(180.0, 260.0);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title (ALL CAPS)
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'SMART NOTICE BOARD',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: titleCol,
                              shadows: [
                                Shadow(
                                  color: Color(0x33000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Card + stamp
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: _NoticeCard(
                          width: cardW,
                          height: cardH,
                          showStamp: _showStamp, // <- important
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final double width;
  final double height;
  final bool showStamp;

  const _NoticeCard({
    required this.width,
    required this.height,
    required this.showStamp,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _skeleton(width * 0.50),
          const SizedBox(height: 14),
          _skeleton(width * 0.70),
          const SizedBox(height: 14),
          _skeleton(width * 0.58),
          const SizedBox(height: 14),
          _skeleton(width * 0.64),
        ],
      ),
    );

    // DISPLAYED stamp — fade + scale + tilt
    final stamp = AnimatedRotation(
      // Final tilt ≈ -10° (cute angle). Change to -12/ -8 as you like.
      turns: showStamp ? (-10 / 360) : (-18 / 360),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      child: AnimatedScale(
        scale: showStamp ? 1.0 : 0.65,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: showStamp ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 220),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAECB).withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE46491), width: 2),
            ),
            child: const Text(
              'DISPLAYED',
              style: TextStyle(
                color: Color(0xFF6D55A6),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(right: 18, top: 12, child: stamp),
      ],
    );
  }

  Widget _skeleton(double w) {
    return Container(
      width: w,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFE1DBF5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
