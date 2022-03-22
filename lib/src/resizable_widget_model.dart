import 'dart:async';

import 'package:flutter/material.dart';
import 'models/resizable_widget_args_info.dart';
import 'models/resizable_widget_child_data.dart';
import 'models/resize_args.dart';
import 'resizable_widget_controller.dart';
import 'widget_child_builder.dart';
import 'widget_children_resizer.dart';
import 'models/widget_size_info.dart';
import 'widgets/separator.dart';

class ResizableWidgetModel {
  final ResizableWidgetArgsInfo _info;
  late final WidgetChildrenResizer _resizer;
  final StreamController<Object> _eventStream = StreamController<Object>();
  Stream<Object> get resizeEventStream => _eventStream.stream;
  List<ResizableWidgetChildData> get children => _resizer.children;

  ResizableWidgetModel(this._info);

  void init(ResizableWidgetController controller) {
    _resizer = WidgetChildrenResizer(
        WidgetChildBuilder(_info, controller).build(), _info, _eventStream);
  }

  void setSizeIfNeeded(BoxConstraints constraints) {
    _resizer.setSizeIfNeeded(constraints);
  }

  ResizeDirection determineResizeDirection(Offset offset) {
    return _resizer.determineResizeDirection(offset);
  }

  bool resize(ResizeArgs data) {
    if (!_resizer.separatorIsValidForResize(data) ||
        !_resizer.blocksCanChangeTheirSize(data)) {
      return false;
    }
    _resizer.resize(data);
    return true;
  }

  void callOnResized() {
    _info.onResized?.call(children
        .where((x) => x.widget is! Separator)
        .map((x) => WidgetSizeInfo(size: x.size!, percentage: x.percentage!))
        .toList());
  }

  bool tryHideOrShow(int separatorIndex) {
    return _resizer.tryHideOrShow(separatorIndex);
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

  double? cursorOverflowOffset(ResizeArgs data) {
    if (data.separatorPosition == null || data.cursorPosition == null) {
      return null;
    }
    try {
      ResizeDirection direction =
          _resizer.determineResizeDirection(data.offset);
      double cursorOverflowOffset = 0;
      switch (direction) {
        case ResizeDirection.left:
          cursorOverflowOffset = data.cursorPosition!.dx -
              (data.separatorPosition!.dx - _info.separatorSize);
          break;
        case ResizeDirection.right:
          cursorOverflowOffset = data.cursorPosition!.dx -
              (data.separatorPosition!.dx + _info.separatorSize);
          break;
        case ResizeDirection.top:
          cursorOverflowOffset = data.cursorPosition!.dy -
              (data.separatorPosition!.dy - _info.separatorSize);
          break;
        case ResizeDirection.bottom:
          cursorOverflowOffset = data.cursorPosition!.dy -
              (data.separatorPosition!.dy + _info.separatorSize);
          break;
        default:
          return null;
      }
      return cursorOverflowOffset;
    } catch (e) {
      return null;
    }
  }

  void callOnCursorOverflow(ResizeArgs data, double offset) {
    if (offset == 0) {
      return;
    }
    ResizableWidgetChildData increaseBlock;
    ResizableWidgetChildData decreaseBlock;
    if (offset > 0) {
      // direction right or bottom
      increaseBlock = children[data.separatorIndex - 1];
      decreaseBlock = children[data.separatorIndex + 1];
    } else {
      // direction left or top
      increaseBlock = children[data.separatorIndex + 1];
      decreaseBlock = children[data.separatorIndex - 1];
    }
    if (decreaseBlock.visible &&
        decreaseBlock.cursorOverflowPercentageForHidding != null) {
      double percentage = offset / (decreaseBlock.size! / 100);
      if (percentage.round().abs() >
          decreaseBlock.cursorOverflowPercentageForHidding! * 100) {
        _resizer.hide(decreaseBlock);
      }
    }

    if (increaseBlock.isNotVisible &&
        increaseBlock.cursorOverflowPercentageForShowing != null) {
      double size = _resizer.maxSizeWithoutSeparators! *
          (increaseBlock.hidingPercentage ??
              increaseBlock.defaultPercentage ??
              0);
      if (size != 0) {
        double percentage = offset / (size / 100);
        if (percentage.round().abs() >
            increaseBlock.cursorOverflowPercentageForShowing! * 100) {
          _resizer.show(increaseBlock);
        }
      }
    }
    // ResizableWidgetChildData targetBlock =
    //     children[data.separatorIndex + (offset > 0 ? 1 : -1)];
    // if (targetBlock.visible &&
    //     targetBlock.cursorOverflowPercentageForHidding != null) {
    //   double percentage = offset / (targetBlock.size! / 100);
    //   print(offset);
    //   print(percentage);
    //   print(percentage.round());
    //   print(targetBlock.cursorOverflowPercentageForHidding);
    //   print('---------------');
    //   if (percentage.round().abs() >
    //       targetBlock.cursorOverflowPercentageForHidding! * 100) {
    //     _resizer.hide(targetBlock);
    //   }
    // }
    // _info.onResized?.call(children
    //     .where((x) => x.widget is! Separator)
    //     .map((x) => WidgetSizeInfo(size: x.size!, percentage: x.percentage!))
    //     .toList());
  }
}
