import 'dart:math';

import 'package:flutter/material.dart';
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
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Series> series;
  Random random = Random();

  Series generateSeries(String name, SeriesType type,
      {bool secondary = false, Color colors = Colors.red, bool fill = false}) {
    return Series(
        List.generate(
          10,
          (index) => Data(
              DateTime.now().subtract(Duration(
                  hours: random.nextInt(16), minutes: random.nextInt(30))),
              random.nextDouble(),
              color: index == 3 ? Colors.black : null),
        ),
        name,
        secondaryAxis: secondary,
        type: type,
        fill: fill,
        color: colors);
  }

  @override
  Widget build(BuildContext context) {
    series = [
      generateSeries('test', SeriesType.line, fill: true),
      generateSeries('test2', SeriesType.line, colors: Colors.black),
      generateSeries('name', SeriesType.noValue, colors: Colors.blue),
      generateSeries('noval', SeriesType.noValue, colors: Colors.grey),
      generateSeries('secondaria', SeriesType.stem,
          secondary: true, colors: Colors.green)
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Chart(
              seriesList: [series[0], series[2], series[3]],
              measureUnit: 'unità',
              title: "primo",
            ),
          ),
          AspectRatio(
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
                )
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Chart(
              seriesList: [series[1], series[4]],
              secondaryMeasureUnit: 'passi',
            ),
          ),
        ],
      ),
    );
  }
}
