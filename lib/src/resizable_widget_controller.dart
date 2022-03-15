import 'dart:async';
import 'package:flutter/material.dart';
import 'resizable_widget_args_info.dart';
import 'resizable_widget_child_data.dart';
import 'resizable_widget_model.dart';
import 'separator.dart';
import 'separator_args_info.dart';

enum ResizeDirection { top, bottom, left, right, none }

class ResizableWidgetController {
  final eventStream = StreamController<Object>();
  final ResizableWidgetModel _model;
  List<ResizableWidgetChildData> get children => _model.children;

  ResizableWidgetController(ResizableWidgetArgsInfo info)
      : _model = ResizableWidgetModel(info) {
    _model.init(_separatorFactory);
  }

  void setSizeIfNeeded(BoxConstraints constraints) {
    _model.setSizeIfNeeded(constraints);
    _model.callOnResized();
  }

  void resize(int separatorIndex, Offset offset) {
    _model.resize(separatorIndex, offset);

    eventStream.add(this);
    _model.callOnResized();
  }

  void tryHideOrShow(int separatorIndex) {
    final result = _model.tryHideOrShow(separatorIndex);

    if (result) {
      eventStream.add(this);
      _model.callOnResized();
    }
  }

  ResizeDirection determineResizeDirection(Offset offset) {
    return _model.determineResizeDirection(offset);
  }

  Widget _separatorFactory(SeparatorArgsBasicInfo basicInfo) {
    return Separator(SeparatorArgsInfo(this, basicInfo));
  }
}
