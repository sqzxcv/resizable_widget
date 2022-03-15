import 'package:flutter/material.dart';
import 'resizable_widget_args_info.dart';
import 'resizable_widget_child_data.dart';
import 'resizable_widget_controller.dart';
import 'separator.dart';
import 'separator_args_info.dart';
import 'widget_size_info.dart';

typedef SeparatorFactory = Widget Function(SeparatorArgsBasicInfo basicInfo);

class ResizableWidgetModel {
  final ResizableWidgetArgsInfo _info;
  final children = <ResizableWidgetChildData>[];
  double? maxSize;
  double? get maxSizeWithoutSeparators => maxSize == null
      ? null
      : maxSize! - (children.length ~/ 2) * _info.separatorSize;

  ResizableWidgetModel(this._info);

  void init(SeparatorFactory separatorFactory) {
    final originalChildren = _info.children;
    final size = originalChildren.length;
    final originalPercentages =
        _info.percentages ?? List.filled(size, 1 / size);
    for (var i = 0; i < size - 1; i++) {
      children.add(ResizableWidgetChildData(
          originalChildren[i], originalPercentages[i]));
      children.add(ResizableWidgetChildData(
          separatorFactory.call(SeparatorArgsBasicInfo(
            2 * i + 1,
            _info.isHorizontalSeparator,
            _info.isDisabledSmartHide,
            _info.separatorSize,
            _info.separatorColor,
            _info.onPanStart,
            _info.onPanUpdate,
            _info.onPanEnd,
          )),
          null));
    }
    children.add(ResizableWidgetChildData(
        originalChildren[size - 1], originalPercentages[size - 1]));
  }

  void setSizeIfNeeded(BoxConstraints constraints) {
    final max = _info.isHorizontalSeparator
        ? constraints.maxHeight
        : constraints.maxWidth;
    var isMaxSizeChanged = maxSize == null || maxSize! != max;
    if (!isMaxSizeChanged || children.isEmpty) {
      return;
    }

    maxSize = max;
    final remain = maxSizeWithoutSeparators!;

    bool prevHadNegative = false;
    for (var i = 0; i < children.length; i++) {
      ResizableWidgetChildData c = children[i];
      if (c.widget is Separator) {
        c.percentage = 0;
        // if (prevHadNegative) {
        //   c.size = 0;
        //   prevHadNegative = false;
        // } else {
        c.size = _info.separatorSize;
        // }
      } else {
        c.size = remain * c.percentage!;
        if (c.size! < 0) {
          c.size = 0;
          prevHadNegative = true;
        }
        c.defaultPercentage = c.percentage;
      }
    }
  }

  bool canBeResized(ResizableWidgetChildData widgetChildData, Offset offset) {
    return (widgetChildData.size ?? 0) > 0;
  }

  WidgetSizeInfo calculateNewSize(
      ResizableWidgetChildData widgetChildData, Offset offset) {
    final size = widgetChildData.size ?? 0;
    double sizeAfter =
        size + (_info.isHorizontalSeparator ? offset.dy : offset.dx);
    double delta = 0;
    if (sizeAfter < 0) {
      delta = sizeAfter.abs();
      sizeAfter = 0;
    }
    double calculatedMaxSize =
        children.map((item) => item.size ?? 0).reduce((a, b) => a + b) -
            (children.length ~/ 2) * _info.separatorSize;
    if (calculatedMaxSize > 0) {
      double maxSizeAfter = calculatedMaxSize - size + sizeAfter;
      if (maxSizeAfter >= maxSizeWithoutSeparators!) {
        sizeAfter = sizeAfter - (maxSizeAfter - maxSizeWithoutSeparators!);
      }
    }
    double percentage = sizeAfter / maxSizeWithoutSeparators!;
    return WidgetSizeInfo(
        size: sizeAfter, percentage: percentage, delta: delta);
  }

  void setBlockSize(
      ResizableWidgetChildData widgetChildData, WidgetSizeInfo size) {
    widgetChildData.size = size.size;
    widgetChildData.percentage = size.percentage;
  }

  ResizeDirection determineResizeDirection(Offset offset) {
    if (offset.dx == 0 && offset.dy == 0) {
      return ResizeDirection.none;
    }
    if (_info.isHorizontalSeparator) {
      if (offset.dy > 0) {
        return ResizeDirection.bottom;
      } else {
        return ResizeDirection.top;
      }
    } else {
      if (offset.dx > 0) {
        return ResizeDirection.right;
      } else {
        return ResizeDirection.left;
      }
    }
  }

  void resize(int separatorIndex, Offset offset) {
    ResizeDirection direction = determineResizeDirection(offset);
    switch (direction) {
      case ResizeDirection.left:
        ResizableWidgetChildData leftData = children[separatorIndex - 1];
        if (canBeResized(leftData, offset)) {
          WidgetSizeInfo newLeftSize = calculateNewSize(leftData, offset);
          setBlockSize(leftData, newLeftSize);

          ResizableWidgetChildData rightData = children[separatorIndex + 1];
          WidgetSizeInfo newRightSize = calculateNewSize(rightData,
              Offset((offset.dx * -1) + newLeftSize.delta, offset.dy));
          setBlockSize(rightData, newRightSize);
        }
        break;
      case ResizeDirection.right:
        ResizableWidgetChildData rightData = children[separatorIndex + 1];
        if (canBeResized(rightData, offset * (-1))) {
          WidgetSizeInfo newRightSize =
              calculateNewSize(rightData, offset * (-1));
          setBlockSize(rightData, newRightSize);

          ResizableWidgetChildData leftData = children[separatorIndex - 1];
          WidgetSizeInfo newLeftSize = calculateNewSize(
              leftData, Offset(offset.dx + newRightSize.delta, offset.dy));
          setBlockSize(leftData, newLeftSize);
        }
        break;
      case ResizeDirection.top:
        ResizableWidgetChildData topData = children[separatorIndex - 1];
        if (canBeResized(topData, offset)) {
          WidgetSizeInfo newTopSize = calculateNewSize(topData, offset);
          setBlockSize(topData, newTopSize);

          ResizableWidgetChildData bottomData = children[separatorIndex + 1];
          WidgetSizeInfo newBottomSize = calculateNewSize(bottomData,
              Offset(offset.dx, (offset.dy * -1) + newTopSize.delta));
          setBlockSize(bottomData, newBottomSize);
        }
        break;
      case ResizeDirection.bottom:
        ResizableWidgetChildData bottomData = children[separatorIndex + 1];
        if (canBeResized(bottomData, offset * (-1))) {
          WidgetSizeInfo newBottomSize =
              calculateNewSize(bottomData, offset * (-1));
          setBlockSize(bottomData, newBottomSize);

          ResizableWidgetChildData topData = children[separatorIndex - 1];
          WidgetSizeInfo newTopSize = calculateNewSize(
              topData, Offset(offset.dx, offset.dy + newBottomSize.delta));
          setBlockSize(topData, newTopSize);
        }
        break;
      default:
    }
  }

  void callOnResized() {
    _info.onResized?.call(children
        .where((x) => x.widget is! Separator)
        .map((x) => WidgetSizeInfo(size: x.size!, percentage: x.percentage!))
        .toList());
  }

  bool tryHideOrShow(int separatorIndex) {
    if (_info.isDisabledSmartHide) {
      return false;
    }

    final isLeft = separatorIndex == 1;
    final isRight = separatorIndex == children.length - 2;
    if (!isLeft && !isRight) {
      // valid only for both ends.
      return false;
    }

    final target = children[isLeft ? 0 : children.length - 1];
    final size = target.size!;
    final coefficient = isLeft ? 1 : -1;
    if (_isNearlyZero(size)) {
      // show
      final offsetScala =
          maxSize! * (target.hidingPercentage ?? target.defaultPercentage!) -
              size;
      final offset = _info.isHorizontalSeparator
          ? Offset(0, offsetScala * coefficient)
          : Offset(offsetScala * coefficient, 0);
      resize(separatorIndex, offset);
    } else {
      // hide
      target.hidingPercentage = target.percentage!;
      final offsetScala = maxSize! * target.hidingPercentage!;
      final offset = _info.isHorizontalSeparator
          ? Offset(0, -offsetScala * coefficient)
          : Offset(-offsetScala * coefficient, 0);
      resize(separatorIndex, offset);
    }

    return true;
  }

  bool _isNearlyZero(double size) {
    return size < 2;
  }
}
