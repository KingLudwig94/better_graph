import 'package:better_graph/chartPainter.dart';
import 'package:better_graph/series.dart';
import 'package:better_graph/viewport.dart';
import 'package:flutter/material.dart' hide Viewport, Step;

class Chart extends StatefulWidget {
  Chart({Key key, this.series, this.startDate, this.endDate}) : super(key: key);
  final Series series;
  final DateTime startDate;
  final DateTime endDate;
  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  DateTime startTime;
  DateTime endTime;
  Viewport viewport;
  @override
  void initState() {
    startTime = widget.startDate;
    endTime = widget.endDate;
    viewport = Viewport(start: startTime, end: endTime);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GestureDetector(
        onHorizontalDragUpdate: handleHorizontalDrag,
        onVerticalDragUpdate: handleVerticalDrag,
        child: CustomPaint(
          child: Container(),
          painter: MyChartPainter(
            widget.series,
            viewport: viewport,
          ),
        ),
      ),
    );
  }

  void handleHorizontalDrag(DragUpdateDetails details) {
    final dd = details.primaryDelta;
    Duration duration;
    setState(() {
      if (viewport.step == Step.Minute) {
        duration = Duration(minutes: dd.floor());
      }
      var startTime1 = startTime.subtract(duration);
      var endTime1 = endTime.subtract(duration);
      if (!(startTime1.compareTo(widget.series.end) < 0) ||
          (!(endTime1.compareTo(widget.series.start) > 0))) {
        return;
      }
      startTime = startTime1;
      endTime = endTime1;

      viewport = Viewport(start: startTime, end: endTime);
    });
  }

  void handleVerticalDrag(DragUpdateDetails details) {
    final dd = details.primaryDelta;
    Duration duration;
    setState(() {
      if (viewport.step == Step.Minute) {
        duration = Duration(minutes: dd.floor());
      }
      var startTime1 = startTime.subtract(duration);
      var endTime1 = endTime.add(duration);
      if (endTime1.difference(startTime1).compareTo(widget.series.rangeX) > 0)
        return;
      if (endTime1.difference(startTime1).inMinutes < 1) return;
      startTime = startTime1;
      endTime = endTime1;

      viewport = Viewport(start: startTime, end: endTime);
    });
  }
}
