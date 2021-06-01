import 'package:charts/entity/candle_entity.dart';
import 'package:flutter/material.dart';

import '../entity/candle_model.dart';

class Price extends StatelessWidget {
  const Price(this.price);

  final double? price;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          price.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),

      ],
    );
  }
}
