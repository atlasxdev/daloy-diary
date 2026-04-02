import 'package:flutter/material.dart';
import 'theme.dart';

/// A curved gradient header that sits behind the top section of a screen.
///
/// Reference: docs/ui/reference/app-theme.webp — the warm pink-to-peach
/// gradient visible at the top of every screen in the design.
class GradientHeader extends StatelessWidget {
  final double height;
  const GradientHeader({super.key, this.height = 220});

  @override
  Widget build(BuildContext context) {
    final baseGradient = AppTheme.getHeaderGradient(context);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.45, 0.75, 1.0],
          colors: [
            baseGradient.colors.first,
            baseGradient.colors.last,
            baseGradient.colors.last.withValues(alpha: 0.3),
            scaffoldBg,
          ],
        ),
      ),
    );
  }
}

/// Wraps a screen body so the gradient sits behind the top portion.
/// The [child] is layered on top of the gradient using a Stack.
class GradientScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final double gradientHeight;
  final List<Widget>? actions;

  const GradientScaffold({
    super.key,
    required this.title,
    required this.child,
    this.gradientHeight = 220,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GradientHeader(height: gradientHeight),
          SafeArea(
            child: Column(
              children: [
                // Title bar.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
                // Content.
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
