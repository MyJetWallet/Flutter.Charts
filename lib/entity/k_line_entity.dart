import 'candle_entity.dart';

class CandleModel extends CandleEntity {
  CandleModel.fromJson(Map<String, dynamic> json) {
    open = (json['o'] as num?)?.toDouble();
    high = (json['h'] as num?)?.toDouble();
    low = (json['l'] as num?)?.toDouble();
    close = (json['c'] as num?)?.toDouble();
    date = (json['d'] as num?)?.toInt();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['open'] = open;
    data['close'] = close;
    data['high'] = high;
    data['low'] = low;
    data['date'] = date;
    return data;
  }

  @override
  String toString() {
    return 'MarketModel{open: $open, high: $high, low: $low, close: $close';
  }
}
