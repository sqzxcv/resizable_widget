import 'package:flutter/material.dart';

class ResizableWidgetChild extends StatelessWidget {
  final double? percentage;
  final double? minPercentage;
  final double? maxPercentage;
  final Widget child;

  const ResizableWidgetChild({
    required this.child,
    this.percentage,
    this.minPercentage,
    this.maxPercentage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
