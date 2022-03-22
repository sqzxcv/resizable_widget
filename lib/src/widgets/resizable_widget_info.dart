class ResizableWidgetInfo {
  final int index;
  final bool isHorizontal;

  ResizableWidgetInfo({required this.index, required this.isHorizontal});

  ResizableWidgetInfo.clone(ResizableWidgetInfo info)
      : index = info.index,
        isHorizontal = info.isHorizontal;
}
