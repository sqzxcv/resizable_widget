import 'package:flutter/material.dart';
import 'package:resizable_widget/src/separator_controller.dart';
import 'separator_info.dart';

class Separator extends StatefulWidget {
  final SeparatorInfo info;

  const Separator({
    required this.info,
    Key? key,
  }) : super(key: key);

  @override
  _SeparatorState createState() => _SeparatorState();
}

class _SeparatorState extends State<Separator> {
  late SeparatorController _controller;
  @override
  void initState() {
    super.initState();
    _controller = SeparatorController(widget.info.index, widget.info);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        child: MouseRegion(
          cursor: widget.info.isHorizontal
              ? SystemMouseCursors.resizeRow
              : SystemMouseCursors.resizeColumn,
          child: Container(color: widget.info.color),
        ),
        onPanUpdate: (details) => _controller.onPanUpdate(details, context),
        onPanStart: (details) => _controller.onPanStart(details, context),
        onPanEnd: (details) => _controller.onPanEnd(details, context),
        onDoubleTap: () => _controller.onDoubleTap(),
      );
}
