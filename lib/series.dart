import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Series {
  final List<Data> values;
  final String name;
  final Color color;
  final bool fill;
  final SeriesType type;
  final bool secondaryAxis;

  Series copyWith(
      {Color color,
      List<Data> values,
      String name,
      bool fill,
      SeriesType type,
      bool secondaryAxis}) {
    return Series(values ?? this.values, name ?? this.name,
        color: color ?? this.color,
        fill: fill ?? this.fill,
        type: type ?? this.type,
        secondaryAxis: secondaryAxis ?? this.secondaryAxis);
  }

  Series(List<Data> val, this.name,
      {Color color,
      this.fill = false,
      this.type = SeriesType.line,
      this.secondaryAxis = false})
      : values = val..sort((a, b) => a.time.compareTo(b.time)),
        this.color = color ?? Color(Colors.blue.value),
        assert(!(secondaryAxis && type == SeriesType.noValue),
            !(fill && (type == SeriesType.noValue || type == SeriesType.dot)));

  num get min => values
      .map<num>((e) => e.value)
      .reduce((value, element) => math.min(value, element));
  num get max => values
      .map<num>((e) => e.value)
      .reduce((value, element) => math.max(value, element));
  num get rangeY =>
      values
          .map<num>((e) => e.value)
          .reduce((value, element) => math.max(value, element)) -
      values
          .map<num>((e) => e.value)
          .reduce((value, element) => math.min(value, element));
  Duration get rangeX => values.last.time.difference(values.first.time);
  DateTime get start => values.first.time;
  DateTime get end => values.last.time;

  String toString() {
    return values.map((e) => "${e.time} - ${e.value}\n").toList().toString() +
        " range: $rangeX";
  }
}

class Data {
  final DateTime time;
  final num value;
  final Color color;
  Data(this.time, this.value, {this.color});

  @override
  String toString() {
    return DateFormat.Hms().format(time) + ' - ' + value.toStringAsFixed(3);
  }

  bool isSame(Data other) => other != null
      ? this.time.isAtSameMomentAs(other.time) && this.value == other.value
      : false;
}

class Range {
  num top;
  String topLabel;
  num bottom;
  String bottomLabel;
  bool yLabel;
  DateTime start;
  bool xLabel;
  DateTime end;
  Color color;
  Range(
      {this.top,
      this.bottom,
      this.end,
      this.start,
      this.color = Colors.grey,
      this.bottomLabel,
      this.topLabel,
      this.yLabel = false,
      this.xLabel = false})
      : assert(!yLabel || (yLabel && (top != null && bottom != null)));

  @override
  String toString() {
    return 'X: $start - $end\n Y: $top - $bottom';
  }
}

enum SeriesType { line, stem, dot, noValue }
