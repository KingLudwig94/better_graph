import 'package:in_date_utils/in_date_utils.dart';

enum Step { Minute, Hour, Day, Month }

class Viewport {
  DateTime start;
  DateTime end;
  Duration rangeX;
  num max;
  num min;
  Step step;
  double xPerStep;
  List<DateTime> steps;
  int stepCount;
  num rangeY;
  num secondaryMax = 0;
  num secondaryMin = 0;
  num secondaryRangeY = 0;

  Viewport copyWith(DateTime start, DateTime end) {
    return Viewport(
        start: start,
        end: end,
        max: this.max,
        min: this.min,
        secondaryMax: this.secondaryMax,
        secondaryMin: this.secondaryMin);
  }

  Viewport(
      {DateTime start,
      DateTime end,
      this.max,
      this.min,
      this.secondaryMax = 0,
      this.secondaryMin = 0}) {
    this.start = start;
    this.end = end;
    rangeX = end.difference(start);
    step = _setStep();
    rangeY = max - min;
    if (this.secondaryMax != null && this.secondaryMin != null)
      secondaryRangeY = secondaryMax - secondaryMin;
    if (step == Step.Day) {
      this.start = DateUtils.copyWith(this.start,
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      this.end = DateUtils.copyWith(this.end,
          day: this.end.hour > 0 ? this.end.day + 1 : null,
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0);
      rangeX = this.end.difference(this.start);
      step = _setStep();
      stepCount = rangeX.inDays;
      steps = [this.start]
        ..addAll(stepCount > 0
            ? List.generate(stepCount - 1,
                (index) => this.start.add(Duration(days: (index + 1))))
            : [])
        ..add(this.end);
    } else if (step == Step.Hour) {
      this.start = DateUtils.copyWith(this.start,
          minute: 0, second: 0, millisecond: 0, microsecond: 0);
      this.end = DateUtils.copyWith(this.end,
          hour: this.end.minute > 0 ? this.end.hour + 1 : null,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0);
      rangeX = this.end.difference(this.start);
      step = _setStep();
      stepCount = rangeX.inHours;
      steps = [this.start]
        ..addAll(stepCount > 0
            ? List.generate(stepCount - 1,
                (index) => this.start.add(Duration(hours: (index + 1))))
            : [])
        ..add(this.end);
    } else if (step == Step.Minute) {
      this.start = DateUtils.copyWith(this.start,
          second: 0, millisecond: 0, microsecond: 0);
      this.end = DateUtils.copyWith(this.start,
          minute: this.end.second > 0 ? this.end.minute + 1 : null,
          second: 0,
          millisecond: 0,
          microsecond: 0);
      rangeX = this.end.difference(this.start);
      step = _setStep();
      stepCount = rangeX.inMinutes;
      steps = [this.start]
        ..addAll(stepCount > 0
            ? List.generate(stepCount - 1,
                (index) => this.start.add(Duration(minutes: (index + 1))))
            : [])
        ..add(this.end);
    }
  }

  Step _setStep() {
    if (rangeX.inDays > 0) {
      return Step.Day;
    } else if (rangeX.inHours > 0) {
      return Step.Hour;
    } else
      return Step.Minute;
  }
}
