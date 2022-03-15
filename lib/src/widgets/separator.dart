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
          child: SizedBox(
            child: Container(color: widget.info.color),
            width: widget.info.isHorizontal ? double.infinity : 0,
            height: widget.info.isHorizontal ? 0 : double.infinity,
          ),
        ),
        onPanUpdate: (details) => _controller.onPanUpdate(details, context),
        onDoubleTap: () => _controller.onDoubleTap(),
      );
}
