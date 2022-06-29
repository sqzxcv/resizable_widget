import 'package:flutter/material.dart';
import 'package:resizable_widget/src/widgets/resizable_widget_child.dart';

class ResizableWidgetChildData {
  final ResizableWidgetChild widget;
  double? percentage;
  final int index;
  bool visible;
  double? minPercentage;
  double? maxPercentage;
  final double? cursorOverflowPercentageForHidding;
  final double? _cursorOverflowPercentageForShowing;
  final bool hideSeparatorOnWidgetHide;

  SizedBox? mountedWidget;
  double? size;
  double? defaultPercentage;
  double? hidingPercentage;
  bool _needRebuild = true;
  bool get isNotVisible => !visible;

  double? get cursorOverflowPercentageForShowing {
    if (_cursorOverflowPercentageForShowing != null) {
      return _cursorOverflowPercentageForShowing;
    } else {
      if (cursorOverflowPercentageForHidding == null) {
        return null;
      } else {
        return (1 - cursorOverflowPercentageForHidding!) + 0.1;
      }
    }
  }

  bool get needRebuild => _needRebuild || mountedWidget == null;
  set needRebuild(value) => _needRebuild = value;
  ResizableWidgetChildData({
    required this.widget,
    required this.percentage,
    required this.index,
    this.visible = true,
    this.minPercentage,
    this.maxPercentage,
    this.cursorOverflowPercentageForHidding,
    this.hideSeparatorOnWidgetHide = false,
    double? cursorOverflowPercentageForShowing,
  }) : _cursorOverflowPercentageForShowing = cursorOverflowPercentageForShowing;
}
