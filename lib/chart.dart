import 'dart:math';

import 'package:better_graph/chartPainter.dart';
import 'package:better_graph/series.dart';
import 'package:better_graph/viewport.dart';
import 'package:flutter/material.dart' hide Viewport, Step;

class Chart extends StatefulWidget {
  Chart({
    /// list of [Series] to plot
    required this.seriesList,

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
    this.zoom = false,

    /// whether to allow selection gesture
    this.select = true,

    /// whether to have the legend on two colums
    this.twoColLegend = true,

    /// widget to show selected data point info
    Widget Function(Data data, Series series)? tooltip,

    /// wheter to show the tooltip on data selection
    this.showTooltip = false,
    this.leftMargin = 54,
    this.rightMargin = 54,
    this.topMargin = 54,
    this.bottomMargin = 54,
    Key? key,
  })  : series = seriesList.where((e) => !e.secondaryAxis).toList(),
        secondarySeries =
            seriesList.where((element) => element.secondaryAxis).toList(),
        this.tooltip = tooltip ??
            ((data, series) {
              return Container(
                /*  width: 100,
                height: 50, */
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.black, width: 1)),
                child: Text(series.name + ': ' + data.toString()),
              );
            }),
        super(key: key);
  final List<Series> series;
  final List<Series> secondarySeries;
  final List<Series> seriesList;
  final Viewport? viewport;
  final List<Range>? ranges;
  final String? title;
  final Color? bgColor;
  final bool showLegend;
  final String? measureUnit;
  final String? secondaryMeasureUnit;
  final bool zoom;
  final bool pan;
  final bool select;
  final bool twoColLegend;
  final bool showTooltip;
  final Widget Function(Data data, Series series) tooltip;
  final double? leftMargin;
  final double? rightMargin;
  final double? topMargin;
  final double? bottomMargin;
  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  late DateTime startTime;
  late DateTime endTime;
  late Viewport viewport;
  Viewport? secondaryViewport;
  late DateTime minT;
  late DateTime maxT;
  late Duration rangeX;
  num maxY = 0;
  num minY = 0;
  MyChartPainter? chart;
  late ValueNotifier<Data?> _selected = ValueNotifier(null);
  late Offset _tapOffset;

  @override
  void initState() {
    viewport = calculateViewport();
    super.initState();
  }

  Viewport calculateViewport() {
    minT = widget.seriesList.map((e) => e.start).reduce(
        (value, element) => value.compareTo(element) < 0 ? value : element);
    startTime = widget.viewport?.start ?? minT;
    maxT = widget.seriesList.map((e) => e.end).reduce(
        (value, element) => value.compareTo(element) > 0 ? value : element);
    endTime = widget.viewport?.end ?? maxT;
    rangeX = maxT.difference(minT);

    if (widget.series.isNotEmpty) {
      maxY = widget.series
          .where((element) => element.type != SeriesType.noValue)
          .map((e) => e.max)
          .reduce((value, element) => max(value, element));
      minY = widget.series
          .where((element) => element.type != SeriesType.noValue)
          .map((e) => e.min)
          .reduce((value, element) => min(value, element));
    }
    num? maxSy;
    num? minSy;
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
      max: widget.viewport?.max ?? maxY,
      min: widget.viewport?.min ?? minY,
      secondaryMax: widget.viewport?.secondaryMax ?? maxSy,
      secondaryMin: widget.viewport?.secondaryMin ?? minSy,
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
        selected: _selected,
        leftMargin: widget.leftMargin!,
        rightMargin: widget.rightMargin!,
        topMargin: widget.topMargin!,
        bottomMargin: widget.bottomMargin!);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Stack(
        children: [
          Container(
            constraints: constraints,
            child: GestureDetector(
              onHorizontalDragUpdate: handleHorizontalDrag,
              onVerticalDragUpdate: handleVerticalDrag,
              onTapUp: handleTap,
              child: CustomPaint(
                painter: chart,
              ),
            ),
          ),
          if (widget.showTooltip && _selected.value != null)
            _tooltip(constraints),
        ],
      );
    });
  }

  void handleHorizontalDrag(DragUpdateDetails details) {
    if (!widget.pan) return;
    final dd = details.primaryDelta;
    late Duration duration;
    setState(() {
      if (viewport.step == Step.Minute) {
        duration = Duration(minutes: dd!.floor());
      } else if (viewport.step == Step.Hour) {
        duration = Duration(minutes: dd!.floor() * 30);
      } else if (viewport.step == Step.Day) {
        duration = Duration(hours: dd!.floor() * 12);
      }
      var startTime1 = startTime.subtract(duration);
      var endTime1 = endTime.subtract(duration);
      if ((startTime1.compareTo(minT) < 0) ||
          ((endTime1.compareTo(maxT) > 0))) {
        return;
      }
      startTime = startTime1;
      endTime = endTime1;
      _selected.value = null;
      viewport = viewport.copyWith(start: startTime, end: endTime);
    });
  }

  void handleVerticalDrag(DragUpdateDetails details) {
    if (!widget.zoom) return;
    final dd = details.primaryDelta;
    late Duration duration;
    setState(() {
      if (viewport.step == Step.Minute) {
        duration = Duration(minutes: dd!.floor());
      } else if (viewport.step == Step.Hour) {
        duration = Duration(minutes: dd!.floor() * 15);
      } else if (viewport.step == Step.Day) {
        duration = Duration(hours: dd!.floor() * 12);
      }

      var startTime1 = startTime.subtract(duration);
      var endTime1 = endTime.add(duration);
      if (endTime1.difference(startTime1).compareTo(rangeX) > 0)
        // max out
        return;
/*       if (dd > 0 &&
          chart.points.values.any((element) =>
              element.length ==
              widget.seriesList
                      .map((e) => e.values.length)
                      .reduce((value, element) => max(value, element)) +
                  1)) return; */

      if (dd! < 0 &&
          chart!.points.values.every((element) => element.length < 3)) return;

      startTime = startTime1;
      endTime = endTime1;
      _selected.value = null;
      viewport = viewport.copyWith(start: startTime, end: endTime);
    });
  }

  void handleTap(TapUpDetails details) {
    if (!widget.select) return;
    Map<Data, Offset> o = Map();
    chart!.points.forEach((key, value) => o.addAll(value));
    var selList = o.entries
        .map((e) => MapEntry<MapEntry<Data, Offset>, double>(
            e, (e.value - details.localPosition).distance))
        .where(
          (element) => element.value < 15.0,
        )
        .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    if (selList.isNotEmpty) {
      var sel = selList.first.key;
      setState(() {
        _tapOffset = sel.value;
        chart!.selected!.value = sel.key;
      });
    } else {
      setState(() {
        chart!.selected!.value = null;
      });
    }
  }

  Widget _tooltip(BoxConstraints constraints) {
    double? top;
    double? bottom;
    double? left;
    double? right;
    if (_tapOffset.dy < constraints.maxHeight / 2)
      top = _tapOffset.dy;
    else
      bottom = constraints.maxHeight - _tapOffset.dy;
    if (_tapOffset.dx < constraints.maxWidth / 2)
      left = _tapOffset.dx;
    else
      right = constraints.maxWidth - _tapOffset.dx;

    return Positioned(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ConstrainedBox(
            constraints: BoxConstraints.loose(Size(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            )),
            child: widget.tooltip(
                _selected.value!,
                widget.seriesList
                    .where((a) => a.values.contains(_selected.value))
                    .first)),
      ),
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
  }
}
