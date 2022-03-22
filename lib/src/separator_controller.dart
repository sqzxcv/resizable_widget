import 'package:flutter/material.dart';
import 'models/resize_args.dart';
import 'widgets/separator_info.dart';

class SeparatorController {
  final int _index;
  final SeparatorInfo _info;

  const SeparatorController(this._index, this._info);

  void onPanUpdate(DragUpdateDetails details, BuildContext context) {
    bool? customResult = _info.onPanUpdate?.call(details, context);

    if (customResult == null || customResult == false) {
      _info.parentController.resize(ResizeArgs(
          separatorIndex: _index,
          offset: details.delta,
          cursorPosition: details.globalPosition,
          separatorPosition: (context.findRenderObject() as RenderBox)
              .localToGlobal(Offset.zero)));
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
