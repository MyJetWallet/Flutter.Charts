import 'dart:convert';

import 'package:flutter/material.dart';

import './flutter_k_chart.dart';
import './k_chart_widget.dart';
import 'components/price.dart';
import 'components/prices.dart';
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
              onChartTypeChanged: (chartType) {},
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
      backgroundColor: const Color(0xff252736),
      body: ListView(
        children: <Widget>[
          if (widget.chartType == ChartType.candle)
            Prices(selectedCandle)
          else
            Price(selectedCandle?.close),
          Stack(
            children: <Widget>[
              Container(
                height: 600,
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
                'hour',
                color: widget.candleResolution == ResolutionString.hour
                    ? Colors.blue.shade200
                    : null,
                onPressed: widget.candleResolution == ResolutionString.hour
                    ? null
                    : () => widget.onResolutionChanged(ResolutionString.hour),
              ),
              button(
                'minute',
                color: widget.candleResolution == ResolutionString.minute
                    ? Colors.blue.shade200
                    : null,
                onPressed: widget.candleResolution == ResolutionString.minute
                    ? null
                    : () => widget.onResolutionChanged(ResolutionString.minute),
              ),
              button(
                'day',
                color: widget.candleResolution == ResolutionString.day
                    ? Colors.blue.shade200
                    : null,
                onPressed: widget.candleResolution == ResolutionString.day
                    ? null
                    : () => widget.onResolutionChanged(ResolutionString.day),
              ),
              if (widget.chartType == ChartType.candle)
                button('Line',
                    onPressed: () => widget.onChartTypeChanged(ChartType.line))
              else
                button('Candle',
                    onPressed: () =>
                        widget.onChartTypeChanged(ChartType.candle)),
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
    return MaterialButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed();
          setState(() {});
        }
      },
      color: color ?? Colors.blue,
      child: Text(text),
    );
  }
}
