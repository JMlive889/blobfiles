import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Default readable width for form-style and content screens.
abstract final class CenteredScrollMetrics {
  static const double defaultMaxWidth = 480;
}

/// Centers a width-constrained child in the viewport.
///
/// Scrollable mode builds a full-viewport scroll canvas (`minWidth` and
/// `minHeight` match the available space) and positions the inner pane with
/// [alignment]. That lets sparse content sit in the vertical center while
/// tall content still scrolls.
///
/// The inner pane uses `min(viewportWidth, [maxWidth])` so
/// [CrossAxisAlignment.stretch] children expand predictably on every screen
/// size, including inside [SizedBox.expand] + [IndexedStack].
class CenteredScrollView extends StatelessWidget {
  const CenteredScrollView({
    super.key,
    required this.child,
    this.maxWidth = CenteredScrollMetrics.defaultMaxWidth,
    this.padding = const EdgeInsets.all(24),
    this.scrollable = true,
    this.alignment = Alignment.center,
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
        final viewportWidth = _finiteWidth(constraints.maxWidth);
        final viewportHeight = constraints.maxHeight;
        final paneWidth = math.min(viewportWidth, maxWidth);

        final pane = SizedBox(
          width: paneWidth,
          child: Padding(
            padding: padding,
            child: child,
          ),
        );

        if (!scrollable) {
          return _nonScrollableBody(
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight,
            pane: pane,
          );
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: viewportWidth,
              minHeight: _finiteHeight(viewportHeight),
            ),
            child: Align(
              alignment: alignment,
              child: pane,
            ),
          ),
        );
      },
    );
  }

  Widget _nonScrollableBody({
    required double viewportWidth,
    required double viewportHeight,
    required Widget pane,
  }) {
    final aligned = Align(
      alignment: alignment,
      child: pane,
    );

    if (!viewportHeight.isFinite || viewportHeight <= 0) {
      return aligned;
    }

    return SizedBox(
      width: viewportWidth,
      height: viewportHeight,
      child: aligned,
    );
  }

  static double _finiteWidth(double width) {
    if (!width.isFinite || width <= 0) {
      return CenteredScrollMetrics.defaultMaxWidth;
    }
    return width;
  }

  static double _finiteHeight(double height) {
    if (!height.isFinite || height <= 0) {
      return 0;
    }
    return height;
  }
}