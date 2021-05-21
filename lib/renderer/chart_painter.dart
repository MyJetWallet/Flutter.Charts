import 'dart:async' show StreamSink;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:charts/entity/candle_type_enum.dart';
import 'package:charts/entity/resolution_string_enum.dart';
import '../entity/k_line_entity.dart';
import '../entity/info_window_entity.dart';

import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'main_renderer.dart';

class ChartPainter extends BaseChartPainter {
  static get maxScrollX => BaseChartPainter.maxScrollX;
  BaseChartRenderer mMainRenderer;
  StreamSink<InfoWindowEntity> sink;
  AnimationController controller;
  double opacity;

  ChartPainter(
      {@required datas,
      @required scaleX,
      @required scrollX,
      @required isLongPass,
      @required selectX,
      this.sink,
      @required CandleTypeEnum candleType,
      @required String resolution,
      this.controller,
      this.opacity = 0.0})
      : super(
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPass,
            selectX: selectX,
            candleType: candleType,
            resolution: resolution);

  @override
  void initChartRenderer() {
    mMainRenderer ??= MainRenderer(mMainRect, mMainMaxValue, mMainMinValue,
        ChartStyle.topPadding, candleType, scaleX);
  }

  final Paint mBgPaint = Paint()..color = ChartColors.bgColor;

  @override
  void drawBg(Canvas canvas, Size size) {
    if (mMainRect != null) {
      Rect mainRect = Rect.fromLTRB(
          0, 0, mMainRect.width, mMainRect.height + ChartStyle.topPadding);
      canvas.drawRect(mainRect, mBgPaint);
    }
    Rect dateRect = Rect.fromLTRB(
        0, size.height - ChartStyle.bottomDateHigh, size.width, size.height);
    canvas.drawRect(dateRect, mBgPaint);
  }

  @override
  void drawGrid(canvas) {
    mMainRenderer?.drawGrid(
        canvas, ChartStyle.gridRows, ChartStyle.gridColumns);
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KLineEntity curPoint = datas[i];
      if (curPoint == null) continue;
      KLineEntity lastPoint = i == 0 ? curPoint : datas[i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
    }

    if (isLongPress == true) drawCrossLine(canvas, size);
    canvas.restore();
  }

  @override
  void drawRightText(canvas) {
    var textStyle = getTextStyle(ChartColors.yAxisTextColor);
    mMainRenderer?.drawRightText(canvas, textStyle, ChartStyle.gridRows);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    double columnSpace = size.width / ChartStyle.gridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double y = 0.0;
    for (var i = 0; i <= ChartStyle.gridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);
      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);
        if (datas[index] == null) continue;
        TextPainter tp = getTextPainter(getDate(datas[index].date),
            color: ChartColors.xAxisTextColor);
        y = size.height -
            (ChartStyle.bottomDateHigh - tp.height) / 2 -
            tp.height;
        tp.paint(canvas, Offset(columnSpace * i - tp.width / 2, y));
      }
    }
  }

  Paint selectPointPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 0.5
    ..color = ChartColors.markerBgColor;
  Paint selectorBorderPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = ChartColors.markerBorderColor;

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter tp = getTextPainter(format(point.close), color: Colors.white);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      Path path = new Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + 2 * w1, y + r);
      path.lineTo(textWidth + 2 * w1 + w2, y);
      path.lineTo(textWidth + 2 * w1, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      Path path = new Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    TextPainter dateTp =
        getTextPainter(getDate(point.date), color: Colors.white);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - ChartStyle.bottomDateHigh;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //Long press to show the details of this data
    sink?.add(InfoWindowEntity(point, isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //Long press to display the data being pressed
    if (isLongPress) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //Release to display the last data
    mMainRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (candleType == CandleTypeEnum.Area || candleType == CandleTypeEnum.Line)
      return;
    //Plot the maximum and minimum values
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //Draw right
      TextPainter tp = getTextPainter("— ${format(mMainLowMinValue)}",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter("${format(mMainLowMinValue)} —",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //Draw right
      TextPainter tp = getTextPainter("— ${format(mMainHighMaxValue)}",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter("${format(mMainHighMaxValue)} —",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = Colors.white12
      ..strokeWidth = ChartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);
    // k-line graph vertical line
    canvas.drawLine(Offset(x, ChartStyle.topPadding),
        Offset(x, size.height - ChartStyle.bottomDateHigh), paintY);

    Paint paintX = Paint()
      ..color = Colors.white
      ..strokeWidth = ChartStyle.hCrossWidth
      ..isAntiAlias = true;
    // k-line graph horizontal line
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
//    canvas.drawCircle(Offset(x, y), 2.0, paintX);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
        paintX);
  }

  final Paint realTimePaint = Paint()
        ..strokeWidth = 1.0
        ..isAntiAlias = true,
      pointPaint = Paint();

  @override
  void drawRealTimePrice(Canvas canvas, Size size) {
    if (mMarginRight == 0 || datas?.isEmpty == true) return;
    KLineEntity point = datas.last;
    TextPainter tp = getTextPainter(format(point.close),
        color: ChartColors.rightRealTimeTextColor);
    double y = getMainY(point.close);
    //The more the max slides to the right, the smaller the value
    var max = (mTranslateX.abs() +
            mMarginRight -
            getMinTranslateX().abs() +
            mPointWidth) *
        scaleX;
    double x = mWidth - max;
    if (candleType == CandleTypeEnum.Candle) x += mPointWidth / 2;
    var dashWidth = 10;
    var dashSpace = 5;
    double startX = 0;
    final space = (dashSpace + dashWidth);
    if (tp.width < max) {
      while (startX < max) {
        canvas.drawLine(
            Offset(x + startX, y),
            Offset(x + startX + dashWidth, y),
            realTimePaint..color = ChartColors.realTimeLineColor);
        startX += space;
      }
      //Flash and flash point last price
      if (candleType == CandleTypeEnum.Area ||
          candleType == CandleTypeEnum.Line) {
        startAnimation();
        Gradient pointGradient = RadialGradient(colors: [
          Colors.white.withOpacity(opacity ?? 0.0),
          Colors.transparent
        ]);
        pointPaint.shader = pointGradient
            .createShader(Rect.fromCircle(center: Offset(x, y), radius: 14.0));
        canvas.drawCircle(Offset(x, y), 14.0, pointPaint);
        canvas.drawCircle(
            Offset(x, y), 2.0, realTimePaint..color = Colors.white);
      } else {
        stopAnimation(); //Stop flashing
      }
      double left = mWidth - tp.width;
      double top = y - tp.height / 2;
      canvas.drawRect(
          Rect.fromLTRB(left, top, left + tp.width, top + tp.height),
          realTimePaint..color = ChartColors.realTimeBgColor);
      tp.paint(canvas, Offset(left, top));
    } else {
      stopAnimation(); //Stop flashing
      startX = 0;

      // TODO: autofitting to window
      if (point.close > mMainMaxValue) {
        y = getMainY(mMainMaxValue);
      } else if (point.close < mMainMinValue) {
        y = getMainY(mMainMinValue);
      }

      while (startX < mWidth) {
        canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y),
            realTimePaint..color = ChartColors.realTimeLongLineColor);
        startX += space;
      }

      const padding = 3.0;
      const triangleHeight = 8.0;
      const triangleWidth = 5.0;

      double left =
          mWidth - mWidth / ChartStyle.gridColumns - tp.width / 2 - padding * 2;
      double top = y - tp.height / 2 - padding;
      //Plus the width of the triangle and padding
      double right = left + tp.width + padding * 2 + triangleWidth + padding;
      double bottom = top + tp.height + padding * 2;
      double radius = (bottom - top) / 2;
      //Draw an ellipse background
      RRect rectBg1 =
          RRect.fromLTRBR(left, top, right, bottom, Radius.circular(radius));
      RRect rectBg2 = RRect.fromLTRBR(left - 1, top - 1, right + 1, bottom + 1,
          Radius.circular(radius + 2));
      canvas.drawRRect(
          rectBg2, realTimePaint..color = ChartColors.realTimeTextBorderColor);
      canvas.drawRRect(
          rectBg1, realTimePaint..color = ChartColors.realTimeBgColor);
      tp = getTextPainter(format(point.close),
          color: ChartColors.realTimeTextColor);
      Offset textOffset = Offset(left + padding, y - tp.height / 2);
      tp.paint(canvas, textOffset);
      //Draw a triangle
      Path path = Path();
      double dx = tp.width + textOffset.dx + padding;
      double dy = top + (bottom - top - triangleHeight) / 2;
      path.moveTo(dx, dy);
      path.lineTo(dx + triangleWidth, dy + triangleHeight / 2);
      path.lineTo(dx, dy + triangleHeight);
      path.close();
      canvas.drawPath(
          path,
          realTimePaint
            ..color = ChartColors.realTimeTextColor
            ..shader = null);
    }
  }

  TextPainter getTextPainter(text, {color = Colors.white}) {
    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    TextPainter tp =
        TextPainter(text: span, textDirection: ui.TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int date) {
    switch (resolution) {
      case ResolutionString.minute:
      case ResolutionString.hour:
        return DateFormat.Hm()
            .format(DateTime.fromMillisecondsSinceEpoch(date, isUtc: true));

      case ResolutionString.day:
        return DateFormat.d()
            .format(DateTime.fromMillisecondsSinceEpoch(date, isUtc: true));

      case ResolutionString.month:
        return DateFormat.Hm()
            .format(DateTime.fromMillisecondsSinceEpoch(date, isUtc: true));

      default:
        return "";
    }
  }

  double getMainY(double y) => mMainRenderer?.getY(y) ?? 0.0;

  startAnimation() {
    if (controller?.isAnimating != true) controller?.repeat(reverse: true);
  }

  stopAnimation() {
    if (controller?.isAnimating == true) controller?.stop();
  }
}
