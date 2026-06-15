import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Shows a welcome overlay the first time a user opens the app.
/// Call [OnboardingOverlay.show] from initState after checking Hive.
class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingOverlay({super.key, required this.onDone});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  int _page = 0;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  static const _pages = [
    _OPage(
      icon: Icons.biotech,
      color: kNeonTeal,
      title: 'Welcome to OmicVerse',
      body: 'A free, open-source bioinformatics suite with 17+ modules — '
          'from genome annotation to drug interactions, all in your browser.',
    ),
    _OPage(
      icon: Icons.science_outlined,
      color: kNeonBlue,
      title: 'Demo Mode is On',
      body: 'You can explore all modules right now using built-in demo data. '
          'No login required.',
    ),
    _OPage(
      icon: Icons.lock_open_outlined,
      color: kNeonPurple,
      title: 'Go Live with Real Data',
      body: 'Sign up for free to switch on live APIs — Ensembl, gnomAD, '
          'UniProt, STRING, and more — and save your analyses.',
    ),
    _OPage(
      icon: Icons.explore_outlined,
      color: kNeonAmber,
      title: 'Tap Any Module to Begin',
      body: 'Each card on the home screen is a full analysis tool. '
          'Start with Genome, Variant, or Expression — wherever your research takes you.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() async {
    if (_page < _pages.length - 1) {
      await _ctrl.reverse();
      setState(() => _page++);
      _ctrl.forward();
    } else {
      widget.onDone();
    }
  }

  void _skip() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    final isLast = _page == _pages.length - 1;

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: p.color.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: p.color.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.color.withValues(alpha: 0.12),
                        border: Border.all(color: p.color.withValues(alpha: 0.4)),
                      ),
                      child: Icon(p.icon, color: p.color, size: 32),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(p.title,
                        textAlign: TextAlign.center,
                        style: tsTitle(kTextPrimary).copyWith(fontSize: 20)),
                    const SizedBox(height: 12),

                    // Body
                    Text(p.body,
                        textAlign: TextAlign.center,
                        style: tsBody().copyWith(
                            color: kTextSecondary, height: 1.6)),
                    const SizedBox(height: 32),

                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? p.color
                                : kTextMuted.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      children: [
                        if (!isLast) ...[
                          TextButton(
                            onPressed: _skip,
                            child: Text('Skip',
                                style: tsBody().copyWith(color: kTextMuted)),
                          ),
                          const Spacer(),
                        ],
                        Expanded(
                          flex: isLast ? 1 : 0,
                          child: _OnboardBtn(
                            label: isLast ? 'Get Started' : 'Next',
                            color: p.color,
                            onTap: _next,
                          ),
                        ),
                      ],
                    ),

                    // Sign-up prompt on last page
                    if (isLast) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          widget.onDone();
                          // Navigate to login after overlay closes
                          Future.microtask(
                              () => context.go('/login'));
                        },
                        child: RichText(
                          text: TextSpan(
                            style: tsBody().copyWith(fontSize: 13),
                            children: [
                              TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(color: kTextMuted)),
                              TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(
                                      color: kNeonTeal,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OPage {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _OPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _OnboardBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OnboardBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  State<_OnboardBtn> createState() => _OnboardBtnState();
}

class _OnboardBtnState extends State<_OnboardBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hov = true),
          onExit: (_) => setState(() => _hov = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: _hov
                    ? widget.color.withValues(alpha: 0.18)
                    : widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hov ? widget.color : widget.color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: _hov
                    ? [BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 16)]
                    : [],
              ),
              child: Center(
                child: Text(
                  widget.label.toUpperCase(),
                  style: tsBadge().copyWith(
                      color: widget.color, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      );
}
