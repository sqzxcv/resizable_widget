import 'package:flutter/widgets.dart';

class ResizeArgs {
  final int separatorIndex;
  final Offset offset;
  final Offset? cursorPosition;
  final Offset? separatorPosition;

  ResizeArgs(
      {required this.separatorIndex,
      required this.offset,
      this.cursorPosition,
      this.separatorPosition});
}
