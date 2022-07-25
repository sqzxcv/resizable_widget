import 'dart:async';

import 'package:flutter/material.dart';
import 'models/resizable_widget_args_info.dart';
import 'models/resizable_widget_child_data.dart';
import 'models/resize_args.dart';
import 'resizable_widget_controller.dart';
import 'models/widget_size_info.dart';
import 'widgets/resizable_widget_child.dart';
import 'widgets/separator.dart';

class WidgetChildrenResizer {
  final StreamController<Object> _eventStream;
  final ResizableWidgetArgsInfo _info;
  final List<ResizableWidgetChildData> children;
  double? maxSize;
  double? get maxSizeWithoutSeparators => maxSize == null
      ? null
      : maxSize! - visibleSeparatorCount * _info.separatorSize;

  int get visibleSeparatorCount => children
      .where((element) => element.widget.child is Separator && element.visible)
      .length;
  WidgetChildrenResizer(this.children, this._info, this._eventStream);

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

    final target = isLeft ? children.first : children.last;
    final size = target.size!;
    if (_isNearlyZero(size)) {
      show(target);
    } else {
      hide(target);
    }

    return true;
  }

  bool show(ResizableWidgetChildData target, {bool force = false}) {
    if (!force && target.visible) {
      return true;
    }

    bool isLast = target.index == children.length - 1;
    final int separatorIndex = isLast ? target.index - 1 : target.index + 1;

    final int coefficient = isLast ? -1 : 1;
    double offsetScala = maxSizeWithoutSeparators! *
        (target.hidingPercentage ?? target.defaultPercentage!);
    if ((isLast || target.index == 0) && target.hideSeparatorOnWidgetHide) {
      offsetScala += _info.separatorSize;
      children[separatorIndex].visible = true;
      setBlockSize(children[separatorIndex],
          WidgetSizeInfo(size: _info.separatorSize, percentage: 0));
    }
    final Offset offset = _info.isHorizontalSeparator
        ? Offset(0, offsetScala * coefficient)
        : Offset(offsetScala * coefficient, 0);

    target.hidingPercentage = null;
    target.visible = true;

    resize(ResizeArgs(separatorIndex: separatorIndex, offset: offset));

    if (target.widget.actionStream != null) {
      target.widget.actionStream!.sink
          .add(ResizableWidgetChildAction.afterShow);
    }
    return true;
  }

  bool hide(ResizableWidgetChildData target, {bool force = false}) {
    if (!force && target.isNotVisible) {
      return true;
    }
    if (target.percentage! == 0) {
      target.visible = false;
      return true;
    }
    final bool isLast = target.index == children.length - 1;
    final int separatorIndex = isLast ? target.index - 1 : target.index + 1;

    final int coefficient = isLast ? -1 : 1;

    double offsetScala = maxSizeWithoutSeparators! * target.percentage!;
    if ((isLast || target.index == 0) && target.hideSeparatorOnWidgetHide) {
      children[separatorIndex].visible = false;
      offsetScala += _info.separatorSize;
      setBlockSize(children[separatorIndex],
          const WidgetSizeInfo(size: 0, percentage: 0));
    }
    final Offset offset = _info.isHorizontalSeparator
        ? Offset(0, -offsetScala * coefficient)
        : Offset(-offsetScala * coefficient, 0);

    target.hidingPercentage = target.percentage!;
    target.visible = false;

    resize(ResizeArgs(separatorIndex: separatorIndex, offset: offset));
    if (target.widget.actionStream != null) {
      target.widget.actionStream!.sink
          .add(ResizableWidgetChildAction.afterHide);
    }
    return true;
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
    final double remain = maxSizeWithoutSeparators!;
    bool prevHadNegative = false;
    for (var i = 0; i < children.length; i++) {
      ResizableWidgetChildData c = children[i];
      if (c.widget.child is Separator) {
        double size = c.visible ? _info.separatorSize : 0;
        if (prevHadNegative) {
          size = 0;
          prevHadNegative = false;
        }
        setBlockSize(c, WidgetSizeInfo(size: size, percentage: 0));
      } else {
        double size = remain * c.percentage!;
        if (size < 0) {
          size = 0;
          prevHadNegative = true;
        }
        double? defaultPercentage = c.percentage;
        setBlockSize(
            c,
            WidgetSizeInfo(
                size: size,
                percentage: c.percentage!,
                defaultPercentage: defaultPercentage));
      }
    }
    for (var i = 0; i < children.length; i++) {
      ResizableWidgetChildData c = children[i];
      if (c.widget is Separator) {
        // resize(ResizeArgs(separatorIndex: i, offset: Offset.zero));
        continue;
      }
      // setBlockSize(c, calculateNewSize(c, Offset.zero));
      if (c.isNotVisible) {
        hide(c, force: true);
      }
    }
    normalize();
  }

  void normalize() {
    double currentSum = children
        .map((e) => e.percentage ?? 0)
        .toList()
        .fold<double>(0, (previous, current) => previous + current);
    double diff = 1 - currentSum;
    ResizableWidgetChildData last =
        children.lastWhere((element) => element.visible);

    double newPercentage = (last.percentage ?? 0) + diff;
    double newSize = maxSizeWithoutSeparators! * newPercentage;
    setBlockSize(
        last, WidgetSizeInfo(percentage: newPercentage, size: newSize));
  }

  ResizableWidgetChildData? findNextCanBeSmaller(
      int separatorIndex, int direction) {
    if (direction == 0) {
      return null;
    }
    int step;
    bool Function(int) checker;
    if (direction > 0) {
      step = 1;
      checker = (p0) => p0 < children.length;
    } else {
      step = -1;
      checker = (p0) => p0 >= 0;
    }

    for (int i = separatorIndex; checker(i); i += step) {
      if (children[i].widget.child is Separator) {
        continue;
      }
      if (canBeSmaller(children[i])) {
        return children[i];
      }
    }
    return null;
  }

  void resize(ResizeArgs data) {
    ResizeDirection direction = determineResizeDirection(data.offset);
    switch (direction) {
      case ResizeDirection.left:
        ResizableWidgetChildData? leftData =
            findNextCanBeSmaller(data.separatorIndex, -1);
        ResizableWidgetChildData rightData = children[data.separatorIndex + 1];
        if (leftData != null && canBeBigger(rightData)) {
          WidgetSizeInfo newLeftSize = calculateNewSize(leftData, data.offset);
          // we need to set new data for correct calculation of maxPercentage in next block calculation
          // relevant in all directions
          setBlockSize(leftData, newLeftSize);

          if (newLeftSize.delta > 0) {
            ResizableWidgetChildData? leftData =
                findNextCanBeSmaller(data.separatorIndex, -1);
            if (leftData != null) {
              newLeftSize = calculateNewSize(
                  leftData, Offset(newLeftSize.delta * -1, data.offset.dy));
              setBlockSize(leftData, newLeftSize);
            }
          }
          // All calculation always start from block that need decreasing(for handle size less then 0).
          // So order is decrease some block and increase another block.
          // But because of maxSize option we can face with problem that we decrease block and after trying to increase another.
          // But it's over of max size(calculate method will handle that increase only on available size)
          // and we will have some delta that need to be aplyid somewhere.
          // So we just trying to apply this delta to the block that was decreased.
          // Same for resize to bottom
          WidgetSizeInfo newRightSize = calculateNewSize(
              rightData,
              Offset(
                  (data.offset.dx * -1) + newLeftSize.delta, data.offset.dy));
          setBlockSize(rightData, newRightSize);

          _eventStream.add(this);
        }
        break;
      case ResizeDirection.right:
        ResizableWidgetChildData? rightData =
            findNextCanBeSmaller(data.separatorIndex, 1);
        ResizableWidgetChildData leftData = children[data.separatorIndex - 1];
        if (rightData != null && canBeBigger(leftData)) {
          WidgetSizeInfo newRightSize =
              calculateNewSize(rightData, data.offset * (-1));
          setBlockSize(rightData, newRightSize);

          if (newRightSize.delta > 0) {
            ResizableWidgetChildData? rightData =
                findNextCanBeSmaller(data.separatorIndex, 1);
            if (rightData != null) {
              newRightSize = calculateNewSize(
                  rightData, Offset(newRightSize.delta * -1, data.offset.dy));
              setBlockSize(rightData, newRightSize);
            }
          }
          WidgetSizeInfo newLeftSize = calculateNewSize(leftData,
              Offset(data.offset.dx + newRightSize.delta, data.offset.dy));
          setBlockSize(leftData, newLeftSize);
          _eventStream.add(this);
        }
        break;
      case ResizeDirection.top:
        ResizableWidgetChildData? topData =
            findNextCanBeSmaller(data.separatorIndex, -1);
        ResizableWidgetChildData bottomData = children[data.separatorIndex + 1];

        if (topData != null && canBeBigger(bottomData)) {
          WidgetSizeInfo newTopSize = calculateNewSize(topData, data.offset);
          setBlockSize(topData, newTopSize);

          if (newTopSize.delta > 0) {
            ResizableWidgetChildData? topData =
                findNextCanBeSmaller(data.separatorIndex, -1);
            if (topData != null) {
              newTopSize = calculateNewSize(
                  topData, Offset(newTopSize.delta * -1, data.offset.dy));
              setBlockSize(topData, newTopSize);
            }
          }
          WidgetSizeInfo newBottomSize = calculateNewSize(bottomData,
              Offset(data.offset.dx, (data.offset.dy * -1) + newTopSize.delta));
          setBlockSize(bottomData, newBottomSize);
          _eventStream.add(this);
        }
        break;
      case ResizeDirection.bottom:
        ResizableWidgetChildData? bottomData =
            findNextCanBeSmaller(data.separatorIndex, 1);
        ResizableWidgetChildData topData = children[data.separatorIndex - 1];

        if (bottomData != null && canBeBigger(topData)) {
          WidgetSizeInfo newBottomSize =
              calculateNewSize(bottomData, data.offset * (-1));
          setBlockSize(bottomData, newBottomSize);

          if (newBottomSize.delta > 0) {
            ResizableWidgetChildData? bottomData =
                findNextCanBeSmaller(data.separatorIndex, 1);
            if (bottomData != null) {
              newBottomSize = calculateNewSize(
                  bottomData, Offset(newBottomSize.delta * -1, data.offset.dy));
              setBlockSize(bottomData, newBottomSize);
            }
          }
          WidgetSizeInfo newTopSize = calculateNewSize(topData,
              Offset(data.offset.dx, data.offset.dy + newBottomSize.delta));
          setBlockSize(topData, newTopSize);

          _eventStream.add(this);
        }
        break;
      default:
    }
  }

  bool blocksCanChangeTheirSize(ResizeArgs data) {
    ResizeDirection direction = determineResizeDirection(data.offset);

    late ResizableWidgetChildData? blockToDecrease;
    late ResizableWidgetChildData blockToIncrease;

    switch (direction) {
      case ResizeDirection.left:
        blockToDecrease = findNextCanBeSmaller(data.separatorIndex, -1);
        blockToIncrease = children[data.separatorIndex + 1];
        break;
      case ResizeDirection.right:
        blockToDecrease = findNextCanBeSmaller(data.separatorIndex, 1);
        blockToIncrease = children[data.separatorIndex - 1];
        break;
      case ResizeDirection.top:
        blockToDecrease = findNextCanBeSmaller(data.separatorIndex, -1);
        blockToIncrease = children[data.separatorIndex + 1];
        break;
      case ResizeDirection.bottom:
        blockToDecrease = findNextCanBeSmaller(data.separatorIndex, 1);
        blockToIncrease = children[data.separatorIndex - 1];
        break;
      default:
        return false;
    }
    return blockToDecrease != null && canBeBigger(blockToIncrease);
  }

  WidgetSizeInfo calculateNewSize(
      ResizableWidgetChildData widgetChildData, Offset offset) {
    final size = widgetChildData.size ?? 0;
    double sizeAfter =
        size + (_info.isHorizontalSeparator ? offset.dy : offset.dx);
    double delta = 0;
    double storeMaxSizeWithoutSeparators = maxSizeWithoutSeparators!;
    if (sizeAfter < 0) {
      delta = sizeAfter.abs();
      sizeAfter = 0;
    }
    double calculatedMaxSize =
        children.map((item) => item.size ?? 0).reduce((a, b) => a + b) -
            visibleSeparatorCount * _info.separatorSize;
    if (calculatedMaxSize > 0) {
      double maxSizeAfter = calculatedMaxSize - size + sizeAfter;
      if (maxSizeAfter >= storeMaxSizeWithoutSeparators) {
        sizeAfter = sizeAfter - (maxSizeAfter - storeMaxSizeWithoutSeparators);
      }
    }
    double percentage = sizeAfter / storeMaxSizeWithoutSeparators;
    if (widgetChildData.visible) {
      if (widgetChildData.minPercentage != null &&
          percentage < widgetChildData.minPercentage!) {
        double minSize =
            widgetChildData.minPercentage! * storeMaxSizeWithoutSeparators;
        delta += minSize - sizeAfter;
        sizeAfter = minSize;
        percentage = widgetChildData.minPercentage!;
      } else if (widgetChildData.maxPercentage != null &&
          percentage > widgetChildData.maxPercentage!) {
        double maxSize =
            widgetChildData.maxPercentage! * storeMaxSizeWithoutSeparators;
        delta = sizeAfter - maxSize;
        sizeAfter = maxSize;
        percentage = widgetChildData.maxPercentage!;
      }
    }
    return WidgetSizeInfo(
        size: sizeAfter, percentage: percentage, delta: delta);
  }

  void setBlockSize(
      ResizableWidgetChildData widgetChildData, WidgetSizeInfo size) {
    widgetChildData.size = size.size.abs();
    widgetChildData.percentage = size.percentage.abs();
    if (size.defaultPercentage != null) {
      widgetChildData.defaultPercentage = size.defaultPercentage!.abs();
    }
    widgetChildData.needRebuild = true;
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

  bool separatorIsValidForResize(ResizeArgs data) {
    if (data.cursorPosition == null || data.separatorPosition == null) {
      return true;
    }
    try {
      ResizeDirection direction = determineResizeDirection(data.offset);
      switch (direction) {
        case ResizeDirection.left:
          return data.cursorPosition!.dx - _info.separatorSize <=
              data.separatorPosition!.dx;
        case ResizeDirection.right:
          return data.cursorPosition!.dx + _info.separatorSize >=
              data.separatorPosition!.dx;
        case ResizeDirection.top:
          return data.cursorPosition!.dy - _info.separatorSize <=
              data.separatorPosition!.dy;
        case ResizeDirection.bottom:
          return data.cursorPosition!.dy + _info.separatorSize >=
              data.separatorPosition!.dy;
        default:
          return true;
      }
    } catch (e) {
      return true;
    }
  }

  bool canBeSmaller(ResizableWidgetChildData widgetChildData) {
    return (widgetChildData.size ?? 0) > 0 &&
        (!widgetChildData.visible ||
            widgetChildData.minPercentage == null ||
            widgetChildData.percentage! > widgetChildData.minPercentage!);
  }

  bool canBeBigger(ResizableWidgetChildData widgetChildData) {
    return widgetChildData.visible &&
        (widgetChildData.maxPercentage == null ||
            widgetChildData.percentage! < widgetChildData.maxPercentage!);
  }

  bool _isNearlyZero(double size) {
    return size < 2;
  }
}
