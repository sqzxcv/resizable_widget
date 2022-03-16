import 'package:flutter/material.dart';
import 'resizable_widget_args_info.dart';
import 'resizable_widget_child_data.dart';
import 'resizable_widget_controller.dart';
import 'widget_size_info.dart';
import 'widgets/separator.dart';

class WidgetChildrenResizer {
  final ResizableWidgetArgsInfo _info;
  final List<ResizableWidgetChildData> children;
  double? maxSize;
  double? get maxSizeWithoutSeparators => maxSize == null
      ? null
      : maxSize! - (children.length ~/ 2) * _info.separatorSize;

  WidgetChildrenResizer(this.children, this._info);

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
        double size = _info.separatorSize;
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
  }

  bool canBeSmaller(ResizableWidgetChildData widgetChildData) {
    return (widgetChildData.size ?? 0) > 0 &&
        (widgetChildData.minPercentage == null ||
            widgetChildData.percentage! > widgetChildData.minPercentage!);
  }

  bool canBeBigger(ResizableWidgetChildData widgetChildData) {
    return (widgetChildData.maxPercentage == null ||
        widgetChildData.percentage! < widgetChildData.maxPercentage!);
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

    if (widgetChildData.minPercentage != null &&
        percentage < widgetChildData.minPercentage!) {
      double minSize =
          widgetChildData.minPercentage! * maxSizeWithoutSeparators!;
      delta += sizeAfter - minSize;
      sizeAfter = minSize;
      percentage = widgetChildData.minPercentage!;
    } else if (widgetChildData.maxPercentage != null &&
        percentage > widgetChildData.maxPercentage!) {
      double maxSize =
          widgetChildData.maxPercentage! * maxSizeWithoutSeparators!;
      delta = sizeAfter - maxSize;
      sizeAfter = maxSize;
      percentage = widgetChildData.maxPercentage!;
    }
    return WidgetSizeInfo(
        size: sizeAfter, percentage: percentage, delta: delta);
  }

  void setBlockSize(
      ResizableWidgetChildData widgetChildData, WidgetSizeInfo size) {
    widgetChildData.size = size.size;
    widgetChildData.percentage = size.percentage;
    if (size.defaultPercentage != null) {
      widgetChildData.defaultPercentage = size.defaultPercentage;
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

  void resize(int separatorIndex, Offset offset) {
    ResizeDirection direction = determineResizeDirection(offset);
    switch (direction) {
      case ResizeDirection.left:
        ResizableWidgetChildData leftData = children[separatorIndex - 1];
        ResizableWidgetChildData rightData = children[separatorIndex + 1];
        if (canBeSmaller(leftData) && canBeBigger(rightData)) {
          WidgetSizeInfo newLeftSize = calculateNewSize(leftData, offset);
          // we need to set new data for correct calculation of maxPercentage in next block calculation
          // relevant in all directions
          setBlockSize(leftData, newLeftSize);

          WidgetSizeInfo newRightSize = calculateNewSize(rightData,
              Offset((offset.dx * -1) + newLeftSize.delta, offset.dy));
          setBlockSize(rightData, newRightSize);

          // All calculation always start from block that need decreasing(for handle size less then 0).
          // So order is decrease some block and increase another block.
          // But because of maxSize option we can face with problem that we decrease block and after trying to increase another.
          // But it's over of max size(calculate method will handle that increase only on available size)
          // and we will have some delta that need to be aplyid somewhere.
          // So we just trying to apply this delta to the block that was decreased.
          // Same for resize to bottom
          if (newRightSize.delta > 0) {
            WidgetSizeInfo newLeftSize = calculateNewSize(
                leftData, Offset(newRightSize.delta, offset.dy));
            setBlockSize(leftData, newLeftSize);
          }
        }
        break;
      case ResizeDirection.right:
        ResizableWidgetChildData rightData = children[separatorIndex + 1];
        ResizableWidgetChildData leftData = children[separatorIndex - 1];

        if (canBeSmaller(rightData) && canBeBigger(leftData)) {
          WidgetSizeInfo newRightSize =
              calculateNewSize(rightData, offset * (-1));
          setBlockSize(rightData, newRightSize);

          WidgetSizeInfo newLeftSize = calculateNewSize(
              leftData, Offset(offset.dx + newRightSize.delta, offset.dy));
          setBlockSize(leftData, newLeftSize);
          if (newLeftSize.delta > 0) {
            WidgetSizeInfo newRightSize = calculateNewSize(
                rightData, Offset(newLeftSize.delta, offset.dy));
            setBlockSize(rightData, newRightSize);
          }
        }
        break;
      case ResizeDirection.top:
        ResizableWidgetChildData topData = children[separatorIndex - 1];
        ResizableWidgetChildData bottomData = children[separatorIndex + 1];

        if (canBeSmaller(topData) && canBeBigger(bottomData)) {
          WidgetSizeInfo newTopSize = calculateNewSize(topData, offset);
          setBlockSize(topData, newTopSize);

          WidgetSizeInfo newBottomSize = calculateNewSize(bottomData,
              Offset(offset.dx, (offset.dy * -1) + newTopSize.delta));
          setBlockSize(bottomData, newBottomSize);

          if (newBottomSize.delta > 0) {
            WidgetSizeInfo newTopSize = calculateNewSize(
                topData, Offset(offset.dx, newBottomSize.delta));
            setBlockSize(topData, newTopSize);
          }
        }
        break;
      case ResizeDirection.bottom:
        ResizableWidgetChildData bottomData = children[separatorIndex + 1];
        ResizableWidgetChildData topData = children[separatorIndex - 1];

        if (canBeSmaller(bottomData) && canBeBigger(topData)) {
          WidgetSizeInfo newBottomSize =
              calculateNewSize(bottomData, offset * (-1));
          setBlockSize(bottomData, newBottomSize);

          WidgetSizeInfo newTopSize = calculateNewSize(
              topData, Offset(offset.dx, offset.dy + newBottomSize.delta));
          setBlockSize(topData, newTopSize);

          if (newTopSize.delta > 0) {
            WidgetSizeInfo newBottomSize = calculateNewSize(
                bottomData, Offset(offset.dx, newTopSize.delta));
            setBlockSize(bottomData, newBottomSize);
          }
        }
        break;
      default:
    }
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
