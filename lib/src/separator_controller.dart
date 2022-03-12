import 'package:flutter/material.dart';
import 'separator_args_info.dart';

class SeparatorController {
  final int _index;
  final SeparatorArgsInfo _info;

  const SeparatorController(this._index, this._info);

  void onPanUpdate(DragUpdateDetails details, BuildContext context) {
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
