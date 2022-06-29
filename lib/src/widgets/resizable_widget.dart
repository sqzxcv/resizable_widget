import 'package:flutter/material.dart';
import 'package:resizable_widget/src/models/resizable_widget_args_info.dart';
import 'package:resizable_widget/src/resizable_widget_controller.dart';
import 'package:resizable_widget/src/models/widget_size_info.dart';

import 'resizable_widget_child.dart';

/// The callback argument type of [ResizableWidget.onResized].
typedef OnResizedFunc = void Function(List<WidgetSizeInfo> infoList);

/// The callback Separator onPanStart event. If result of function is true, it will stop logic and will not run default reactions.
typedef OnPanStartFunc = bool Function(
    DragStartDetails details, BuildContext context);

/// The callback Separator onPanUpdate event. If result of function is true, it will stop logic and will not run default reactions.
typedef OnPanUpdateFunc = bool Function(
    DragUpdateDetails details, BuildContext context);

/// The callback Separator onPanEnd event. If result of function is true, it will stop logic and will not run default reactions.
typedef OnPanEndFunc = bool Function(
    DragEndDetails details, BuildContext context);

/// Holds resizable widgets as children.
/// Users can resize the internal widgets by dragging.
class ResizableWidget extends StatefulWidget {
  /// Resizable widget list.
  final List<ResizableWidgetChild> children;

  /// Sets the default [children] width or height as percentages.
  ///
  /// If you set this value,
  /// the length of [percentages] must match the one of [children],
  /// and the sum of [percentages] must be equal to 1.
  ///
  /// If this value is [null], [children] will be split into the same size.
  final List<double>? percentages;

  /// When set to true, creates horizontal separators.
  @Deprecated('Use [isHorizontalSeparator] instead')
  final bool isColumnChildren;

  /// When set to true, creates horizontal separators.
  final bool isHorizontalSeparator;

  /// When set to true, Smart-Hide-Function is disabled.
  ///
  /// Smart-Hide-Function is that users can hide / show the both ends widgets
  /// by double-clicking the separators.
  final bool isDisabledSmartHide;

  /// Separator size.
  final double separatorSize;

  /// Separator color.
  final Color separatorColor;

  /// Callback of the resizing event.
  /// You can get the size and percentage of the internal widgets.
  ///
  /// Note that [onResized] is called every frame when resizing [children].
  final OnResizedFunc? onResized;

  /// The callback Separator onPanStart event.
  /// If result of function is true, it will stop logic and will not run default reactions.
  final OnPanStartFunc? onPanStart;

  /// The callback Separator onPanUpdate event.
  /// If result of function is true, it will stop logic and will not run default reactions.
  final OnPanUpdateFunc? onPanUpdate;

  /// The callback Separator onPanEnd event.
  /// If result of function is true, it will stop logic and will not run default reactions.
  final OnPanEndFunc? onPanEnd;

  /// Creates [ResizableWidget].
  ResizableWidget(
      {Key? key,
      required this.children,
      this.percentages,
      @Deprecated('Use [isHorizontalSeparator] instead')
          this.isColumnChildren = false,
      this.isHorizontalSeparator = false,
      this.isDisabledSmartHide = false,
      this.separatorSize = 4,
      this.separatorColor = Colors.white12,
      this.onResized,
      this.onPanStart,
      this.onPanUpdate,
      this.onPanEnd})
      : super(key: key) {
    assert(children.isNotEmpty);
    assert(percentages == null || percentages!.length == children.length);
    assert(percentages == null ||
        percentages!.reduce((value, element) => value + element) == 1);
  }

  @override
  _ResizableWidgetState createState() => _ResizableWidgetState();
}

class _ResizableWidgetState extends State<ResizableWidget> {
  late ResizableWidgetArgsInfo _info;
  late ResizableWidgetController _controller;

  @override
  void initState() {
    super.initState();

    _info = ResizableWidgetArgsInfo(widget);
    _controller = ResizableWidgetController(_info);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          _controller.setSizeIfNeeded(constraints);
          return StreamBuilder(
              stream: _controller.resizeEventStream,
              builder: (context, snapshot) {
                return _info.isHorizontalSeparator
                    ? Column(children: _controller.rebuildChildren())
                    : Row(children: _controller.rebuildChildren());
              });
        },
      );
}
