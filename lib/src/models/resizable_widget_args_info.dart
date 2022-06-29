import 'package:flutter/material.dart';
import 'package:resizable_widget/resizable_widget.dart';

class ResizableWidgetArgsInfo {
  final List<ResizableWidgetChild> children;
  final bool isHorizontalSeparator;
  final bool isDisabledSmartHide;
  final double separatorSize;
  final Color separatorColor;
  final OnResizedFunc? onResized;
  final OnPanStartFunc? onPanStart;
  final OnPanUpdateFunc? onPanUpdate;
  final OnPanEndFunc? onPanEnd;

  ResizableWidgetArgsInfo(ResizableWidget widget)
      : children = widget.children,
        isHorizontalSeparator =
            // ignore: deprecated_member_use_from_same_package
            widget.isHorizontalSeparator || widget.isColumnChildren,
        isDisabledSmartHide = widget.isDisabledSmartHide,
        separatorSize = widget.separatorSize,
        separatorColor = widget.separatorColor,
        onPanStart = widget.onPanStart,
        onPanUpdate = widget.onPanUpdate,
        onPanEnd = widget.onPanEnd,
        onResized = widget.onResized;
}
