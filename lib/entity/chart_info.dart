import 'candle_entity.dart';

class ChartInfo {
  ChartInfo({
    required this.left,
    required this.right,
    required this.candleResolution,
  });

  CandleEntity left;
  CandleEntity right;
  String candleResolution;
}