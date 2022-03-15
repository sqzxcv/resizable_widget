import 'dart:async';

import 'package:resizable_widget/src/widget_size_info.dart';

class ResizableWidgetInfo {
  final int index;
  final bool isHorizontal;
  final StreamController<WidgetSizeInfo> resizeEventStream =
      StreamController<WidgetSizeInfo>();

  ResizableWidgetInfo({required this.index, required this.isHorizontal});

  ResizableWidgetInfo.clone(ResizableWidgetInfo info)
      : index = info.index,
        isHorizontal = info.isHorizontal;
}
