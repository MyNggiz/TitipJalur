import 'package:flutter/material.dart';

/// Membatasi lebar konten maksimal pada layar lebar (tablet/desktop/web)
/// agar tampilan tetap rapi, berada di tengah, dan tidak tertekan atau melar.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 650.0,
    this.padding,
  });

  /// Helper factory untuk membungkus konten scrollable di dalam SingleChildScrollView
  /// yang secara otomatis dibatasi oleh ResponsiveContainer.
  static Widget scrollable({
    Key? key,
    required Widget child,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    double maxWidth = 650.0,
    ScrollController? controller,
    bool primary = false,
  }) {
    return SingleChildScrollView(
      key: key,
      physics: physics,
      controller: controller,
      primary: primary,
      child: ResponsiveContainer(
        maxWidth: maxWidth,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: content,
      ),
    );
  }
}
