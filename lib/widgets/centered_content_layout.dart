import 'package:flutter/material.dart';

/// Shared content width for form-style screens (login, library, profile, etc.).
abstract final class ContentLayout {
  static const double formMaxWidth = 480;
}

/// Horizontally centers page content and enforces a readable max width.
///
/// Sets [BoxConstraints.minWidth] so [CrossAxisAlignment.stretch] children
/// expand correctly inside a [SingleChildScrollView]. Without [minWidth], wide
/// viewports can collapse content into a narrow strip on the left.
class CenteredContentLayout extends StatelessWidget {
  const CenteredContentLayout({
    super.key,
    required this.child,
    this.maxWidth = ContentLayout.formMaxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    this.scrollable = true,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _contentWidth(constraints.maxWidth, maxWidth);

        final content = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            minWidth: width,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        );

        final body = scrollable
            ? SingleChildScrollView(child: content)
            : content;

        return Align(
          alignment: alignment,
          child: body,
        );
      },
    );
  }

  static double _contentWidth(double viewportWidth, double maxWidth) {
    if (!viewportWidth.isFinite || viewportWidth <= 0) {
      return maxWidth;
    }
    return viewportWidth < maxWidth ? viewportWidth : maxWidth;
  }
}