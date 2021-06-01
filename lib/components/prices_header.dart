import 'package:charts/entity/candle_entity.dart';
import 'package:flutter/material.dart';

import '../entity/candle_model.dart';

class Prices extends StatelessWidget {
  const Prices(this.candle);

  final CandleEntity? candle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Open: ${candle?.open.toString()}',
          style: TextStyle(color: Colors.white),
        ),
        Text(
          'Close: ${candle?.close.toString()}',
          style: TextStyle(color: Colors.white),
        ),
        Text(
          'High: ${candle?.high.toString()}',
          style: TextStyle(color: Colors.white),
        ),
        Text(
          'Low: ${candle?.low.toString()}',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
