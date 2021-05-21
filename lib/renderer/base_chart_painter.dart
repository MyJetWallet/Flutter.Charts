import 'dart:math';
export 'package:flutter/material.dart'
    show Color, required, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:flutter/material.dart'
    show Color, required, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:charts/entity/candle_type_enum.dart';
import '../utils/date_format_util.dart';
import '../utils/number_util.dart';
import '../entity/k_line_entity.dart';
import '../chart_style.dart' show ChartStyle;

abstract class BaseChartPainter extends CustomPainter {
  static double maxScrollX = 0.0;
  List<KLineEntity> datas;

  double scaleX = 1.0, scrollX = 0.0, selectX;
  bool isLongPress = false;
  CandleTypeEnum candleType = CandleTypeEnum.Candle;

  Rect mMainRect;
  double mDisplayHeight, mWidth;

  int mStartIndex = 0, mStopIndex = 0;
  double mMainMaxValue = -double.maxFinite, mMainMinValue = double.maxFinite;
  double mVolMaxValue = -double.maxFinite, mVolMinValue = double.maxFinite;
  double mSecondaryMaxValue = -double.maxFinite,
      mSecondaryMinValue = double.maxFinite;
  double mTranslateX = -double.maxFinite;
  int mMainMaxIndex = 0, mMainMinIndex = 0;
  double mMainHighMaxValue = -double.maxFinite,
      mMainLowMinValue = double.maxFinite;
  int mItemCount = 0;
  double mDataLen = 0.0; //Data occupies the total length of the screen
  double mPointWidth = ChartStyle.pointWidth;
  List<String> mFormats = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ]; //Format time
  double mMarginRight = 0.0;

  String resolution; //The distance vacated on the right side of the k line

  BaseChartPainter(
      {@required this.datas,
      @required this.scaleX,
      @required this.scrollX,
      @required this.isLongPress,
      @required this.selectX,
      @required this.candleType,
      @required this.resolution}) {
    mItemCount = datas?.length ?? 0;
    mDataLen = mItemCount * mPointWidth;
    initFormats();
  }

  void initFormats() {
    if (mItemCount < 2) return;
    int firstTime = datas.first?.date ?? 0;
    int secondTime = datas[1]?.date ?? 0;
    int time = secondTime - firstTime;
    //Month
    if (time >= 24 * 60 * 60 * 28)
      mFormats = [yy, '-', mm];
    //day
    else if (time >= 24 * 60 * 60)
      mFormats = [yy, '-', mm, '-', dd];
    //hour
    else
      mFormats = [mm, '-', dd, ' ', HH, ':', nn];
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    mDisplayHeight =
        size.height - ChartStyle.topPadding - ChartStyle.bottomDateHigh;
    mWidth = size.width;
    mMarginRight = (mWidth / ChartStyle.gridColumns - mPointWidth) / scaleX;
    initRect(size);
    calculateValue();
    initChartRenderer();

    canvas.save();
    canvas.scale(1, 1);
    drawBg(canvas, size);
    drawGrid(canvas);
    if (datas != null && datas.isNotEmpty) {
      drawChart(canvas, size);
      drawRightText(canvas);
      drawRealTimePrice(canvas, size);
      drawDate(canvas, size);
      if (isLongPress == true) drawCrossLineText(canvas, size);
      drawText(canvas, datas?.last, 5);
      drawMaxAndMin(canvas);
    }
    canvas.restore();
  }

  void initChartRenderer();

  void drawBg(Canvas canvas, Size size);

  void drawGrid(canvas);

  void drawChart(Canvas canvas, Size size);

  void drawRightText(canvas);

  void drawDate(Canvas canvas, Size size);

  void drawText(Canvas canvas, KLineEntity data, double x);

  void drawMaxAndMin(Canvas canvas);

  void drawCrossLineText(Canvas canvas, Size size);

  void initRect(Size size) {
    double mainHeight = mDisplayHeight;

    mMainRect = Rect.fromLTRB(
        0, ChartStyle.topPadding, mWidth, ChartStyle.topPadding + mainHeight);
  }

  calculateValue() {
    if (datas == null || datas.isEmpty) return;
    maxScrollX = getMinTranslateX().abs();
    setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));
    for (int i = mStartIndex; i <= mStopIndex; i++) {
      var item = datas[i];
      getMainMaxMinValue(item, i);
    }
  }

  void getMainMaxMinValue(KLineEntity item, int i) {
    switch (candleType) {
      case CandleTypeEnum.Area:
      case CandleTypeEnum.Line:
        mMainMaxValue = max(mMainMaxValue, item.close);
        mMainMinValue = min(mMainMinValue, item.close);
        break;
      case CandleTypeEnum.Candle:
        double maxPrice = item.high, minPrice = item.low;

        mMainMaxValue = max(mMainMaxValue, maxPrice);
        mMainMinValue = min(mMainMinValue, minPrice);

        if (mMainHighMaxValue < item.high) {
          mMainHighMaxValue = item.high;
          mMainMaxIndex = i;
        }
        if (mMainLowMinValue > item.low) {
          mMainLowMinValue = item.low;
          mMainMinIndex = i;
        }
        break;
      default:
    }
  }

  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) =>
      _indexOfTranslateX(translateX, 0, mItemCount - 1);

  ///Binary search for the index of the current value
  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }
    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  ///Get the x coordinate according to the index
  ///+ mPointWidth / 2  Prevent incomplete display of the first and last bar
  ///@param position Index value
  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  Object getItem(int position) {
    if (datas != null) {
      return datas[position];
    } else {
      return null;
    }
  }

  ///scrollX Convert to TranslateX
  void setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  ///Get the minimum value of translation
  double getMinTranslateX() {
    var x = -mDataLen + mWidth / scaleX - mPointWidth / 2;
    x = x >= 0 ? 0.0 : x;
    //Less than one screen of data
    if (x >= 0) {
      if (mWidth / scaleX - getX(datas.length) < mMarginRight) {
        //After the data is filled, the remaining space is smaller than mMarginRight, find the difference. x-= difference
        x -= mMarginRight - mWidth / scaleX + getX(datas.length);
      } else {
        //After data is filled, the remaining space is larger than Right
        mMarginRight = mWidth / scaleX - getX(datas.length);
      }
    } else if (x < 0) {
      //More than one screen of data
      x -= mMarginRight;
    }
    return x >= 0 ? 0.0 : x;
  }

  ///Calculate the value of x after long press and convert it to index
  int calculateSelectedX(double selectX) {
    int mSelectedIndex = indexOfTranslateX(xToTranslateX(selectX));
    if (mSelectedIndex < mStartIndex) {
      mSelectedIndex = mStartIndex;
    }
    if (mSelectedIndex > mStopIndex) {
      mSelectedIndex = mStopIndex;
    }
    return mSelectedIndex;
  }

  ///translateX into x in view
  double translateXtoX(double translateX) =>
      (translateX + mTranslateX) * scaleX;

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: ChartStyle.defaultTextSize, color: color);
  }

  void drawRealTimePrice(Canvas canvas, Size size);

  String format(double n) {
    return NumberUtil.format(n);
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) {
    return true;
  }
}
