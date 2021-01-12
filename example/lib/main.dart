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
  Series series;
  Random random = Random();

  @override
  Widget build(BuildContext context) {
    series = Series(
        List.generate(
            10,
            (index) => Data(
                DateTime.now().subtract(Duration(
                  hours: random.nextInt(16), minutes: random.nextInt(30)
                )),
                random.nextDouble()))
        /* [
          Data(
              DateTime.parse('2021-01-11 16:29:47.355589'), 0.7329044472692887),
          Data(
              DateTime.parse('2021-01-11 16:33:17.355592'), 0.5708143077340662),
          Data(DateTime.parse('2021-01-11 16:42:47.355493'), 0.7528595474568435)
        ] */, 'test');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Chart(
          series: series,
          /* startDate: DateTime.parse('2021-01-11 16:42:47.355493').subtract(
            Duration(minutes: 10),
          ),
          endDate: DateTime.parse('2021-01-11 16:42:47.355493')
              .subtract(Duration(minutes: 5)), */
        ),
      )),
    );
  }
}
