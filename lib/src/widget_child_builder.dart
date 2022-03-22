import 'package:flutter/widgets.dart';

import 'models/resizable_widget_args_info.dart';
import 'models/resizable_widget_child_data.dart';
import 'resizable_widget_controller.dart';
import 'widgets/resizable_widget_child.dart';
import 'widgets/separator.dart';
import 'widgets/separator_info.dart';

class WidgetChildBuilder {
  final ResizableWidgetArgsInfo info;
  final ResizableWidgetController controller;
  WidgetChildBuilder(this.info, this.controller);
  List<ResizableWidgetChildData> build() {
    final size = info.children.length;

    final originalPercentages = _calculatePercentages();
    List<ResizableWidgetChildData> result = [];
    for (var i = 0; i < size - 1; i++) {
      ResizableWidgetChild child =
          _buildWidget(info.children[i], originalPercentages[i], i);
      result.add(_buildChildData(child, originalPercentages[i], i));

      result.add(_buildChildData(_buildSeparator(i), null, i));
    }
    int lastIndex = size - 1;
    ResizableWidgetChild child = _buildWidget(
        info.children[lastIndex], originalPercentages[lastIndex], lastIndex);
    result
        .add(_buildChildData(child, originalPercentages[lastIndex], lastIndex));

    return result;
  }

  ResizableWidgetChildData _buildChildData(
      Widget widget, double? percentage, int index) {
    ResizableWidgetChildData data;
    if (widget is ResizableWidgetChild) {
      data = ResizableWidgetChildData(
          widget: widget,
          percentage: percentage,
          index: index,
          minPercentage: widget.minPercentage,
          maxPercentage: widget.maxPercentage,
          visible: widget.visible,
          cursorOverflowPercentageForHidding:
              widget.cursorOverflowPercentageForHidding,
          cursorOverflowPercentageForShowing:
              widget.cursorOverflowPercentageForShowing);
      _setupActionHandler(data);
    } else {
      data = ResizableWidgetChildData(
          widget: widget, percentage: percentage, index: index);
    }
    return data;
  }

  ResizableWidgetChild _buildWidget(
      Widget child, double percentage, int index) {
    if (child is ResizableWidgetChild) {
      return child;
    } else {
      return ResizableWidgetChild(
        child: child,
        percentage: percentage,
      );
    }
  }

  void _setupActionHandler(ResizableWidgetChildData data) {
    if (data.widget is ResizableWidgetChild) {
      ResizableWidgetChild widget = data.widget as ResizableWidgetChild;
      if (widget.actionStream != null) {
        widget.actionStream!.stream.listen((event) {
          switch (event) {
            case ResizableWidgetChildAction.hide:
              controller.hide(data);
              break;
            case ResizableWidgetChildAction.show:
              controller.show(data);
              break;
            case ResizableWidgetChildAction.toogleVisible:
              if (data.visible) {
                controller.hide(data);
              } else {
                controller.show(data);
              }
              break;
            default:
          }
        });
      }
    }
  }

  Separator _buildSeparator(int index) {
    SeparatorInfo separatorInfo = SeparatorInfo(
      index: 2 * index + 1,
      isHorizontal: info.isHorizontalSeparator,
      isDisabledSmartHide: info.isDisabledSmartHide,
      parentController: controller,
      size: info.separatorSize,
      color: info.separatorColor,
      onPanStart: info.onPanStart,
      onPanUpdate: info.onPanUpdate,
      onPanEnd: info.onPanEnd,
    );
    return Separator(info: separatorInfo);
  }

  List<double> _calculatePercentages() {
    List<double?> existingPercentages = info.children
        .map((child) {
          if (child is ResizableWidgetChild) {
            return child.percentage;
          } else {
            return null;
          }
        })
        .toList()
        .where((p) => p != null)
        .toList();

    double existingSum =
        existingPercentages.fold(0, (previous, current) => previous + current!);

    double defaultPercentage;
    if (existingSum <= 0 || existingSum > 1) {
      return List.filled(info.children.length, 1 / info.children.length);
    }

    defaultPercentage =
        (1 - existingSum) / (info.children.length - existingPercentages.length);

    return info.children.map((child) {
      if (child is ResizableWidgetChild) {
        if (child.percentage == null) {
          return defaultPercentage;
        } else {
          return child.percentage! >= 0 && child.percentage! <= 1
              ? child.percentage!
              : defaultPercentage;
        }
      } else {
        return defaultPercentage;
      }
    }).toList();
  }
}
