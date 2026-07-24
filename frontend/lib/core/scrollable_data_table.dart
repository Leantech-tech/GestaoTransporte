import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ScrollableDataTable extends StatelessWidget {
  final Widget child;
  final int columnCount;
  final Future<void> Function()? onRefresh;

  const ScrollableDataTable({
    super.key,
    required this.child,
    required this.columnCount,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = constraints.maxWidth < (columnCount * 140)
            ? columnCount * 140.0
            : constraints.maxWidth;

        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                width: minWidth,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return content;
  }
}
