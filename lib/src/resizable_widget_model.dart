import 'package:flutter/material.dart';
import 'resizable_widget_args_info.dart';
import 'resizable_widget_child_data.dart';
import 'resizable_widget_controller.dart';
import 'widget_child_builder.dart';
import 'widget_children_resizer.dart';
import 'widget_size_info.dart';
import 'widgets/separator.dart';

class ResizableWidgetModel {
  final ResizableWidgetArgsInfo _info;
  late final WidgetChildrenResizer resizer;
  List<ResizableWidgetChildData> get children => resizer.children;

  ResizableWidgetModel(this._info);

  void init(ResizableWidgetController controller) {
    resizer = WidgetChildrenResizer(
        WidgetChildBuilder(_info, controller).build(), _info);
  }

  void setSizeIfNeeded(BoxConstraints constraints) {
    resizer.setSizeIfNeeded(constraints);
  }

  ResizeDirection determineResizeDirection(Offset offset) {
    return resizer.determineResizeDirection(offset);
  }

  void resize(int separatorIndex, Offset offset) {
    resizer.resize(separatorIndex, offset);
  }

  void callOnResized() {
    _info.onResized?.call(children
        .where((x) => x.widget is! Separator)
        .map((x) => WidgetSizeInfo(size: x.size!, percentage: x.percentage!))
        .toList());
  }

  bool tryHideOrShow(int separatorIndex) {
    return resizer.tryHideOrShow(separatorIndex);
  }

  List<Widget> rebuildChildren() {
    return children.map((child) {
      if (child.needRebuild) {
        child.mountedWidget = SizedBox(
          width: _info.isHorizontalSeparator ? double.infinity : child.size,
          height: _info.isHorizontalSeparator ? child.size : double.infinity,
          child: child.widget,
        );
        child.needRebuild = false;
      }

      return child.mountedWidget!;
    }).toList();
  }
}
