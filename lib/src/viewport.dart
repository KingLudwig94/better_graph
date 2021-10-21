import 'package:in_date_utils/in_date_utils.dart';

enum Step { Minute, Hour, Day, Month }

class Viewport {
  DateTime? start;
  DateTime? end;
  late Duration rangeX;
  num? max;
  num? min;
  Step? step;
  double? xPerStep;
  late List<DateTime?> steps;
  late int stepCount;
  late num rangeY;
  Map<String, num>? secondaryMax;
  Map<String, num>? secondaryMin;
  Map<String, num> secondaryRangeY = {};

  Viewport copyWith(
      {DateTime? start,
      DateTime? end,
      num? max,
      num? min,
      Map<String, num>? secondaryMax,
      Map<String, num>? secondaryMin}) {
    return Viewport(
        start: start ?? this.start,
        end: end ?? this.end,
        max: max ?? this.max,
        min: min ?? this.min,
        secondaryMax: secondaryMax ?? this.secondaryMax,
        secondaryMin: secondaryMin ?? this.secondaryMin);
  }

  Viewport(
      {this.start,
      this.end,
      this.max,
      this.min,
      this.secondaryMax,
      this.secondaryMin}) {
    if (start != null && end != null) {
      rangeX = end!.difference(start!);
      step = _setStep();
    }
    if (max != null && min != null) rangeY = max! - min!;
    if (this.secondaryMax != null && this.secondaryMin != null) {
      secondaryMax!.forEach((i, element) {
        secondaryRangeY[i] = secondaryMax![i]! - secondaryMin![i]!;
      });
    }
    if (step != null) {
      if (step == Step.Day) {
        this.start = DateUtils.copyWith(this.start!,
            hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
        this.end = DateUtils.copyWith(this.end!,
            day: this.end!.hour > 0 ? this.end!.day + 1 : null,
            hour: 0,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0);
        rangeX = this.end!.difference(this.start!);
        step = _setStep();
        stepCount = rangeX.inDays;
        steps = [this.start]
          ..addAll(stepCount > 0
              ? List.generate(stepCount - 1,
                  (index) => this.start!.add(Duration(days: (index + 1))))
              : [])
          ..add(this.end);
      } else if (step == Step.Hour) {
        this.start = DateUtils.copyWith(this.start!,
            minute: 0, second: 0, millisecond: 0, microsecond: 0);
        this.end = DateUtils.copyWith(this.end!,
            hour: this.end!.minute > 0 ? this.end!.hour + 1 : null,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0);
        rangeX = this.end!.difference(this.start!);
        step = _setStep();
        stepCount = rangeX.inHours;
        steps = [this.start]
          ..addAll(stepCount > 0
              ? List.generate(stepCount - 1,
                  (index) => this.start!.add(Duration(hours: (index + 1))))
              : [])
          ..add(this.end);
      } else if (step == Step.Minute) {
        this.start = DateUtils.copyWith(this.start!,
            second: 0, millisecond: 0, microsecond: 0);
        this.end = DateUtils.copyWith(this.start!,
            minute: this.end!.second > 0 ? this.end!.minute + 1 : null,
            second: 0,
            millisecond: 0,
            microsecond: 0);
        rangeX = this.end!.difference(this.start!);
        step = _setStep();
        stepCount = rangeX.inMinutes;
        steps = [this.start]
          ..addAll(stepCount > 0
              ? List.generate(stepCount - 1,
                  (index) => this.start!.add(Duration(minutes: (index + 1))))
              : [])
          ..add(this.end);
      }
    }
  }

  Step _setStep() {
    if (rangeX.inHours > 36) {
      return Step.Day;
    } else if (rangeX.inHours > 0) {
      return Step.Hour;
    } else
      return Step.Minute;
  }
}
