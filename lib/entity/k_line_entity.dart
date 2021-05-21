import 'candle_entity.dart';

class KLineEntity extends CandleEntity {
  KLineEntity.fromJson(Map<String, dynamic> json) {
    open = (json['o'] as num)?.toDouble();
    high = (json['h'] as num)?.toDouble();
    low = (json['l'] as num)?.toDouble();
    close = (json['c'] as num)?.toDouble();
    date = (json['d'] as num)?.toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['open'] = this.open;
    data['close'] = this.close;
    data['high'] = this.high;
    data['low'] = this.low;
    data['date'] = this.date;
    return data;
  }

  @override
  String toString() {
    return 'MarketModel{open: $open, high: $high, low: $low, close: $close';
  }
}
