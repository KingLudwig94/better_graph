import 'dart:math';

import 'package:better_graph/series.dart';
import 'package:better_graph/viewport.dart';
import 'package:flutter/material.dart' hide Viewport, Step;
import 'package:intl/intl.dart' show DateFormat;
import 'package:in_date_utils/in_date_utils.dart';

class MyChartPainter extends CustomPainter {
  MyChartPainter(this.series, {Viewport viewport, this.ranges})
      : super(repaint: selected) {
    if (viewport != null) {
      Series show = series;
      int s = show.values.indexWhere((element) =>
          viewport.start != null ? element.time.isAfter(viewport.start) : true);
      int e = show.values.indexWhere((element) =>
          viewport.end != null ? !element.time.isBefore(viewport.end) : false);
      series = series.copyWith(
        values: series.values
            .getRange(
                s > 0 ? s - 1 : 0,
                e >= 0
                    ? e < series.values.length - 1
                        ? e + 1
                        : series.values.length
                    : series.values.length)
            .toList(),
      );
    }
    //TODO: fix no data in rangeX
    this.viewport = viewport ??
        Viewport(start: series.values.first.time, end: series.values.last.time);
  }

  static Map<Data, Offset> points;
  static ValueNotifier<Data> selected = ValueNotifier(null);
  List<Range> ranges;
  Viewport viewport;
  Series series;
  double chartW;
  double chartH;
  double yRatio;

  Paint chBorder;
  Paint dpPaint;
  Paint dpPaintFill;
  TextStyle titleStyle;
  TextStyle labelStyle;
  TextStyle legendStyle;

  @override
  void paint(Canvas canvas, Size size) {
    points = Map();
    chartW = size.width - 108;
    chartH = size.height - 108;
    viewport.xPerStep = chartW / viewport.stepCount;
    yRatio = (chartH / series.rangeY);

    var paint = Paint()..color = Colors.white;
    canvas.drawPaint(paint);
    var center = Offset(size.width / 2, size.height / 2);
    //drawFrame(canvas, center);
    drawChart(canvas, center);
  }

  void drawFrame(Canvas canvas, Offset center) {
    var w = 600.0;
    var rect = Rect.fromCenter(center: center, width: w, height: w);
    // fill rect
    var bg = Paint()..color = Color(0xfff2f3f0);
    canvas.drawRect(rect, bg);
    // draw border
    var border = Paint()
      ..color = Colors.black45
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, border);
  }

  void drawChart(Canvas canvas, Offset center) {
    chBorder = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    dpPaint = Paint()
      ..color = series.color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    dpPaintFill = Paint()
      ..color = series.color.withAlpha(30)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.fill;

    titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 40,
      fontWeight: FontWeight.w900,
    );
    labelStyle = TextStyle(
      color: Colors.black,
      fontSize: 13,
    );
    legendStyle = TextStyle(
      color: Colors.black,
      fontSize: 13,
    );

    var rect = Rect.fromCenter(center: center, width: chartW, height: chartH);
    // draw chart borders
    drawChartBorder(canvas, chBorder, rect);
    // draw data points
    drawDataPoints(canvas, dpPaint, rect);
    // draw chart guides
    drawChartGuides(canvas, chBorder, rect);
    // draw chart title
    drawText(canvas, rect.topLeft + Offset(0, -60), rect.width, titleStyle,
        "Weekly Data");
    drawLabels(canvas, rect, labelStyle);
    drawLegend(canvas, rect.bottomLeft + Offset(0, 30), legendStyle);
    drawRanges(canvas, rect);
  }

  void drawChartBorder(Canvas canvas, Paint chBorder, Rect rect) {
    canvas.drawRect(rect, chBorder);
  }

  void drawChartGuides(Canvas canvas, Paint chBorder, Rect rect) {
    var x = rect.left;
    for (var i = 0; i < viewport.stepCount; i++) {
      var p1 = Offset(x, rect.bottom);
      var p2 = Offset(x, rect.top);
      canvas.drawLine(p1, p2, chBorder);
      x += viewport.xPerStep;
    }

    // draw horizontal lines
    var yD = chartH / 3.0;
    canvas.drawLine(Offset(rect.left, rect.bottom - yD),
        Offset(rect.right, rect.bottom - yD), chBorder);
    canvas.drawLine(Offset(rect.left, rect.bottom - yD * 2),
        Offset(rect.right, rect.bottom - yD * 2), chBorder);
  }

  void drawDataPoints(Canvas canvas, dpPaint, Rect rect) {
    if (series == null && series.values.isNotEmpty) return;
    // this ratio is the number of y pixels per unit data
    var p = Path();
    var x = rect.left;

    bool first = true;
    var fraction;
    series.values.forEach((e) {
      var v = e.value;
      var d = e.time;

      // (v-minD) because we start our range at min value
      var y = (v - series.min) * yRatio; // * percentage; // for animation
      if (yRatio.isInfinite) y = chartH / 2;

      if (first) {
        fraction = _calculateFraction(d, viewport.start);
      } else
        fraction = _calculateFraction(
            d, series.values.elementAt(series.values.indexOf(e) - 1).time);
      x += viewport.xPerStep * fraction;

      if (first) {
        p.moveTo(x, rect.bottom - y);
        if (x - rect.left > 0) {
          _addPoint(rect, x, y, e);
        } else {
          var e1 = series.values[1];
          var x1 = x + viewport.xPerStep * _calculateFraction(e1.time, e.time);
          var y1 = e1.value;
          var m = (y1 - y) / (x1 - x);
          var q = y - m * x;
          var y0 = m * rect.left + q;
          //_drawPoint(canvas, rect, rect.left, y0);
          p.moveTo(rect.left, rect.bottom - y0);
        }
        first = false;
      } else {
        if (x - rect.right < 0) {
          _addPoint(rect, x, y, e);
          p.lineTo(x, rect.bottom - y);
        } else {
          var i = series.values.indexOf(e);
          var e1 = series.values[i - 1];
          var x1 = x + viewport.xPerStep * _calculateFraction(e1.time, e.time);
          var y1 = e1.value;
          var m = (y1 - y) / (x1 - x);
          var q = y - m * x;
          var y0 = m * rect.right + q;
          //_drawPoint(canvas, rect, rect.left, y0);
          p.lineTo(rect.right, rect.bottom - y0);
        }
      }
    });

    canvas.drawPath(p, dpPaint);
    if (series.fill) {
      p.lineTo(x, rect.bottom);
      p.lineTo(rect.left, rect.bottom);
      canvas.drawPath(p, dpPaintFill);
    }

    points.forEach(
        (key, value) => _drawPoint(canvas, rect, value.dx, value.dy, key));
  }

  double _calculateFraction(DateTime d, DateTime prev) {
    var diff = d.difference(prev);
    if (viewport.step == Step.Month) {
      return diff.inDays.toDouble() / DateUtils.getDaysInMonth(d.year, d.month);
    } else if (viewport.step == Step.Day) {
      return diff.inHours.toDouble() / 24;
    } else if (viewport.step == Step.Hour)
      return diff.inMinutes.toDouble() / 60;
    else {
      return diff.inSeconds.toDouble() / 60;
    }
  }

  _drawPoint(Canvas canvas, Rect rect, double x, double y, Data e) {
    canvas.drawCircle(
      Offset(x, y),
      e.isSame(selected?.value) ? 7 : 4,
      Paint()
        ..style = PaintingStyle.fill
        ..color = e.color ?? series.color,
    );
  }

  _addPoint(Rect rect, double x, double y, Data e) {
    points.putIfAbsent(e, () => Offset(x, rect.bottom - y));
  }

  drawText(Canvas canvas, Offset position, double width, TextStyle style,
      String text) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: width);
    textPainter.paint(canvas, position);
  }

  void drawLabels(Canvas canvas, Rect rect, TextStyle labelStyle) {
    // draw x Label
    var x = rect.left;
    String labelformat;
    if (viewport.step == Step.Day) {
      labelformat = DateFormat.Md().pattern;
    } else if (viewport.step == Step.Hour) {
      labelformat = DateFormat.Hm().pattern;
    } else if (viewport.step == Step.Minute) {
      labelformat = DateFormat.m().pattern;
    }

    List<String> labels;
    double xStep;
    int skip = 5;
    if (viewport.xPerStep < 30) {
      var t = List.from(viewport.steps);
      var temp = Map.fromIterable(t, key: (_) => t.indexOf(_), value: (_) => _)
        ..removeWhere((key, value) => key % skip != 0);
      labels = temp
          .map<int, String>(
              (_, e) => MapEntry(_, DateFormat(labelformat).format(e)))
          .values
          .toList();
      xStep = viewport.xPerStep * (skip);
    } else {
      labels =
          viewport.steps.map((e) => DateFormat(labelformat).format(e)).toList();
      xStep = viewport.xPerStep;
    }

    labels.forEach((element) {
      drawText(canvas, Offset(x - xStep / skip, rect.bottom + 10), xStep,
          labelStyle, element);
      x += xStep;
    });

    //draw y Label
    drawText(canvas, rect.bottomLeft + Offset(-25, -10), 40, labelStyle,
        series.min.toStringAsFixed(1)); // print min value
    drawText(canvas, rect.topLeft + Offset(-25, 0), 40, labelStyle,
        series.max.toStringAsFixed(1)); // print max value
  }

  void drawLegend(Canvas canvas, Offset offset, TextStyle legendStyle) {
    if (selected.value == null) return;
    //TODO: cancellare se variano i dati
    drawText(canvas, offset, double.maxFinite, legendStyle,
        series.name + ': ' + selected.value.toString());
  }

  void drawRanges(Canvas canvas, Rect rect) {
    ranges.forEach((element) {
      Paint paint = Paint()
        ..color = element.color.withOpacity(.5)
        ..style = PaintingStyle.fill;
      double top = element.top != null
          ? rect.bottom - (element.top - series.min) * yRatio
          : rect.top;
      double bottom = element.bottom != null
          ? rect.bottom - (element.bottom - series.min) * yRatio
          : rect.bottom;
      double left = element.start != null
          ? rect.left +
              _calculateFraction(element.start, viewport.start) *
                  viewport.xPerStep
          : rect.left;
      double right = element.end != null
          ? rect.left +
              _calculateFraction(element.end, viewport.start) *
                  viewport.xPerStep
          : rect.right;
      Rect r = Rect.fromLTRB(
          left > rect.left ? left : rect.left,
          top < rect.top
              ? rect.top
              : top < rect.bottom
                  ? top
                  : rect.bottom,
          right > rect.right
              ? rect.right
              : right < rect.left
                  ? rect.left
                  : right,
          bottom > rect.bottom ? rect.bottom : bottom);
      canvas.drawRect(r, paint);
    });
  }

  @override
  bool shouldRepaint(MyChartPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(MyChartPainter oldDelegate) => false;
}
