import 'dart:math';

import 'package:better_graph/chartPainter.dart';
import 'package:better_graph/series.dart';
import 'package:better_graph/viewport.dart';
import 'package:flutter/material.dart' hide Viewport, Step;

class Chart extends StatefulWidget {
  Chart({
    Key key,

    /// list of [Series] to plot
    this.seriesList,

    /// WIP custom viewport
    this.viewport,

    /// ranges to plot
    this.ranges,

    /// title of the chart
    this.title,

    /// background color of the graph
    this.bgColor,

    /// unit of measures for the primary axis
    this.measureUnit,

    /// unit of measures for the secondary axis
    this.secondaryMeasureUnit,

    /// whether to show a legend below the graph, required to show info on the selected [Data]
    this.showLegend = true,

    /// whether to allow pan gesture
    this.pan = true,

    /// whether to allow zoom gesture (up/down drag on plot)
    this.zoom = true,

    /// whether to allow selection gesture
    this.select = true,

    /// whether to have the legend on two colums
    this.twoColLegend = true,
  })  : series = seriesList.where((e) => !e.secondaryAxis).toList(),
        secondarySeries =
            seriesList.where((element) => element.secondaryAxis).toList(),
        super(key: key);
  final List<Series> series;
  final List<Series> secondarySeries;
  final List<Series> seriesList;
  final Viewport viewport;
  final List<Range> ranges;
  final String title;
  final Color bgColor;
  final bool showLegend;
  final String measureUnit;
  final String secondaryMeasureUnit;
  final bool zoom;
  final bool pan;
  final bool select;
  final bool twoColLegend;
  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  DateTime startTime;
  DateTime endTime;
  Viewport viewport;
  Viewport secondaryViewport;
  DateTime minT;
  DateTime maxT;
  Duration rangeX;
  num maxY;
  num minY;
  MyChartPainter chart;
  ValueNotifier<Data> _selected = ValueNotifier(null);

  @override
  void initState() {
    viewport = calculateViewport();
    super.initState();
  }

  Viewport calculateViewport() {
    minT = widget.seriesList.map((e) => e.start).reduce(
        (value, element) => value.compareTo(element) < 0 ? value : element);
    startTime = minT;
    maxT = widget.seriesList.map((e) => e.end).reduce(
        (value, element) => value.compareTo(element) > 0 ? value : element);
    endTime = maxT;
    rangeX = maxT.difference(minT);
    maxY = widget.series
        .where((element) => element.type != SeriesType.noValue)
        .map((e) => e.max)
        .reduce((value, element) => max(value, element));
    minY = widget.series
        .where((element) => element.type != SeriesType.noValue)
        .map((e) => e.min)
        .reduce((value, element) => min(value, element));
    num maxSy;
    num minSy;
    if (widget.secondarySeries.isNotEmpty) {
      maxSy = widget.secondarySeries
          .map((e) => e.max)
          .reduce((value, element) => max(value, element));
      minSy = widget.secondarySeries
          .map((e) => e.min)
          .reduce((value, element) => min(value, element));
    }
    return Viewport(
      start: startTime,
      end: endTime,
      max: maxY,
      min: minY,
      secondaryMax: maxSy,
      secondaryMin: minSy,
    );
  }

  @override
  Widget build(BuildContext context) {
    chart = MyChartPainter(widget.series,
        viewport: viewport,
        secondarySeries: widget.secondarySeries,
        ranges: widget.ranges,
        title: widget.title,
        bgColor: widget.bgColor,
        showLegend: widget.showLegend,
        secondaryMeasureUnit: widget.secondaryMeasureUnit,
        measureUnit: widget.measureUnit,
        twoColLegend: widget.twoColLegend,
        selected: _selected);

    return Container(
      child: GestureDetector(
        onHorizontalDragUpdate: handleHorizontalDrag,
        onVerticalDragUpdate: handleVerticalDrag,
        onTapUp: handleTap,
        child: CustomPaint(
          child: Container(),
          painter: chart,
        ),
      ),
    );
  }

  void handleHorizontalDrag(DragUpdateDetails details) {
    if (!widget.pan) return;
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
      if ((startTime1.compareTo(minT) < 0) ||
          ((endTime1.compareTo(maxT) > 0))) {
        return;
      }
      startTime = startTime1;
      endTime = endTime1;

      viewport = viewport.copyWith(startTime, endTime);
    });
  }

  void handleVerticalDrag(DragUpdateDetails details) {
    if (!widget.zoom) return;
    final dd = details.primaryDelta;
    Duration duration;
    setState(() {
      if (viewport.step == Step.Minute) {
        duration = Duration(minutes: dd.floor());
      } else if (viewport.step == Step.Hour) {
        duration = Duration(minutes: dd.floor() * 15);
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

      viewport = viewport.copyWith(startTime, endTime);
    });
  }

  void handleTap(TapUpDetails details) {
    if (!widget.select) return;
    Map<Data, Offset> o = Map();
    chart.points.forEach((key, value) => o.addAll(value));
    var sel = o.entries.firstWhere(
        (element) => (element.value - details.localPosition).distance < 15.0,
        orElse: () => null);
    chart.selected.value = sel != null ? sel.key : null;
  }
}
