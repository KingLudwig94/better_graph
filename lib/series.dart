import 'dart:math' as math;

import 'package:intl/intl.dart';

class Series {
  final List<Data> values;
  final String name;
/*   final num min;
  final num max;
  final num rangeY;
  final Duration rangeX; */
  Series(List<Data> val, this.name)
      : values = val..sort((a, b) => a.time.compareTo(b.time));

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
  Data(this.time, this.value);

  @override
  String toString() {
    return DateFormat.Hms().format(time) + ' ' + value.toStringAsFixed(3);
  }

  bool isSame(Data other) => other != null
      ? this.time.isAtSameMomentAs(other.time) && this.value == other.value
      : false;
}
