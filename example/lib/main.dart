import 'dart:math';

import 'package:flutter/material.dart' hide Viewport;
import 'package:better_graph/better_graph.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Series> series;
  Random random = Random();

  Series generateSeries(String name, SeriesType type,
      {bool secondary = false,
      Color colors = Colors.red,
      bool fill = false,
      double? size,
      double? low}) {
    List<Data> val = List.generate(
      10,
      (index) => Data(
          DateTime.now().subtract(Duration(
              hours: 1 * random.nextInt(32), minutes: random.nextInt(30))),
          random.nextDouble(),
          color: index == 3 ? Colors.black : null,
          description: index % 2 == 0 ? 'prova nota' : null),
    );
    return Series(
        val: val,
        name: name,
        secondaryAxis: secondary,
        type: type,
        lowerLimit:
            low != null ? val.map((f) => Data(f.time, f.value - low)).toList() : null,
        fill: fill,
        color: colors);
  }

  @override
  Widget build(BuildContext context) {
    series = [
      generateSeries(
        'test',
        SeriesType.line,
        fill: true,
      ),
      generateSeries('test2', SeriesType.line, colors: Colors.black),
      generateSeries('name', SeriesType.noValue, colors: Colors.blue),
      generateSeries('noval', SeriesType.noValue, colors: Colors.grey),
      generateSeries('secondaria', SeriesType.stem,
          secondary: true, colors: Colors.green, size: 1),
      generateSeries('low', SeriesType.line,
          colors: Colors.black, fill: true, low: .1)
    ];
    print(series[5]);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Chart(
              seriesList: [series[5]],
              // viewport: Viewport(max: 1, min: 0, start: DateTime(2021, 3, 3)),
              showTooltip: true,
              secondaryMeasureUnit: 'passi',
              /* tooltip: (data, series) {
                print(series.where((a) => a.values.contains(data))?.first?.name);
                return Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.black, width: 1)),
                  child: Text(data.toString()),
                );
              }, */
            ),
          ),
          /*  AspectRatio(
            aspectRatio: 16 / 9,
            child: Chart(
              seriesList: [series[1]],
              ranges: [
                Range(
                    top: series.first.max / 2,
                    bottom: series.first.min * 2,
                    yLabel: true),
                Range(
                  start: series.first.start
                      .add(Duration(minutes: random.nextInt(60))),
                  end: series.first.end
                      .subtract(Duration(hours: random.nextInt(4))),
                  color: Colors.blue.shade200,
                  xLabel: true,
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Chart(
              seriesList: [series[1], series[4]],
              secondaryMeasureUnit: 'passi',
            ),
          ), */
        ],
      ),
    );
  }
}
