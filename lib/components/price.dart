import 'package:flutter/material.dart';

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
