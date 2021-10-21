import 'dart:math';
import 'dart:ui';

import 'package:better_graph/src/series.dart';
import 'package:better_graph/src/viewport.dart';
import 'package:flutter/material.dart' hide Viewport, Step;
import 'package:intl/intl.dart' show DateFormat;
// import 'package:in_date_utils/in_date_utils.dart';

class MyChartPainter extends CustomPainter {
  MyChartPainter(
    this.seriesList, {
    required this.viewport,
    this.ranges,
    this.secondarySeries,
    this.title,
    this.bgColor,
    required this.showLegend,
    this.selected,
    this.measureUnit,
    this.secondaryMeasureUnit,
    this.leftMargin = 54,
    this.rightMargin = 54,
    this.bottomMargin = 54,
    this.topMargin = 54,
    this.yLabels,
    this.maxCharsAxisLabel,
    required this.twoColLegend,
  }) : super(repaint: selected) {
    seriesList = seriesList.map((series) {
      Series show = series;
      int s = show.values.indexWhere((element) => viewport.start != null
          ? element.time.isAfter(viewport.start!)
          : true);
      int e = show.values.indexWhere((element) =>
          viewport.end != null ? !element.time.isBefore(viewport.end!) : false);
      List<Data>? low;
      if (series.lowerLimit != null)
        low = series.lowerLimit!
            .getRange(
                s > 0 ? s - 1 : 0,
                e >= 0
                    ? e < series.values.length - 1
                        ? e + 1
                        : series.values.length
                    : series.values.length)
            .toList();
      return s == -1 && e == -1
          ? series.copyWith(values: [])
          : series.copyWith(
              values: series.values
                  .getRange(
                      s > 0 ? s - 1 : 0,
                      e >= 0
                          ? e < series.values.length - 1
                              ? e + 1
                              : series.values.length
                          : series.values.length)
                  .toList(),
              lowerLimit: low,
            );
    }).toList();
    insideNoValSeries = seriesList
        .where((element) => element.type == SeriesType.noValueInside)
        .toList();
    seriesList = seriesList
        .where((element) => element.type != SeriesType.noValueInside)
        .toList();
    secondarySeries = secondarySeries!.map((series) {
      Series show = series;
      int s = show.values.indexWhere((element) => viewport.start != null
          ? element.time.isAfter(viewport.start!)
          : true);
      int e = show.values.indexWhere((element) =>
          viewport.end != null ? !element.time.isBefore(viewport.end!) : false);
      return s == -1 && e == -1
          ? series.copyWith(values: [])
          : series.copyWith(
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
    double sumSecX = secondaryMeasureUnit!.values
            .map((value) => measureText(value, labelStyle, 100) + 5)
            .reduce((value, element) => value + element) +
        10;
    rightMargin = max(sumSecX, rightMargin);
    if (ranges != null)
      ranges = ranges!
          .where((range) => (!((range.start!.isBefore(viewport.start!) &&
                  range.end!.isBefore(viewport.start!)) ||
              (range.start!.isAfter(viewport.end!) &&
                  range.end!.isAfter(viewport.end!)))))
          .map((range) {
        return range.copyWith(
            start:
                range.start!.isBefore(viewport.start!) ? viewport.start! : null,
            end: range.end!.isAfter(viewport.end!) ? viewport.end! : null);
      }).toList();
    _setLabelFormat();
    //TODO: fix no data in rangeX
  }

  late Map<String, Map<Data, Offset>> points;
  ValueNotifier<Data?>? selected;
  List<Range>? ranges;
  Viewport viewport;
  List<Series> seriesList;
  List<Series>? secondarySeries;
  late List<Series> insideNoValSeries;
  late double chartW;
  late double chartH;
  late double yRatio;
  Map<String, double> yRatioSecondary = {};
  List<num>? yLabels;

  bool showLegend;
  bool twoColLegend;
  Color? bgColor;
  late Paint chBorder;
  late Paint chBg;
  late Paint dpPaint;
  late Paint dpPaintFill;
  final double leftMargin;
  double rightMargin;
  final double topMargin;
  final double bottomMargin;

  Paint dpTransparent = Paint()..color = Colors.transparent;
  TextStyle titleStyle = TextStyle(
    color: Colors.black,
    fontSize: 25,
    fontWeight: FontWeight.w900,
  );
  TextStyle labelStyle = TextStyle(
    color: Colors.black,
    fontSize: 13,
  );
  TextStyle legendStyle = TextStyle(
    color: Colors.black,
    fontSize: 13,
  );
  late double labelOffset;
  double offsetStep = 14.0;
  double insideNoValOffset = -7.0;
  late String? labelFormat;
  String? title;
  String? measureUnit;
  Map<String, String>? secondaryMeasureUnit;
  int? maxCharsAxisLabel;

  @override
  void paint(Canvas canvas, Size size) {
    labelOffset = 7.0;
    points = Map();
    chartW = size.width -
        (leftMargin + (secondarySeries!.isNotEmpty ? rightMargin : 20));
    chartH = size.height - (topMargin + bottomMargin);

    viewport.xPerStep = chartW / viewport.stepCount;
    yRatio = (chartH / viewport.rangeY);
    if (secondarySeries!.isNotEmpty) {
      secondarySeries!.forEach((value) {
        yRatioSecondary[value.name] =
            chartH / viewport.secondaryRangeY[value.name]!;
      });
    }

    var center =
        Offset(size.width / 2, size.height / 2 - (title == null ? 25 : 15));
    //drawFrame(canvas, center, size);
    drawChart(canvas, center);
  }

/*   void drawFrame(Canvas canvas, Offset center, Size size) {
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
  } */

  void drawChart(Canvas canvas, Offset center) {
    chBorder = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    chBg = Paint()..color = bgColor ?? Colors.white;

    var rect = Rect.fromLTWH(leftMargin, topMargin, chartW, chartH);
    // draw background
    canvas.drawRect(rect, chBg);
    // draw chart borders
    drawChartBorder(canvas, chBorder, rect);
    // draw chart guides
    drawChartGuides(canvas, chBorder, rect);
    // draw chart title
    if (title != null)
      drawText(canvas, rect.topLeft + Offset(0, -40), rect.width, titleStyle,
          title!);
    drawRanges(canvas, rect);

    if (secondarySeries!.isNotEmpty)
      secondarySeries!.forEach((series) {
        points[series.name] = {};
        dpPaint = Paint()
          ..color = series.color
          ..strokeWidth = series.drawSize
          ..style = PaintingStyle.stroke;

        dpPaintFill = Paint()
          ..color = series.color.withAlpha(30)
          ..strokeWidth = series.drawSize
          ..style = PaintingStyle.fill;
        /*  if (series.type == SeriesType.noValue)
          //draw novalue data
          drawNoValPoints(canvas, dpPaint, rect, series);
        else */
        // draw data points
        drawDataPoints(canvas, dpPaint, rect, series);
      });
    seriesList.forEach((series) {
      points[series.name] = {};
      dpPaint = Paint()
        ..color = series.color
        ..strokeWidth = series.drawSize
        ..style = PaintingStyle.stroke;

      dpPaintFill = Paint()
        ..color = series.fillColor ?? series.color.withAlpha(30)
        ..strokeWidth = series.drawSize
        ..style = PaintingStyle.fill;
      if (series.type == SeriesType.noValue)
        //draw novalue data
        drawNoValPoints(canvas, dpPaint, rect, series);
      // draw data points
      drawDataPoints(canvas, dpPaint, rect, series);

      if (insideNoValSeries.isNotEmpty)
        drawNoValInsidePoints(canvas, rect, insideNoValSeries);
    });
    // draw labels
    drawXLabels(canvas, rect, labelStyle);
    drawYLabels(canvas, rect, labelStyle);
    if (secondarySeries!.isNotEmpty)
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
      x += viewport.xPerStep!;
    }

    // draw horizontal lines
    if (yLabels != null && yLabels!.isNotEmpty) {
      yLabels!.forEach((element) {
        var y = (element - viewport.min!) * yRatio;
        canvas.drawLine(Offset(rect.left, rect.bottom - y),
            Offset(rect.right, rect.bottom - y), chBorder);
      });
    }
    /* 
    var yD = chartH / 3.0;
    canvas.drawLine(Offset(rect.left, rect.bottom - yD),
        Offset(rect.right, rect.bottom - yD), chBorder);
    canvas.drawLine(Offset(rect.left, rect.bottom - yD * 2),
        Offset(rect.right, rect.bottom - yD * 2), chBorder); */
  }

  void drawDataPoints(Canvas canvas, dpPaint, Rect rect, Series series) {
    if (series.values.isEmpty) return;
    // this ratio is the number of y pixels per unit data
    var p = Path();
    var x = rect.left;
    var firstX = x;
    late var firstY;
    List<Data>? low;
    if (series.lowerLimit != null) low = series.lowerLimit!.reversed.toList();

    var lowPath = Path();
    bool first = true;
    var fraction;
    series.values.forEach((e) {
      var v = e.value;
      var d = e.time;

      // (v-minD) because we start our range at min value
      num y;
      if (series.secondaryAxis) {
        y = (v - viewport.secondaryMin![series.name]!) *
            yRatioSecondary[series.name]!;
      } else {
        y = (v - viewport.min!) * yRatio; // * percentage; // for animation
      }
      if (yRatio.isInfinite) y = chartH / 2;
      if (first) firstY = y;
      if (first) {
        fraction = _calculateFraction(d, viewport.start!);
      } else
        fraction = _calculateFraction(
            d, series.values.elementAt(series.values.indexOf(e) - 1).time);
      x += viewport.xPerStep! * fraction;

// fuori dal grafico
      if (first) {
        p.moveTo(x, rect.bottom - y);
        if (x - rect.left > 0) {
          if (series.type == SeriesType.stem ||
              series.type == SeriesType.stemNoPoint) p.lineTo(x, rect.bottom);
          if (series.type != SeriesType.stemNoPoint)
            _addPoint(rect, x, y as double, e, series.name);
        } else {
          var e1 = series.values[1];
          var x1 = x + viewport.xPerStep! * _calculateFraction(e1.time, e.time);
          var y1 = (e1.value - viewport.min!) * yRatio;
          var m = (y1 - y) / (x1 - x);
          num q = y - m * x;
          var y0 = m * rect.left + q;
          //_drawPoint(canvas, rect, rect.left, y0);
          p.moveTo(rect.left, rect.bottom - y0);
        }
        firstX = x;
        first = false;
      } else {
        if (x - rect.right < 0) {
          if (series.type != SeriesType.stemNoPoint)
            _addPoint(rect, x, y as double, e, series.name);
          if (series.type == SeriesType.line ||
              series.type == SeriesType.lineNoPoint)
            p.lineTo(x, rect.bottom - y);
          else if (series.type == SeriesType.stem ||
              series.type == SeriesType.stemNoPoint) {
            p.moveTo(x, rect.bottom - y);
            p.lineTo(x, rect.bottom);
          }
        } else {
          var i = series.values.indexOf(e);
          var e1 = series.values[i - 1];
          var x1 = x + viewport.xPerStep! * _calculateFraction(e1.time, e.time);
          var y1 = (e1.value - viewport.min!) * yRatio;
          var m = (y1 - y) / (x1 - x);
          num q = y - m * x;
          var y0 = m * rect.right + q;
          //_drawPoint(canvas, rect, rect.left, y0);
          if (series.type == SeriesType.line ||
              series.type == SeriesType.lineNoPoint)
            p.lineTo(rect.right, rect.bottom - y0);
          x = rect.right;
        }
      }
    });

    canvas.drawPath(p, dpPaint);
    if (series.fill) {
      if (low != null) {
        first = true;
        low.forEach((e) {
          var v = e.value;
          var d = e.time;

          // (v-minD) because we start our range at min value
          num y;

          y = (v - viewport.min!) * yRatio; // * percentage; // for animation
          if (yRatio.isInfinite) y = chartH / 2;

          if (first) {
            fraction = _calculateFraction(d, series.values.last.time);
          } else {
            fraction =
                _calculateFraction(d, low!.elementAt(low.indexOf(e) - 1).time);
          }
          x += viewport.xPerStep! * fraction;

          if (x - rect.right < 0) {
            //if (series.type != SeriesType.stemNoPoint)
            //_addPoint(rect, x, y, e, series.name);
            if (series.type == SeriesType.line ||
                series.type == SeriesType.lineNoPoint) if (first) {
              first = false;
              lowPath.moveTo(x, rect.bottom - y);
            } else
              lowPath.lineTo(x, rect.bottom - y);
            /*  else if (series.type == SeriesType.stem ||
              series.type == SeriesType.stemNoPoint) {
            p.moveTo(x, rect.bottom - y);
            p.lineTo(x, rect.bottom);
          } */
          }
        });
        p.extendWithPath(lowPath, Offset.zero);
        lowPath.lineTo(firstX, firstY);
      } else {
        p.lineTo(x < rect.right ? x : rect.right, rect.bottom);
        p.lineTo(firstX > rect.left ? firstX : rect.left, rect.bottom);
      }
      canvas.drawPath(p, dpPaintFill);
    }

    if (series.type != SeriesType.lineNoPoint)
      points[series.name]!.forEach((key, value) =>
          _drawPoint(canvas, rect, value.dx, value.dy, key, series));
  }

  double _calculateFraction(DateTime d, DateTime prev) {
    var diff = d.difference(prev);
    if (viewport.step == Step.Month) {
      return diff.inDays.toDouble() / DateUtils.getDaysInMonth(d.year, d.month);
    } else if (viewport.step == Step.Day) {
      return diff.inSeconds.toDouble() / 86400;
    } else if (viewport.step == Step.Hour) {
      return diff.inSeconds.toDouble() / 3600;
    } else {
      return diff.inSeconds.toDouble() / 60;
    }
  }

  _drawPoint(
      Canvas canvas, Rect rect, double x, double y, Data e, Series series) {
    if (e.pointType == PointType.circle)
      canvas.drawCircle(
        Offset(x, y),
        e.isSame(selected?.value) ? series.drawSize + 3 : series.drawSize + 1,
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 2
          ..color = e.color ?? series.color,
      );
    else if (e.pointType == PointType.square)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCircle(
                center: Offset(x, y),
                radius: e.isSame(selected?.value)
                    ? series.drawSize + 3
                    : series.drawSize + 1),
            Radius.zero),
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 2
          ..color = e.color ?? series.color,
      );

    if (e.isSame(selected?.value)) {
      canvas.drawLine(
          Offset(x, rect.bottom),
          Offset(x, rect.top),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.black87);
    }
  }

  _addPoint(Rect rect, double x, double y, Data e, String sName) {
    points[sName]!.putIfAbsent(e, () => Offset(x, rect.bottom - y));
  }

  drawText(Canvas canvas, Offset position, double width, TextStyle style,
      String text, {bool ltr = true}) {
    final textSpan = TextSpan(text: ltr ? text : text.split('').reversed.join(), style: style);
    final textPainter =
        TextPainter(text: textSpan, textDirection: ltr? TextDirection.ltr: TextDirection.rtl);
    textPainter.layout(minWidth: 0, maxWidth: width);
    textPainter.paint(canvas, position);
  }

  drawVerticalText(Canvas canvas, Offset position, double width,
      TextStyle style, String text) {
    canvas.save();
    canvas.translate(position.dx + style.fontSize!, position.dy);
    canvas.rotate(3.14 / 2);
    final textSpan = TextSpan(text: text, style: style);
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  double measureText(String text, TextStyle style, double width) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout(minWidth: 0, maxWidth: width);
    return textPainter.width;
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
    late double? xStep;
    double maxW = List<DateTime>.from(viewport.steps)
        .map<String>((e) => DateFormat(labelFormat).format(e))
        .map((e) => measureText(e, labelStyle, 100))
        .reduce((e, d) => e > d ? e : d);
    int skip = 5;
    if (viewport.xPerStep! < maxW) {
      var t = List.from(viewport.steps);
      var temp = Map.fromIterable(t, key: (_) => t.indexOf(_), value: (_) => _)
        ..removeWhere((key, value) => key % skip != 0);
      labels = temp
          .map<int, String>(
              (_, e) => MapEntry(_, DateFormat(labelFormat).format(e)))
          .values
          .toList();
      xStep = viewport.xPerStep! * (skip);
    } else {
      labels = viewport.steps
          .map((e) => DateFormat(labelFormat).format(e!))
          .toList();
      xStep = viewport.xPerStep;
    }
    if (xStep! >= 0)
      labels.forEach((element) {
        canvas.drawLine(Offset(x, rect.bottom + labelOffset - offsetStep / 2),
            Offset(x, rect.bottom), chBorder);
        canvas.drawLine(Offset(x, rect.bottom + labelOffset),
            Offset(x, rect.bottom + labelOffset - offsetStep / 2), Paint());
        double meas = measureText(element, labelStyle, xStep!);
        drawText(canvas, Offset(x - meas / 2, rect.bottom + labelOffset), xStep,
            labelStyle, element);
        x += xStep;
      });
  }

  void drawYLabels(Canvas canvas, Rect rect, TextStyle labelStyle) {
    Offset posTop = rect.topLeft + Offset(-leftMargin, 0);
    Offset posBottom = rect.bottomLeft + Offset(-leftMargin, -10);

    //draw y Label
    List<num> toDraw = [viewport.min!, viewport.max!];
    if(yLabels != null && yLabels!.isNotEmpty)
      toDraw.addAll(yLabels!);
    int prec = _findMinPrecision(
        toDraw, leftMargin - 5, labelStyle);
    _drawTextStringCustom(canvas, posBottom, leftMargin - 5, labelStyle, prec,
        viewport.min!); // print min value
     _drawTextStringCustom(canvas, posTop, leftMargin - 5, labelStyle, prec,
        viewport.max!); // print max value
    if (measureUnit != null)
      drawText(canvas, posTop + Offset(0, -labelStyle.fontSize! - 3),
          rect.width / 3, labelStyle, measureUnit!);

    if (yLabels != null && yLabels!.isNotEmpty) {
      yLabels!.forEach((element) {
        Offset o = Offset(0, -yRatio * element);
        if (o.dy.abs() < labelStyle.fontSize! ||
            rect.height - o.dy.abs() < labelStyle.fontSize!) return;
        _drawTextStringCustom(
            canvas, posBottom + o, leftMargin - 5, labelStyle, prec, element);
      });
    }
  }

  _drawTextStringCustom(Canvas canvas, Offset position, double width,
      TextStyle style, int prec, num value,
      {bool right = false}) {
    String str;
    if (value == 0) {
      int p = prec;
      if(maxCharsAxisLabel  != null)
        p = min(prec, maxCharsAxisLabel!);
      str = '0';
      Offset o = position.translate(
          (right ? 0 : 1) * (p - 1 - (right ? 0 : 1)) * style.fontSize!, 0);
      drawText(canvas, o, style.fontSize!, labelStyle, str);
      return;
    } else {
      prec = min(prec, value.toString().length);
      if (maxCharsAxisLabel != null) {
        if (maxCharsAxisLabel! < prec &&
            value.toStringAsPrecision(prec).length > maxCharsAxisLabel!) {
          str = value.toStringAsPrecision(maxCharsAxisLabel!);
          drawText(
              canvas,
             /*  position.translate(
                  (right ? 0 : 1) *
                      (prec - maxCharsAxisLabel! - (right ? 0 : 1)) *
                      style.fontSize!,
                  0), */
                  position,
              width,
              labelStyle,
              str);
          return;
        } else {
          str = value.toStringAsPrecision(prec);
        }
      }
    }
    drawText(canvas, position, width, style, value.toStringAsPrecision(prec));
  }

  int _findMinPrecision(List<num> values, double width, TextStyle style) {
    int prec = 1;

    values.forEach((element) {
      int p = prec;
      while (measureText(viewport.max!.toStringAsPrecision(p), style, width) <=
              width &&
          p < 21) {
        p++;
      }
      if (prec < p - 1) prec = p - 1;
    });

    return prec;
  }

  void drawSecondaryYLabels(
    Canvas canvas,
    Rect rect,
    TextStyle labelStyle,
  ) {
    if (secondaryMeasureUnit != null) {
      double posX = rightMargin + 1;
      secondaryMeasureUnit!.forEach((key, value) {
        double space = measureText(
            secondaryMeasureUnit![key]!, labelStyle, rect.width / 3);
        posX -= space + 3;
        drawText(
            canvas,
            rect.topRight + Offset(posX, -labelStyle.fontSize! - 3),
            measureText(
                secondaryMeasureUnit![key]!, labelStyle, rect.width / 3),
            labelStyle,
            secondaryMeasureUnit![key]!);
        //draw y Label
        int prec = _findMinPrecision(
            [viewport.secondaryMin![key]!, viewport.secondaryMax![key]!],
            space + 5,
            labelStyle);
        _drawTextStringCustom(
            canvas,
            rect.bottomRight + Offset(posX, -labelStyle.fontSize! - 3),
            space + 5,
            labelStyle,
            prec,
            viewport.secondaryMin![key]!,
            right: true); // print min value
        _drawTextStringCustom(
            canvas,
            rect.topRight + Offset(posX, -labelStyle.fontSize! + 10),
            space + 5,
            labelStyle,
            prec,
            viewport.secondaryMax![key]!,
            right: true); // print max value
      });
    }
  }

  void drawLegend(Canvas canvas, Rect rect, TextStyle legendStyle) {
    int i = 1;
    bool col0 = true;
    int nS =
        seriesList.length + secondarySeries!.length + insideNoValSeries.length;
    List<Series> merge = List.from(seriesList)
      ..addAll(secondarySeries!)
      ..addAll(insideNoValSeries);
    merge.forEach((element) {
      double x = col0 ? 0 : 4 / 5 * rect.bottomCenter.dx;
      double y = labelOffset + 3 + offsetStep / 2 + offsetStep * i;
      canvas.drawRect(
          Rect.fromCenter(
              center: rect.bottomLeft + Offset(x, y), width: 10, height: 10),
          Paint()..color = element.color);
      drawText(
          canvas,
          rect.bottomLeft + Offset(x + 10, y - offsetStep / 2),
          double.maxFinite,
          legendStyle,
          element
              .name /* +
              (element.values.contains(selected!.value)
                  ? ': ' + selected!.value!.toValueString()
                  : '') */
          );
      i++;
      if (twoColLegend) if (!(i < nS / 2 + 1)) {
        col0 = false;
        i = 1;
      }
    });
  }

  void drawRanges(Canvas canvas, Rect rect) {
    if (ranges == null) return;
    ranges!.forEach((element) {
      Paint paint = Paint()
        ..color = element.color.withAlpha(128)
        ..style = PaintingStyle.fill;
      double top = element.top != null
          ? rect.bottom - (element.top! - viewport.min!) * yRatio
          : rect.top;
      double bottom = element.bottom != null
          ? rect.bottom - (element.bottom! - viewport.min!) * yRatio
          : rect.bottom;
      double left = element.start != null
          ? rect.left +
              _calculateFraction(element.start!, viewport.start!) *
                  viewport.xPerStep!
          : rect.left;
      double right = element.end != null
          ? rect.left +
              _calculateFraction(element.end!, viewport.start!) *
                  viewport.xPerStep!
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
              DateFormat(labelFormat).format(element.start!));
        }
        if (right < rect.right) {
          canvas.drawLine(Offset(right - 1, rect.top),
              Offset(right - 1, rect.top - 15), Paint());
          drawText(canvas, Offset(right - 36, rect.top - 15), 40, labelStyle,
              DateFormat(labelFormat).format(element.end!));
        }
      }
      if (element.yLabel) {
        if (element.bottom != null && bottom < rect.bottom - 15) {
          double w = measureText(
              element.bottom!.toStringAsPrecision(4), labelStyle, 40);
          canvas.drawLine(Offset(rect.left, bottom),
              Offset(rect.left - 10, bottom), Paint());
          drawText(
              canvas,
              Offset(rect.left - 13 - w, bottom - labelStyle.fontSize! / 2),
              40,
              labelStyle,
              element.bottom!.toStringAsPrecision(4));
        }
        if (element.top != null && top > rect.top) {
          double w =
              measureText(element.top!.toStringAsPrecision(4), labelStyle, 40);

          canvas.drawLine(
              Offset(rect.left, top), Offset(rect.left - 10, top), Paint());
          drawText(
              canvas,
              Offset(rect.left - 13 - w, top - labelStyle.fontSize! / 2),
              40,
              labelStyle,
              element.top!.toStringAsPrecision(4));
        }
      }
      if (element.icon != null) {
        final icon = element.icon!.icon!;
        TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
        textPainter.text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            color: Colors.black,
            fontFamily: icon.fontFamily,
            package: icon
                .fontPackage, // This line is mandatory for external icon packs
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(left, bottom - 2 * labelOffset));
      }
      if (element.description != null) {
        drawVerticalText(
            canvas, Offset(left, top), 40, labelStyle, element.description!);
      }
    });
  }

  @override
  bool shouldRepaint(MyChartPainter oldDelegate) =>
      oldDelegate.viewport != viewport;

  @override
  bool shouldRebuildSemantics(MyChartPainter oldDelegate) => true;

  void drawNoValPoints(Canvas canvas, Paint dpPaint, Rect rect, Series series) {
    bool below = series.type == SeriesType.noValue;
    double offset;
    if (below) {
      offset = labelOffset;
      labelOffset += offsetStep;
    } else {
      offset = insideNoValOffset;
      insideNoValOffset -= offsetStep;
    }
    var fraction;
    var x = rect.left;
    bool first = true;
    series.values.forEach((e) {
      var d = e.time;
      if (first) {
        fraction = _calculateFraction(d, viewport.start!);
        first = false;
      } else
        fraction = _calculateFraction(
            d, series.values.elementAt(series.values.indexOf(e) - 1).time);
      x += viewport.xPerStep! * fraction;
      if (x - rect.right < 0 && x - rect.left > 0)
        _addPoint(rect, x, -offset, e, series.name);
    });
    points[series.name]!.forEach((key, value) =>
        _drawPoint(canvas, rect, value.dx, rect.bottom + offset, key, series));
    if (below)
      canvas.drawLine(
          Offset(rect.left, rect.bottom + offset + 7),
          Offset(rect.right, rect.bottom + offset + 7),
          Paint()..color = Colors.black);
  }

  void drawNoValInsidePoints(Canvas canvas, Rect rect, List<Series> series) {
    double offset = insideNoValOffset;

    var fraction;
    var x = rect.left;
    bool first = true;
    Map<double, List<List<dynamic>>> fractions =
        Map(); //fraction, [{Data, Series}]
    series.forEach((s) {
      points[s.name] = {};
      s.values.forEach((element) {
        double fraction = _calculateFraction(element.time, viewport.start!);
        fractions[fraction] = fractions.containsKey(fraction)
            ? List.from(fractions[fraction]!..add([element, s]))
            : [
                [element, s]
              ];
      });
    });
    fractions.forEach((frac, list) {
      x = rect.left + viewport.xPerStep! * frac;
      if (x - rect.right < 0 && x - rect.left > 0) {
        list.asMap().forEach((i, element) {
          offset = insideNoValOffset - i * offsetStep;
          _addPoint(rect, x, -offset, element[0], (element[1] as Series).name);
          _drawPoint(
              canvas, rect, x, rect.bottom + offset, element[0], element[1]);
        });
      }
    });
  }
}
