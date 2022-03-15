import 'package:flutter/material.dart';
import 'package:resizable_widget/resizable_widget.dart';
import 'package:resizable_widget/src/resizable_widget_controller.dart';

class SeparatorInfo {
  final bool isDisabledSmartHide;
  final ResizableWidgetController parentController;
  final int index;
  final bool isHorizontal;
  final double size;
  final Color color;
  final OnPanStartFunc? onPanStart;
  final OnPanUpdateFunc? onPanUpdate;
  final OnPanEndFunc? onPanEnd;

  SeparatorInfo(
      {required this.index,
      required this.isHorizontal,
      required this.isDisabledSmartHide,
      required this.size,
      required this.color,
      required this.parentController,
      this.onPanStart,
      this.onPanUpdate,
      this.onPanEnd});
}
