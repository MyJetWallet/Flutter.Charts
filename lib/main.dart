import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import './flutter_k_chart.dart';
import './k_chart_widget.dart';
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
        primarySwatch: Colors.grey,
      ),
      home: Chart(
        onResolutionChanged: (resolution) {},
        onChartTypeChanged: (chartType) {},
        candles: const [],
      ),
    );
  }

  Future<List<CandleModel>> mockCandles(BuildContext context) async {
    final data =
    await DefaultAssetBundle.of(context).loadString('candles_mock.json');
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
    required this.onChartTypeChanged,
    required this.candles,
    this.chartType = ChartType.candle,
    this.candleResolution = ResolutionString.minute,
  }) : super(key: key);

  final void Function(String) onResolutionChanged;
  final void Function(ChartType) onChartTypeChanged;
  final List<CandleModel> candles;
  final ChartType chartType;
  final String candleResolution;

  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  CandleEntity? selectedCandle;

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        children: <Widget>[
          // if (widget.chartType == ChartType.candle)
          //   Prices(selectedCandle)
          // else
          // Price(selectedCandle?.close),
          Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height * 0.6,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: double.infinity,
                child: KChartWidget(
                  widget.candles,
                  candleType: widget.chartType,
                  getData: (_, __, ___) {},
                  candleResolution: widget.candleResolution,
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
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: <Widget>[
              button(
                '1H',
                color: widget.candleResolution == ResolutionString.hour
                    ? Colors.blue.shade200
                    : null,
                onPressed: widget.candleResolution == ResolutionString.hour
                    ? null
                    : () =>
                    widget.onResolutionChanged(ResolutionString.hour),
              ),
              button(
                '1D',
                color: widget.candleResolution == ResolutionString.day
                    ? Colors.blue.shade200
                    : null,
                onPressed: widget.candleResolution == ResolutionString.day
                    ? null
                    : () =>
                    widget.onResolutionChanged(ResolutionString.day),
              ),
              button(
                '1W',
                color: widget.candleResolution == ResolutionString.week
                    ? Colors.blue.shade200
                    : null,
                onPressed: widget.candleResolution == ResolutionString.week
                    ? null
                    : () =>
                    widget.onResolutionChanged(ResolutionString.week),
              ),
              button(
                '1M',
                color: widget.candleResolution == ResolutionString.month
                    ? Colors.blue.shade200
                    : null,
                onPressed: widget.candleResolution == ResolutionString.month
                    ? null
                    : () =>
                    widget.onResolutionChanged(ResolutionString.month),
              ),
              button(
                '3M',
                color:
                widget.candleResolution == ResolutionString.threeMonth
                    ? Colors.blue.shade200
                    : null,
                onPressed: widget.candleResolution ==
                    ResolutionString.threeMonth
                    ? null
                    : () => widget
                    .onResolutionChanged(ResolutionString.threeMonth),
              ),
              button(
                '1Y',
                color: widget.candleResolution == ResolutionString.year
                    ? Colors.blue.shade200
                    : null,
                onPressed: widget.candleResolution == ResolutionString.year
                    ? null
                    : () =>
                    widget.onResolutionChanged(ResolutionString.year),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget button(
      String text, {
        VoidCallback? onPressed,
        Color? color,
      }) {
    return SizedBox(
      width: 0.15.sw,
      child: MaterialButton(
        onPressed: () {
          if (onPressed != null) {
            onPressed();
            setState(() {});
          }
        },
        color: color ?? Colors.blue,
        child: Text(text),
      ),
    );
  }
}
