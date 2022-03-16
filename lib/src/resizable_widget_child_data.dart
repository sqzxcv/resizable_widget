import 'package:flutter/material.dart';

class ResizableWidgetChildData {
  final Widget widget;
  final int index;
  SizedBox? mountedWidget;
  double? size;
  double? percentage;
  final double? minPercentage;
  final double? maxPercentage;
  double? defaultPercentage;
  double? hidingPercentage;
  bool _needRebuild = true;
  bool get needRebuild => _needRebuild || mountedWidget == null;
  set needRebuild(value) => _needRebuild = value;
  ResizableWidgetChildData(
      {required this.widget,
      required this.percentage,
      required this.index,
      this.minPercentage,
      this.maxPercentage});
}
