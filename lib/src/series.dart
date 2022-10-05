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

  final Color? fillColor;

  final List<Data>? lowerLimit;

  /// type of this series, default [SeriesType.line]
  final SeriesType type;

  /// whether this series should be plotted on secondary axis, default [false]
  final bool secondaryAxis;

  /// size of data visualization paint
  final double drawSize;

  late List<Data> _allPoints;

  Series(
      {required List<Data> val,
      required this.name,
      Color? color,
      this.fill = false,
      this.fillColor,
      this.lowerLimit,
      this.type = SeriesType.line,
      this.secondaryAxis = false,
      this.drawSize = 3.0})
      : values = val..sort((a, b) => a.time.compareTo(b.time)),
        this.color = color ?? Color(Colors.blue.value),
        assert(!(secondaryAxis && type == SeriesType.noValue),
            !(fill && (type == SeriesType.noValue || type == SeriesType.dot))) {
    _allPoints = List.from(values);
    if (lowerLimit != null) {
      lowerLimit!.sort((a, b) => a.time.compareTo(b.time));
      _allPoints.addAll(lowerLimit!);
    }
  }

  Series copyWith(
      {Color? color,
      List<Data>? values,
      List<Data>? lowerLimit,
      String? name,
      bool? fill,
      SeriesType? type,
      bool? secondaryAxis,
      double? drawSize}) {
    return Series(
        val: values ?? this.values,
        lowerLimit: lowerLimit ?? this.lowerLimit,
        name: name ?? this.name,
        color: color ?? this.color,
        fill: fill ?? this.fill,
        fillColor: fillColor ?? this.fillColor,
        type: type ?? this.type,
        secondaryAxis: secondaryAxis ?? this.secondaryAxis,
        drawSize: drawSize ?? this.drawSize);
  }

  num get min => _allPoints
      .map<num>((e) => e.value)
      .reduce((value, element) => math.min(value, element));
  num get max => _allPoints
      .map<num>((e) => e.value)
      .reduce((value, element) => math.max(value, element));
  num get rangeY =>
      _allPoints
          .map<num>((e) => e.value)
          .reduce((value, element) => math.max(value, element)) -
      _allPoints
          .map<num>((e) => e.value)
          .reduce((value, element) => math.min(value, element));
  Duration get rangeX => _allPoints.last.time.difference(_allPoints.first.time);
  DateTime get start => _allPoints.first.time;
  DateTime get end => _allPoints.last.time;

  String toString() {
    return values.map((e) => "${e.time} - ${e.value}\n").toList().toString() +
        " rangeX: $rangeX";
  }
}

class Data {
  /// time of this data point
  final DateTime time;

  /// numeric value of this data point
  final num value;

  /// custom color of this data point. It overrides the color of the [Series] containing this point
  final Color? color;

  /// custom description to be shown in tooltip
  final String? description;

  /// original data object in its original class
  final dynamic originalData;

  final PointType pointType;
  Data(this.time, this.value,
      {this.color,
      this.description,
      this.originalData,
      this.pointType = PointType.circle});

  @override
  String toString() {
    return DateFormat.Hms().format(time) +
        ' - ' +
        value.toStringAsFixed(3) +
        (description != null ? ' - $description' : '');
  }

  String toValueString() {
    return DateFormat.Hms().format(time) + ' - ' + value.toStringAsFixed(3);
  }
  
  String toDescriptionString() {
    assert(description != null);
    return DateFormat.Hms().format(time) + ' - ' + description!;
  }

  bool isSame(Data? other) => other != null
      ? this.originalData != null && other.originalData != null
          ? this.originalData == other.originalData
              ? true
              : false
          : this.time.isAtSameMomentAs(other.time) && this.value == other.value
      : false;
}

class Range {
  /// top margin of this range
  num? top;

  /// top label of this range
  /* String topLabel;
  /// bottom margin of this range */
  num? bottom;
  /* /// bottom label of this range
  String bottomLabel; */
  /// whether to display this label on y margins
  bool yLabel;

  /// start date of this range
  DateTime? start;

  /// whether to display this label on x margins
  bool xLabel;

  /// end date of this range
  DateTime? end;

  /// color of this range
  Color color;

  /// description to be shown inside the range
  String? description;

  /// icon to be shown inside the range
  Icon? icon;

  Range(
      {this.top,
      this.bottom,
      this.end,
      this.start,
      this.color = Colors.grey,
      this.icon,
      //this.bottomLabel,
      //this.topLabel,
      this.yLabel = false,
      this.xLabel = false,
      this.description})
      : assert(!yLabel || (yLabel && (top != null || bottom != null))),
        assert(!(icon != null && description != null)){
          if(start == null) start = DateTime(0);
          if(end == null) end = DateTime(3000);
        }

  @override
  String toString() {
    return 'X: $start - $end\n Y: $top - $bottom';
  }

  Range copyWith(
      {num? top,
      num? bottom,
      DateTime? end,
      DateTime? start,
      Color? color,
      Icon? icon,
      bool? yLabel,
      bool? xLabel,
      String? description}) {
    return Range(
        top: top ?? this.top,
        bottom: bottom ?? this.bottom,
        end: end ?? this.end,
        start: start ?? this.start,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        yLabel: yLabel ?? this.yLabel,
        xLabel: xLabel ?? this.xLabel,
        description: description ?? this.description);
  }
}

enum SeriesType {
  /// plot [Data] as connected line
  line,

  /// plot [Data] as connected line without value point
  lineNoPoint,

  /// plot [Data] as stem
  stem,

  /// plot [Data] as stem without value point
  stemNoPoint,

  /// plot [Data] as a single point
  dot,

  /// plot only the time of the [Data] points BELOW the graph
  noValue,

  /// plot only the time of the [Data] points INSIDE the graph
  noValueInside
}

enum PointType { circle, square }
