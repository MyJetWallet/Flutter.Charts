import 'package:flutter/material.dart' show Color;

class ChartColors {
  static const Color bgColor = Color(0xff272937);
  static const Color kLineColor = Color(0xff07fff2);
  static const Color gridColor = Color(0xff4f525e);
  static const List<Color> kLineShadowColor = [
    Color(0xff07FFF2),
    Color(0x1A07FFF2)
  ]; //gradient kline
  static const Color upColor = Color(0xff21b3a4);
  static const Color dnColor = Color(0xffec165c);

  static const Color yAxisTextColor = Color(0xff60738E);
  static const Color xAxisTextColor = Color(0xff60738E);

  static const Color maxMinTextColor = Color(0xffffffff);

  static const Color markerBorderColor = Color(0xff6C7A86);

  static const Color markerBgColor = Color(0xff0D1722);

  static const Color realTimeBgColor = Color(0xffffffff);
  static const Color rightRealTimeTextColor = Color(0xff4C86CD);
  static const Color realTimeTextBorderColor = Color(0xffffffff);
  static const Color realTimeTextColor = Color(0xff272937);

  static const Color realTimeLineColor = Color(0xffffffff);
  static const Color realTimeLongLineColor = Color(0xff4C86CD);
}

class ChartStyle {
  //between points
  static const double pointWidth = 11.0;

  static const double candleWidth = 8.5;

  static const double candleLineWidth = 1.5;

  //Vertical cross line width
  static const double vCrossWidth = 8.5;

  //Horizontal cross line width
  static const double hCrossWidth = 0.5;

  static const int gridRows = 3, gridColumns = 4;

  static const double topPadding = 30.0,
      bottomDateHigh = 20.0,
      childPadding = 25.0;

  static const double defaultTextSize = 10.0;
}
