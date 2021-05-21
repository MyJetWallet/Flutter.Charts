import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:charts/entity/instrument_entity.dart';
import 'package:charts/entity/resolution_string_enum.dart';
import 'package:charts/http/http_service.dart';
import 'package:charts/utils/data_feed_util.dart';
import './flutter_k_chart.dart';
import './k_chart_widget.dart';

import 'entity/candle_type_enum.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Chart(title: 'Charts Demo Home Page'),
    );
  }
}

class Chart extends StatefulWidget {
  Chart({Key key, this.title, this.authToken, this.instrument})
      : super(key: key);

  final String title;
  final String authToken;
  final Instrument instrument;

  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  List<KLineEntity> candlesArray = <KLineEntity>[];
  bool showLoading = true;
  CandleTypeEnum candleType = CandleTypeEnum.Candle;
  final textController = TextEditingController();
  bool isTextInputVisible = true;
  final HttpService httpService = HttpService();

  DateTime now = DateTime.now();
  String candleResolution = ResolutionString.minute;
  DateTimeRange timeFrame = DateTimeRange(
      start: DateTime.now().subtract(const Duration(minutes: 15)),
      end: DateTime.now());
  int historyDepth = 0;

  @override
  void initState() {
    super.initState();
    getData(widget.authToken, candleResolution, widget.instrument.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff252736),
      body: ListView(
        children: <Widget>[
          Stack(children: <Widget>[
            Container(
              height: 600,
              margin: EdgeInsets.symmetric(horizontal: 10),
              width: double.infinity,
              child: KChartWidget(
                candlesArray,
                candleType: candleType,
                fractionDigits: widget.instrument.pricescale,
                getData: getData,
                authToken: widget.authToken,
                timeFrame: timeFrame,
                instrumentId: widget.instrument.id,
                candleResolution: candleResolution,
              ),
            ),
            if (showLoading)
              Container(
                  width: double.infinity,
                  height: 450,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator()),
          ]),
          buildButtons(),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: <Widget>[
              button("hour",
                  onPressed: () => changeResolution(ResolutionString.hour)),
              button("minute",
                  onPressed: () => changeResolution(ResolutionString.minute)),
              button("Day",
                  onPressed: () => changeResolution(ResolutionString.day)),
            ],
          )
        ],
      ),
    );
  }

  Widget buildButtons() {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      children: <Widget>[
        button("Area", onPressed: () => candleType = CandleTypeEnum.Area),
        button("Line", onPressed: () => candleType = CandleTypeEnum.Line),
        button("Candle", onPressed: () => candleType = CandleTypeEnum.Candle),
        // button("update", onPressed: () {
        //   datas.last.close += (Random().nextInt(100) - 50).toDouble();
        //   datas.last.high = max(datas.last.high, datas.last.close);
        //   datas.last.low = min(datas.last.low, datas.last.close);
        // }),
        // button("addData", onPressed: () {
        //   var kLineEntity = KLineEntity.fromJson(datas.last.toJson());
        //   kLineEntity.id += 60 * 60 * 24;
        //   kLineEntity.open = kLineEntity.close;
        //   kLineEntity.close += (Random().nextInt(100) - 50).toDouble();
        //   datas.last.high = max(datas.last.high, datas.last.close);
        //   datas.last.low = min(datas.last.low, datas.last.close);
        // }),
      ],
    );
  }

  Widget button(String text, {VoidCallback onPressed}) {
    return TextButton(
        onPressed: () {
          if (onPressed != null) {
            onPressed();
            setState(() {});
          }
        },
        child: Text("$text"),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blue),
            foregroundColor: MaterialStateProperty.all(Colors.black)));
  }

  void getData(String authToken, String resolution, String instrumentId) async {
    String result;
    showLoading = true;
    setState(() {});

    int delta = 0;
    if (candlesArray.length > 1) {
      delta = candlesArray.first.date - candlesArray[1].date;
    }

    var toDate = candlesArray.length > 0
        ? DateTime.fromMillisecondsSinceEpoch(candlesArray.first.date + delta,
            isUtc: true)
        : DateTime.now().toUtc();

    var calculatedHistoryDepth = DataFeedUtil.calculateHistoryDepth(resolution);

    var fromDate = toDate.subtract(calculatedHistoryDepth.intervalBackDuration);

    try {
      // await Future.delayed(Duration(seconds: 2));
      result = await httpService.getCandles(
          authToken, fromDate, toDate, resolution, instrumentId);
    } catch (e) {
      return Future.error('Error');
    } finally {
      List list = json.decode(result);
      var newCandles = list.map((item) => KLineEntity.fromJson(item)).toList();
      candlesArray = newCandles + candlesArray;
      showLoading = false;
      setState(() {});

      Future.delayed(Duration(seconds: 5), () {
        candlesArray = newCandles + candlesArray;
      });
    }
  }

  void changeResolution(String newResolution) {
    candlesArray.clear();
    candleResolution = newResolution;
    getData(widget.authToken, candleResolution, widget.instrument.id);
  }
}
