import 'dart:async';

import 'package:flutter/material.dart';

import 'models/resizable_widget_args_info.dart';
import 'models/resizable_widget_child_data.dart';
import 'models/resize_args.dart';
import 'resizable_widget_model.dart';

enum ResizeDirection { top, bottom, left, right, none }

class ResizableWidgetController {
  final ResizableWidgetModel _model;
  Stream<Object> get resizeEventStream => _model.resizeEventStream;

  List<ResizableWidgetChildData> get children => _model.children;
  List<Widget> get childrenWidgets => _model.children.map((e) => e.widget).toList();

  ResizableWidgetController(ResizableWidgetArgsInfo info) : _model = ResizableWidgetModel(info) {
    _model.init(this);
  }

  /// 父容器大小发送变化时. 会调用该方法进行重绘
  void setSizeIfNeeded(BoxConstraints constraints) {
    _model.setSizeIfNeeded(constraints);
    _model.callOnResized();
  }

  void resize(ResizeArgs data) {
    if (_model.resize(data)) {
      // print("2222");
      _model.callOnResized();
    } else {
      double? cursorOverflow = _model.cursorOverflowOffset(data);
      if (cursorOverflow != null) {
        // print("333");
        _model.callOnCursorOverflow(data, cursorOverflow);
      }
    }
  }

  void tryHideOrShow(int separatorIndex) {
    final result = _model.tryHideOrShow(separatorIndex);

    if (result) {
      _model.callOnResized();
    }
  }

  bool show(ResizableWidgetChildData target) {
    return _model.show(target);
  }

  bool hide(ResizableWidgetChildData target) {
    return _model.hide(target);
  }

  ResizeDirection determineResizeDirection(Offset offset) {
    return _model.determineResizeDirection(offset);
  }

  List<Widget> rebuildChildren() {
    return _model.rebuildChildren();
  }
}
