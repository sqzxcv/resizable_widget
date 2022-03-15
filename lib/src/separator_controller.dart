import 'package:flutter/material.dart';
import 'resizable_widget_controller.dart';
import 'widgets/separator_info.dart';

class SeparatorController {
  final int _index;
  final SeparatorInfo _info;

  const SeparatorController(this._index, this._info);

  bool _canResize(DragUpdateDetails details, BuildContext context) {
    try {
      ResizeDirection direction =
          _info.parentController.determineResizeDirection(details.delta);
      Offset widgetPos =
          (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
      switch (direction) {
        case ResizeDirection.left:
          return details.globalPosition.dx - context.size!.width <=
              widgetPos.dx;
        case ResizeDirection.right:
          return details.globalPosition.dx + context.size!.width >=
              widgetPos.dx;
        case ResizeDirection.top:
          return details.globalPosition.dy - context.size!.height <=
              widgetPos.dy;
        case ResizeDirection.bottom:
          return details.globalPosition.dy + context.size!.height >=
              widgetPos.dy;
        default:
          return true;
      }
    } catch (e) {
      return true;
    }
  }

  void onPanUpdate(DragUpdateDetails details, BuildContext context) {
    if (!_canResize(details, context)) {
      return;
    }
    bool? customResult = _info.onPanUpdate?.call(details, context);

    if (customResult == null || customResult == false) {
      _info.parentController.resize(_index, details.delta);
    }
  }

  void onPanStart(DragStartDetails details, BuildContext context) {
    _info.onPanStart?.call(details, context);
  }

  void onPanEnd(DragEndDetails details, BuildContext context) {
    _info.onPanEnd?.call(details, context);
  }

  void onDoubleTap() {
    _info.parentController.tryHideOrShow(_index);
  }
}
