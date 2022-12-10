import 'dart:async';

import 'package:flutter/material.dart';

enum ResizableWidgetChildAction { show, hide, toogleVisible, afterShow, afterHide }

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

  /// [fixSize] 如果设置固定大小后, 当窗口大小发生变化时,该widget会保持这个size不变(除非空间不够)
  /// 如果设置了该属性 那么percentage 会被忽略
  double? fixSize;
  ResizableWidgetChild({
    required this.child,
    this.percentage,
    this.minPercentage,
    this.maxPercentage,
    this.visible = true,
    this.cursorOverflowPercentageForHidding,
    this.cursorOverflowPercentageForShowing,
    this.actionStream,
    this.hideSeparatorOnWidgetHide = false,
    this.fixSize,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
