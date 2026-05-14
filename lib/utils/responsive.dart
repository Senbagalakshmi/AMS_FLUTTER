import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ─── AMS RESPONSIVE UTILITY ─────────────────────────────────
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Checks if the screen width is considered Mobile (< 650)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  /// Checks if the screen width is considered Tablet (650 <= width < 1024)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1024;

  /// Checks if the screen width is considered Desktop (>= 1024)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  /// Helper to quickly get the screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Helper to get a responsive value based on device type
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final width = screenWidth(context);
    if (width >= 1024) return desktop;
    if (width >= 650 && tablet != null) return tablet;
    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktop;
        } else if (constraints.maxWidth >= 650 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

// ─── FLEX ADAPTER ─────────────────────────────────────────────
/// Highly useful wrapper that turns dynamic Rows into Columns on mobile
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final double runSpacing;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16.0,
    this.runSpacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.map((child) {
          final isLast = children.indexOf(child) == children.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : runSpacing),
            child: child,
          );
        }).toList(),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map((child) {
        final isLast = children.indexOf(child) == children.length - 1;
        return Expanded(
          flex: child is Expanded ? 1 : 0, // Keep expands but don't break wrap behavior
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : spacing),
            child: child,
          ),
        );
      }).toList(),
    );
  }
}
