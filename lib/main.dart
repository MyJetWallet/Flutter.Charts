import 'dart:convert';

import 'package:flutter/material.dart';

import './flutter_k_chart.dart';
import './k_chart_widget.dart';
import 'components/price.dart';
import 'components/prices_header.dart';
import 'entity/candle_entity.dart';
import 'entity/candle_type_enum.dart';
import 'entity/resolution_string_enum.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: mockCandles(context),
        builder: (context, AsyncSnapshot<List<CandleModel>> data) {
          if (data.data != null) {
            return Chart(
              onResolutionChanged: (resolution) {},
              candles: data.data!,
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Future<List<CandleModel>> mockCandles(BuildContext context) async {
    final data =
        await DefaultAssetBundle.of(context).loadString('candles_mock');
    final newCandles = (json.decode(data) as List)
        .map((e) => CandleModel.fromJson(e))
        .toList();
    return newCandles;
  }
}

class Chart extends StatefulWidget {
  const Chart({
    Key? key,
    required this.onResolutionChanged,
    required this.candles,
  }) : super(key: key);

  final void Function(String) onResolutionChanged;
  final List<CandleModel> candles;

  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  CandleTypeEnum candleType = CandleTypeEnum.candle;
  String candleResolution = ResolutionString.minute;
  late CandleEntity? lastCandle;
  CandleEntity? selectedCandle;

  @override
  void initState() {
    super.initState();
    // getData(widget.authToken, candleResolution, widget.instrument.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (selectedCandle == null) {
      lastCandle =
          widget.candles.isNotEmpty ? widget.candles.last : CandleEntity();
    } else {
      lastCandle = selectedCandle;
    }

    return Scaffold(
      backgroundColor: const Color(0xff252736),
      body: ListView(
        children: <Widget>[
          if (candleType == CandleTypeEnum.candle)
            Prices(lastCandle)
          else
            Price(lastCandle?.close),
          Stack(
            children: <Widget>[
              Container(
                height: 600,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: double.infinity,
                child: KChartWidget(
                  widget.candles,
                  candleType: candleType,
                  getData: (_, __, ___) {},
                  candleResolution: candleResolution,
                  onCandleSelected: (CandleEntity? candle) {
                    WidgetsBinding.instance!.addPostFrameCallback((_) {
                      setState(() {
                        selectedCandle = candle;
                      });
                    });
                  },
                ),
              ),
            ],
          ),
          // buildButtons(),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: <Widget>[
              button('hour',
                  onPressed: () =>
                      widget.onResolutionChanged(ResolutionString.hour)),
              button('minute',
                  onPressed: () =>
                      widget.onResolutionChanged(ResolutionString.minute)),
              button('Day',
                  onPressed: () =>
                      widget.onResolutionChanged(ResolutionString.day)),
              button('Line', onPressed: () => candleType = CandleTypeEnum.line),
              button('Candle',
                  onPressed: () => candleType = CandleTypeEnum.candle),
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

// Future<void> getData(
//   String authToken,
//   String resolution,
//   String instrumentId,
// ) async {
//   late String result;
//   setState(() {});
//
//   var delta = 0;
//   if (candlesArray.length > 1) {
//     delta = candlesArray.first.date! - candlesArray[1].date!;
//   }
//
//   final toDate = candlesArray.isNotEmpty
//       ? DateTime.fromMillisecondsSinceEpoch(candlesArray.first.date! + delta,
//           isUtc: true)
//       : DateTime.now().toUtc();
//
//   final calculatedHistoryDepth =
//       DataFeedUtil.calculateHistoryDepth(resolution);
//
//   final fromDate =
//       toDate.subtract(calculatedHistoryDepth.intervalBackDuration);
//
//   try {
//     result = await httpService.getCandles(
//         authToken, fromDate, toDate, resolution, instrumentId);
//   } catch (e) {
//     return Future.error('Error');
//   } finally {
//     //TODO(Vova): fix
//     final newCandles = (json.decode(result) as List)
//         .map((e) => KLineEntity.fromJson(e))
//         .toList();
//     candlesArray = newCandles + candlesArray;
//     setState(() {});
//
//     Future.delayed(const Duration(seconds: 5), () {
//       candlesArray = newCandles + candlesArray;
//     });
//   }
// }
//
// void changeResolution(String newResolution) {
//   widget.onResolutionChanged(newResolution);
//   candlesArray.clear();
//   candleResolution = newResolution;
//   getData(widget.authToken, candleResolution, widget.instrument.id);
// }
}
