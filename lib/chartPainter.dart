import 'package:better_graph/series.dart';
import 'package:better_graph/viewport.dart';
import 'package:flutter/material.dart' hide Viewport, Step;
import 'package:intl/intl.dart' show DateFormat;
import 'package:in_date_utils/in_date_utils.dart';

class MyChartPainter extends CustomPainter {
  MyChartPainter(this.series, {Viewport viewport}) {
    if (viewport != null) {
      Series show = series;
      int s = show.values.indexWhere((element) =>
          viewport.start != null ? element.time.isAfter(viewport.start) : true);
      int e = show.values.indexWhere((element) =>
          viewport.end != null ? !element.time.isBefore(viewport.end) : false);
      series = Series(
          series.values
              .getRange(
                  s > 0 ? s - 1 : 0,
                  e >= 0
                      ? e < series.values.length - 1
                          ? e + 1
                          : series.values.length
                      : series.values.length)
              .toList(),
          series.name);
    }
    //TODO: fix no data in rangeX
    this.viewport = viewport ??
        Viewport(start: series.values.first.time, end: series.values.last.time);
  }

  Viewport viewport;
  Series series;
  double chartW;
  double chartH;

  @override
  void paint(Canvas canvas, Size size) {
    chartW = size.width - 108;
    chartH = size.height - 108;
    viewport.xPerStep = chartW / viewport.stepCount;

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
    var rect = Rect.fromCenter(center: center, width: chartW, height: chartH);
    var chBorder = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    var dpPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    var titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 40,
      fontWeight: FontWeight.w900,
    );
    var labelStyle = TextStyle(
      color: Colors.black,
      fontSize: 13,
    );
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
    var yRatio = (chartH / series.rangeY);
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
          _drawPoint(canvas, rect, x, y);
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
          p.lineTo(x, rect.bottom - y);
          _drawPoint(canvas, rect, x, y);
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

    p.moveTo(x - viewport.xPerStep, rect.bottom);
    p.moveTo(rect.left, rect.bottom);
    canvas.drawPath(p, dpPaint);
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

  _drawPoint(Canvas canvas, Rect rect, double x, double y) {
    canvas.drawCircle(
      Offset(x, rect.bottom - y),
      4,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.green,
    );
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
    if (viewport.step == Step.Hour) {
      labelformat = DateFormat.Hm().pattern;
    } else if (viewport.step == Step.Minute) {
      labelformat = DateFormat.m().pattern;
    }
    for (var i = 0; i < viewport.steps.length; i++) {
      drawText(canvas, Offset(x, rect.bottom + 10), viewport.xPerStep,
          labelStyle, DateFormat(labelformat).format(viewport.steps[i]));
      x += viewport.xPerStep;
    }
    /* drawText(canvas, Offset(x - 20, rect.bottom + 10), 40, labelStyle,
        DateFormat.Hm().format(viewport.start));
    drawText(canvas, Offset(rect.right - 20, rect.bottom + 10), 40, labelStyle,
        DateFormat.Hm().format(viewport.end)); */

    //draw y Label
    drawText(canvas, rect.bottomLeft + Offset(-25, -10), 40, labelStyle,
        series.min.toStringAsFixed(1)); // print min value
    drawText(canvas, rect.topLeft + Offset(-25, 0), 40, labelStyle,
        series.max.toStringAsFixed(1)); // print max value
  }

  @override
  bool shouldRepaint(MyChartPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(MyChartPainter oldDelegate) => false;
}
