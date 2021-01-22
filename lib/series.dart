import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Series {
  /// list of [Data] of the series
  final List<Data> values;

  /// name of this series, should be unique
  final String name;

  /// color of this series
  final Color color;

  /// whether the series should have below area filled
  final bool fill;

  /// type of this series, default [SeriesType.line]
  final SeriesType type;

  /// whether this series should be plotted on secondary axis, default [false]
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
  /// time of this data point
  final DateTime time;

  /// numeric value of this data point
  final num value;

  /// custom color of this data point. It overrides the color of the [Series] containing this point
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
  /// top margin of this range
  num top;

  /// top label of this range
  /* String topLabel;
  /// bottom margin of this range */
  num bottom;
  /* /// bottom label of this range
  String bottomLabel; */
  /// whether to display this label on y margins
  bool yLabel;

  /// start date of this range
  DateTime start;

  /// whether to display this label on x margins
  bool xLabel;

  /// end date of this range
  DateTime end;

  /// color of this range
  Color color;
  Range(
      {this.top,
      this.bottom,
      this.end,
      this.start,
      this.color = Colors.grey,
      //this.bottomLabel,
      //this.topLabel,
      this.yLabel = false,
      this.xLabel = false})
      : assert(!yLabel || (yLabel && (top != null && bottom != null)));

  @override
  String toString() {
    return 'X: $start - $end\n Y: $top - $bottom';
  }
}

enum SeriesType {
  /// plot [Data] as connected line
  line,

  /// plot [Data] as stem
  stem,

  /// plot [Data] as a single point
  dot,

  /// plot only the time of the [Data] points below the graph
  noValue
}
