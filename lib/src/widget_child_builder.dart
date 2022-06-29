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
    int orderIndex = 0;
    for (var i = 0; i < size - 1; i++) {
      ResizableWidgetChildData child =
          _buildChildData(info.children[i], originalPercentages[i], orderIndex);
      result.add(child);

      orderIndex++;
      ResizableWidgetChildData separator =
          _buildChildData(_buildSeparator(i), null, orderIndex);
      if (i == 0 && child.isNotVisible && child.hideSeparatorOnWidgetHide) {
        separator.visible = false;
      }
      result.add(separator);
      orderIndex++;
    }
    int lastIndex = size - 1;
    ResizableWidgetChildData child = _buildChildData(
        info.children[lastIndex], originalPercentages[lastIndex], orderIndex);
    ResizableWidgetChildData separator = result.last;
    if (child.isNotVisible && child.hideSeparatorOnWidgetHide) {
      separator.visible = false;
    }
    result.add(_buildChildData(
        info.children[lastIndex], originalPercentages[lastIndex], orderIndex));

    return result;
  }

  ResizableWidgetChildData _buildChildData(
      ResizableWidgetChild widget, double? percentage, int index) {
    ResizableWidgetChildData data;
    percentage ??= 0.0;
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
            widget.cursorOverflowPercentageForShowing,
        hideSeparatorOnWidgetHide: widget.hideSeparatorOnWidgetHide);
    if (widget.child is! Separator && (!widget.visible || percentage == 0)) {
      data.visible = false;
      if (widget.percentage != null &&
          (widget.minPercentage == null ||
              widget.percentage! > widget.minPercentage!) &&
          (widget.maxPercentage == null ||
              widget.percentage! < widget.maxPercentage!)) {
        data.defaultPercentage = widget.percentage;
        data.hidingPercentage = widget.percentage;
      } else if (widget.minPercentage != null) {
        data.defaultPercentage = widget.minPercentage;
        data.hidingPercentage = widget.minPercentage;
      } else {
        double defaultVal = 1 / info.children.length;
        data.defaultPercentage = defaultVal;
        data.hidingPercentage = defaultVal;
      }
    }
    _setupActionHandler(data);

    return data;
  }

  void _setupActionHandler(ResizableWidgetChildData data) {
    if (data.widget.actionStream != null) {
      data.widget.actionStream!.stream.listen((event) {
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

  ResizableWidgetChild _buildSeparator(int index) {
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
    return ResizableWidgetChild(
        child: Separator(info: separatorInfo), percentage: 0);
  }

  List<double> _calculatePercentages() {
    List<double?> existingPercentages = info.children.map((child) {
      if (child.visible) {
        return child.percentage;
      } else {
        return null;
      }
    }).toList();

    int visibleChildren = info.children.where((p) => p.visible).length;
    double existingSum = existingPercentages.fold(
        0, (previous, current) => previous + (current ?? 0));
    double defaultPercentage;
    if (existingSum <= 0 || existingSum > 1) {
      // return List.filled(info.children.length, 1 / info.children.length);
      double defaultValue = visibleChildren > 0 ? 1 / visibleChildren : 0;
      List<double> result = [];
      for (int i = 0; i < info.children.length; i++) {
        result.add(info.children[i].visible ? defaultValue : 0);
      }
      return result;
    }

    int emptyChilds = (visibleChildren -
        existingPercentages.where((element) => element != null).length);
    if (emptyChilds == 0) {
      defaultPercentage = 0;
    } else {
      defaultPercentage = (1 - existingSum) / emptyChilds;
    }
    int i = 0;
    return existingPercentages.map((percentage) {
      ResizableWidgetChild child = info.children[i];
      i++;
      if (!child.visible) {
        return 0.0;
      }
      if (percentage != null &&
          (child.minPercentage == null || percentage > child.minPercentage!) &&
          (child.maxPercentage == null || percentage < child.maxPercentage!)) {
        return child.percentage!;
      }
      if (defaultPercentage != 0) {
        return defaultPercentage;
      }
      if (child.minPercentage != null) {
        return child.minPercentage!;
      }
      return 0.0;
    }).toList();
  }
}
