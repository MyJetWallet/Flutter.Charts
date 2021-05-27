import 'dart:convert';

import 'package:flutter/material.dart';

import './flutter_k_chart.dart';
import './k_chart_widget.dart';
import 'entity/candle_type_enum.dart';
import 'entity/instrument_entity.dart';
import 'entity/resolution_string_enum.dart';
import 'http/http_service.dart';
import 'utils/data_feed_util.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Chart(
        authToken:
            'e7yV5DsJX4WzJv6oYSfXDhlSnSgJDjszNI7zFrC80+Cjr4rYxdLtGxFp0+TQgFKdPKTE1W4oMbhPZdbHURzs5EALwUp55PZlKlhs326bWXi9gW+IMx5vgzds6k9cLRC9TbUnDh1/1lXC/s7TMkJ55WHSOY1YMPW5+eqeUbhU+kQdQbwUdGcCZ/6ITMdPxpLSZzKC4VTZyJeTaU7tpNdfAJ242U8P8u1aXnVv7jv6S3jkHSeZlDkkT8Fop1vyTFekEtlFu+crhwPRl49Fb4x+Qg==',
        instrument: Instrument('BTCUSD', 'BTCUSD', 2, []),
      ),
    );
  }
}

class Chart extends StatefulWidget {
  const Chart({
    Key? key,
    required this.authToken,
    required this.instrument,
  }) : super(key: key);

  final String authToken;
  final Instrument instrument;

  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  List<KLineEntity> candlesArray = <KLineEntity>[];
  bool showLoading = true;
  CandleTypeEnum candleType = CandleTypeEnum.candle;
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
      backgroundColor: const Color(0xff252736),
      body: ListView(
        children: <Widget>[
          Stack(children: <Widget>[
            Container(
              height: 600,
              margin: const EdgeInsets.symmetric(horizontal: 10),
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
                child: const CircularProgressIndicator(),
              ),
          ]),
          buildButtons(),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: <Widget>[
              button('hour',
                  onPressed: () => changeResolution(ResolutionString.hour)),
              button('minute',
                  onPressed: () => changeResolution(ResolutionString.minute)),
              button('Day',
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
        // button('Area', onPressed: () => candleType = CandleTypeEnum.area),
        button('Line', onPressed: () => candleType = CandleTypeEnum.line),
        button('Candle', onPressed: () => candleType = CandleTypeEnum.candle),
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

  Widget button(String text, {VoidCallback? onPressed}) {
    return TextButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed();
          setState(() {});
        }
      },
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.blue),
          foregroundColor: MaterialStateProperty.all(Colors.black)),
      child: Text(text),
    );
  }

  Future<void> getData(
    String authToken,
    String resolution,
    String instrumentId,
  ) async {
    late String result;
    showLoading = true;
    setState(() {});

    var delta = 0;
    if (candlesArray.length > 1) {
      delta = candlesArray.first.date! - candlesArray[1].date!;
    }

    final toDate = candlesArray.isNotEmpty
        ? DateTime.fromMillisecondsSinceEpoch(candlesArray.first.date! + delta,
            isUtc: true)
        : DateTime.now().toUtc();

    final calculatedHistoryDepth =
        DataFeedUtil.calculateHistoryDepth(resolution);

    final fromDate =
        toDate.subtract(calculatedHistoryDepth.intervalBackDuration);

    try {
      result = await httpService.getCandles(
          authToken, fromDate, toDate, resolution, instrumentId);
    } catch (e) {
      return Future.error('Error');
    } finally {
      //TODO(Vova): fix
      final newCandles = (json.decode(result) as List)
          .map((e) => KLineEntity.fromJson(e))
          .toList();
      candlesArray = newCandles + candlesArray;
      showLoading = false;
      setState(() {});

      Future.delayed(const Duration(seconds: 5), () {
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
