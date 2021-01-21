import 'package:better_graph/series.dart';
import 'package:better_graph/viewport.dart';
import 'package:flutter/material.dart' hide Viewport, Step;
import 'package:intl/intl.dart' show DateFormat;
import 'package:in_date_utils/in_date_utils.dart';

class MyChartPainter extends CustomPainter {
  MyChartPainter(
    this.seriesList, {
    this.viewport,
    this.ranges,
    this.secondarySeries,
    this.title,
    this.bgColor,
    this.showLegend,
    this.selected,
    this.measureUnit,
    this.secondaryMeasureUnit,
    this.twoColLegend,
  }) : super(repaint: selected) {
    seriesList = seriesList.map((series) {
      Series show = series;
      int s = show.values.indexWhere((element) =>
          viewport.start != null ? element.time.isAfter(viewport.start) : true);
      int e = show.values.indexWhere((element) =>
          viewport.end != null ? !element.time.isBefore(viewport.end) : false);
      return series = series.copyWith(
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
    }).toList();
    secondarySeries = secondarySeries.map((series) {
      Series show = series;
      int s = show.values.indexWhere((element) =>
          viewport.start != null ? element.time.isAfter(viewport.start) : true);
      int e = show.values.indexWhere((element) =>
          viewport.end != null ? !element.time.isBefore(viewport.end) : false);
      return series = series.copyWith(
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
    }).toList();
    _setLabelFormat();
    //TODO: fix no data in rangeX
  }

  Map<String, Map<Data, Offset>> points;
  ValueNotifier<Data> selected;
  List<Range> ranges;
  Viewport viewport;
  List<Series> seriesList;
  List<Series> secondarySeries;
  double chartW;
  double chartH;
  double yRatio;
  double yRatioSecondary;

  bool showLegend;
  bool twoColLegend;
  Color bgColor;
  Paint chBorder;
  Paint chBg;
  Paint dpPaint;
  Paint dpPaintFill;
  TextStyle titleStyle;
  TextStyle labelStyle;
  TextStyle legendStyle;
  double labelOffset;
  double offsetStep = 14.0;
  double legendOffset;
  String labelFormat;
  String title;
  String measureUnit;
  String secondaryMeasureUnit;

  @override
  void paint(Canvas canvas, Size size) {
    labelOffset = 7.0;
    points = Map();
    chartW = size.width - 108;
    chartH = size.height - 108;

    viewport.xPerStep = chartW / viewport.stepCount;
    yRatio = (chartH / viewport.rangeY);
    if (secondarySeries.isNotEmpty) {
      yRatioSecondary = (chartH / viewport.secondaryRangeY);
    }

    var center =
        Offset(size.width / 2, size.height / 2 - (title == null ? 25 : 15));
    //drawFrame(canvas, center, size);
    drawChart(canvas, center);
  }

  void drawFrame(Canvas canvas, Offset center, Size size) {
    var w = 600.0;
    var rect =
        Rect.fromCenter(center: center, width: size.width, height: size.height);
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
    chBg = Paint()..color = bgColor ?? Colors.white;

    titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 25,
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
    // draw background
    canvas.drawRect(rect, chBg);
    // draw chart borders
    drawChartBorder(canvas, chBorder, rect);
    // draw chart guides
    drawChartGuides(canvas, chBorder, rect);
    // draw chart title
    drawText(
        canvas, rect.topLeft + Offset(0, -40), rect.width, titleStyle, title);
    drawRanges(canvas, rect);

    seriesList.forEach((series) {
      points[series.name] = {};
      dpPaint = Paint()
        ..color = series.color
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      dpPaintFill = Paint()
        ..color = series.color.withAlpha(30)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.fill;
      if (series.type == SeriesType.noValue)
        //draw novalue data
        drawNoValPoints(canvas, dpPaint, rect, series);
      else
        // draw data points
        drawDataPoints(canvas, dpPaint, rect, series);
    });
    if (secondarySeries.isNotEmpty)
      secondarySeries.forEach((series) {
        points[series.name] = {};
        dpPaint = Paint()
          ..color = series.color
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

        dpPaintFill = Paint()
          ..color = series.color.withAlpha(30)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.fill;
        /*  if (series.type == SeriesType.noValue)
          //draw novalue data
          drawNoValPoints(canvas, dpPaint, rect, series);
        else */
        // draw data points
        drawDataPoints(canvas, dpPaint, rect, series);
      });
    // draw labels
    drawXLabels(canvas, rect, labelStyle);
    drawYLabels(canvas, rect, labelStyle);
    if (secondarySeries.isNotEmpty)
      drawSecondaryYLabels(canvas, rect, labelStyle);
    if (showLegend) drawLegend(canvas, rect, legendStyle);
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

  void drawDataPoints(Canvas canvas, dpPaint, Rect rect, Series series) {
    if (series == null && series.values.isNotEmpty) return;
    // this ratio is the number of y pixels per unit data
    var p = Path();
    var x = rect.left;
    var firstX = x;

    bool first = true;
    var fraction;
    series.values.forEach((e) {
      var v = e.value;
      var d = e.time;

      // (v-minD) because we start our range at min value
      num y;
      if (series.secondaryAxis) {
        y = (v - viewport.secondaryMin) * yRatioSecondary;
      } else {
        y = (v - viewport.min) * yRatio; // * percentage; // for animation
      }
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
          if (series.type == SeriesType.stem) p.lineTo(x, rect.bottom);
          _addPoint(rect, x, y, e, series.name);
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
        firstX = x;
        first = false;
      } else {
        if (x - rect.right < 0) {
          _addPoint(rect, x, y, e, series.name);
          if (series.type == SeriesType.line)
            p.lineTo(x, rect.bottom - y);
          else if (series.type == SeriesType.stem) {
            p.moveTo(x, rect.bottom - y);
            p.lineTo(x, rect.bottom);
          }
        } else {
          var i = series.values.indexOf(e);
          var e1 = series.values[i - 1];
          var x1 = x + viewport.xPerStep * _calculateFraction(e1.time, e.time);
          var y1 = e1.value;
          var m = (y1 - y) / (x1 - x);
          var q = y - m * x;
          var y0 = m * rect.right + q;
          //_drawPoint(canvas, rect, rect.left, y0);
          if (series.type == SeriesType.line)
            p.lineTo(rect.right, rect.bottom - y0);
        }
      }
    });

    canvas.drawPath(p, dpPaint);
    if (series.fill) {
      p.lineTo(x < rect.right ? x : rect.right, rect.bottom);
      p.lineTo(firstX > rect.left ? firstX : rect.left, rect.bottom);
      canvas.drawPath(p, dpPaintFill);
    }

    points[series.name].forEach((key, value) =>
        _drawPoint(canvas, rect, value.dx, value.dy, key, series));
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

  _drawPoint(
      Canvas canvas, Rect rect, double x, double y, Data e, Series series) {
    canvas.drawCircle(
      Offset(x, y),
      e.isSame(selected?.value) ? 7 : 4,
      Paint()
        ..style = PaintingStyle.fill
        ..color = e.color ?? series.color,
    );
  }

  _addPoint(Rect rect, double x, double y, Data e, String sName) {
    points[sName].putIfAbsent(e, () => Offset(x, rect.bottom - y));
  }

  drawText(Canvas canvas, Offset position, double width, TextStyle style,
      String text) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: width);
    textPainter.paint(canvas, position);
  }

  void _setLabelFormat() {
    if (viewport.step == Step.Day) {
      labelFormat = DateFormat.Md().pattern;
    } else if (viewport.step == Step.Hour) {
      labelFormat = DateFormat.Hm().pattern;
    } else if (viewport.step == Step.Minute) {
      labelFormat = DateFormat.m().pattern;
    }
  }

  void drawXLabels(Canvas canvas, Rect rect, TextStyle labelStyle) {
    // draw x Label
    var x = rect.left;

    List<String> labels;
    double xStep;
    int skip = 5;
    if (viewport.xPerStep < 30) {
      var t = List.from(viewport.steps);
      var temp = Map.fromIterable(t, key: (_) => t.indexOf(_), value: (_) => _)
        ..removeWhere((key, value) => key % skip != 0);
      labels = temp
          .map<int, String>(
              (_, e) => MapEntry(_, DateFormat(labelFormat).format(e)))
          .values
          .toList();
      xStep = viewport.xPerStep * (skip);
    } else {
      labels =
          viewport.steps.map((e) => DateFormat(labelFormat).format(e)).toList();
      xStep = viewport.xPerStep;
    }
    if (xStep >= 0)
      labels.forEach((element) {
        canvas.drawLine(
            Offset(x - xStep / skip + xStep / skip, rect.bottom + labelOffset),
            Offset(x - xStep / skip + xStep / skip, rect.bottom + 2),
            Paint());
        drawText(canvas, Offset(x - xStep / skip, rect.bottom + labelOffset),
            xStep, labelStyle, element);
        x += xStep;
      });
  }

  void drawYLabels(Canvas canvas, Rect rect, TextStyle labelStyle) {
    Offset posTop = rect.topLeft + Offset(-40, 0);
    Offset posBottom = rect.bottomLeft + Offset(-40, -10);
    //draw y Label
    drawText(canvas, posBottom, 40, labelStyle,
        viewport.min.toStringAsFixed(2)); // print min value
    drawText(canvas, posTop, 40, labelStyle,
        viewport.max.toStringAsFixed(2)); // print max value
    if (measureUnit != null)
      drawText(canvas, posTop + Offset(0, -20), 40, labelStyle, measureUnit);
  }

  void drawSecondaryYLabels(
    Canvas canvas,
    Rect rect,
    TextStyle labelStyle,
  ) {
    Offset posTop = rect.topRight + Offset(10, 0);
    Offset posBottom = rect.bottomRight + Offset(10, -10);
    //draw y Label
    drawText(canvas, posBottom, 40, labelStyle,
        viewport.secondaryMin.toStringAsFixed(2)); // print min value
    drawText(canvas, posTop, 40, labelStyle,
        viewport.secondaryMax.toStringAsFixed(2)); // print max value
    if (secondaryMeasureUnit != null)
      drawText(canvas, posTop + Offset(0, -20), 40, labelStyle,
          secondaryMeasureUnit);
  }

  void drawLegend(Canvas canvas, Rect rect, TextStyle legendStyle) {
    int i = 1;
    bool col0 = true;
    int nS = seriesList.length + secondarySeries.length;
    List<Series> merge = List.from(seriesList)..addAll(secondarySeries);
    merge.forEach((element) {
      double x = col0 ? 0 : 4 / 5 * rect.bottomCenter.dx;
      double y = col0
          ? labelOffset + offsetStep / 2 + offsetStep * i
          : labelOffset + offsetStep / 2 + offsetStep * i;
      canvas.drawRect(
          Rect.fromCenter(
              center: rect.bottomLeft + Offset(x, y), width: 10, height: 10),
          Paint()..color = element.color);
      drawText(
          canvas,
          rect.bottomLeft + Offset(x + 10, y - offsetStep / 2),
          double.maxFinite,
          legendStyle,
          element.name +
              (element.values.contains(selected.value)
                  ? ': ' + selected.value.toString()
                  : ''));
      i++;
      if (!(i < nS / 2 + 1)) {
        col0 = false;
        i = 1;
      }
    });
  }

  void drawRanges(Canvas canvas, Rect rect) {
    if (ranges == null) return;
    ranges.forEach((element) {
      Paint paint = Paint()
        ..color = element.color.withOpacity(.5)
        ..style = PaintingStyle.fill;
      double top = element.top != null
          ? rect.bottom - (element.top - viewport.min) * yRatio
          : rect.top;
      double bottom = element.bottom != null
          ? rect.bottom - (element.bottom - viewport.min) * yRatio
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
      if (element.xLabel) {
        if (left > rect.left) {
          canvas.drawLine(
              Offset(left, rect.top), Offset(left, rect.top - 15), Paint());
          drawText(canvas, Offset(left + 2, rect.top - 15), 40, labelStyle,
              DateFormat(labelFormat).format(element.start));
        }
        if (right < rect.right) {
          canvas.drawLine(Offset(right - 1, rect.top),
              Offset(right - 1, rect.top - 15), Paint());
          drawText(canvas, Offset(right - 36, rect.top - 15), 40, labelStyle,
              DateFormat(labelFormat).format(element.end));
        }
      }
      if (element.yLabel) {
        if (bottom < rect.bottom - 15) {
          canvas.drawLine(Offset(rect.left, bottom),
              Offset(rect.left - 10, bottom), Paint());
          drawText(
              canvas,
              Offset(rect.left - 40, bottom - labelStyle.fontSize / 2),
              40,
              labelStyle,
              element.bottom.toStringAsFixed(2));
        }
        if (top > rect.top) {
          canvas.drawLine(
              Offset(rect.left, top), Offset(rect.left - 10, top), Paint());
          drawText(
              canvas,
              Offset(rect.left - 40, top - labelStyle.fontSize / 2),
              40,
              labelStyle,
              element.top.toStringAsFixed(2));
        }
      }
    });
  }

  @override
  bool shouldRepaint(MyChartPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(MyChartPainter oldDelegate) => false;

  void drawNoValPoints(Canvas canvas, Paint dpPaint, Rect rect, Series series) {
    if (series == null) return;
    double offset = labelOffset;
    labelOffset += offsetStep;
    var fraction;
    var x = rect.left;
    bool first = true;
    series.values.forEach((e) {
      var d = e.time;
      if (first) {
        fraction = _calculateFraction(d, viewport.start);
        first = false;
      } else
        fraction = _calculateFraction(
            d, series.values.elementAt(series.values.indexOf(e) - 1).time);
      x += viewport.xPerStep * fraction;
      if (x - rect.right < 0 && x - rect.left > 0)
        _addPoint(rect, x, -offset, e, series.name);
    });
    points[series.name].forEach((key, value) =>
        _drawPoint(canvas, rect, value.dx, rect.bottom + offset, key, series));
    canvas.drawLine(Offset(rect.left, rect.bottom + offset + 7),
        Offset(rect.right, rect.bottom + offset + 7), Paint());
  }
}
