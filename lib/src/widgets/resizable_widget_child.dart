import 'dart:async';

import 'package:flutter/material.dart';

enum ResizableWidgetChildAction {
  show,
  hide,
  toogleVisible,
  afterShow,
  afterHide
}

class ResizableWidgetChild extends StatelessWidget {
  final double? percentage;
  final double? minPercentage;
  final double? maxPercentage;
  final Widget child;
  final bool visible;
  final double? cursorOverflowPercentageForHidding;
  final double? cursorOverflowPercentageForShowing;
  final StreamController<ResizableWidgetChildAction>? actionStream;
  final bool hideSeparatorOnWidgetHide;
  const ResizableWidgetChild({
    required this.child,
    this.percentage,
    this.minPercentage,
    this.maxPercentage,
    this.visible = true,
    this.cursorOverflowPercentageForHidding,
    this.cursorOverflowPercentageForShowing,
    this.actionStream,
    this.hideSeparatorOnWidgetHide = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
