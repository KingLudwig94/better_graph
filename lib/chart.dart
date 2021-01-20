import 'dart:math';

import 'package:better_graph/chartPainter.dart';
import 'package:better_graph/series.dart';
import 'package:better_graph/viewport.dart';
import 'package:flutter/material.dart' hide Viewport, Step;

class Chart extends StatefulWidget {
  Chart({Key key, this.seriesList, this.viewport, this.ranges})
      : super(key: key);
  final List<Series> seriesList;
  final Viewport viewport;
  final List<Range> ranges;
  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  DateTime startTime;
  DateTime endTime;
  Viewport viewport;
  DateTime minT;
  DateTime maxT;
  Duration rangeX;
  num maxV;
  num minV;

  Viewport calculateViewport() {
    minT = widget.seriesList.map((e) => e.start).reduce(
        (value, element) => value.compareTo(element) < 0 ? value : element);
    startTime = minT;
    maxT = widget.seriesList.map((e) => e.end).reduce(
        (value, element) => value.compareTo(element) > 0 ? value : element);
    endTime = maxT;
    rangeX = maxT.difference(minT);
    maxV = widget.seriesList
        .where((element) => element.type != SeriesType.noValue)
        .map((e) => e.max)
        .reduce((value, element) => max(value, element));
    minV = widget.seriesList
        .where((element) => element.type != SeriesType.noValue)
        .map((e) => e.min)
        .reduce((value, element) => min(value, element));
    return Viewport(start: startTime, end: endTime, max: maxV, min: minV);
  }

  @override
  Widget build(BuildContext context) {
    viewport = widget.viewport ?? calculateViewport();
    return Container(
      child: GestureDetector(
        onHorizontalDragUpdate: handleHorizontalDrag,
        onVerticalDragUpdate: handleVerticalDrag,
        onTapUp: handleTap,
        child: CustomPaint(
          child: Container(),
          painter: MyChartPainter(
            widget.seriesList,
            viewport: viewport,
            ranges: widget.ranges,
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
      } else if (viewport.step == Step.Hour) {
        duration = Duration(minutes: dd.floor() * 30);
      } else if (viewport.step == Step.Day) {
        duration = Duration(hours: dd.floor() * 12);
      }
      var startTime1 = startTime.subtract(duration);
      var endTime1 = endTime.subtract(duration);
      if (!(startTime1.compareTo(minT) < 0) ||
          (!(endTime1.compareTo(maxT) > 0))) {
        return;
      }
      startTime = startTime1;
      endTime = endTime1;

      viewport = calculateViewport();
    });
  }

  void handleVerticalDrag(DragUpdateDetails details) {
    final dd = details.primaryDelta;
    Duration duration;
    setState(() {
      if (viewport.step == Step.Minute) {
        duration = Duration(minutes: dd.floor());
      } else if (viewport.step == Step.Hour) {
        duration = Duration(hours: dd.floor());
      } else if (viewport.step == Step.Day) {
        duration = Duration(hours: dd.floor() * 12);
      }

      var startTime1 = startTime.subtract(duration);
      var endTime1 = endTime.add(duration);
      if (endTime1.difference(startTime1).compareTo(rangeX) > 0)
        // max out
        return;
      if (endTime1.difference(startTime1).inMinutes < 1) return;
      startTime = startTime1;
      endTime = endTime1;

      viewport = calculateViewport();
    });
  }

  void handleTap(TapUpDetails details) {
    Map<Data, Offset> o = Map();
    MyChartPainter.points.forEach((key, value) => o.addAll(value));
    var sel = o.entries.firstWhere(
        (element) => (element.value - details.localPosition).distance < 15.0,
        orElse: () => null);
    MyChartPainter.selected.value = sel != null ? sel.key : null;
  }
}
