import 'package:flutter/material.dart';
import 'package:my_app/entity/candle_type_enum.dart';
import 'package:my_app/entity/candle_entity.dart';
import 'base_chart_renderer.dart';

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  double mCandleWidth = ChartStyle.candleWidth;
  double mCandleLineWidth = ChartStyle.candleLineWidth;
  CandleTypeEnum candleType;

  double _contentPadding = 12.0;

  MainRenderer(Rect mainRect, double maxValue, double minValue,
      double topPadding, this.candleType, double scaleX)
      : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            scaleX: scaleX) {
    var diff = maxValue - minValue;
    var newScaleY = (chartRect.height - _contentPadding) /
        diff; //Content area height/difference = new scale
    var newDiff =
        chartRect.height / newScaleY; //High/new ratio = new difference
    var value = (newDiff - diff) /
        2; //New difference-difference / 2 = the value to be expanded on the y axis
    if (newDiff > diff) {
      this.scaleY = newScaleY;
      this.maxValue += value;
      this.minValue -= value;
    }
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    switch (candleType) {
      case CandleTypeEnum.Area:
      case CandleTypeEnum.Line:
        return;
      case CandleTypeEnum.Candle:
        TextSpan span;
        if (span == null) return;
        TextPainter tp =
            TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;
      default:
    }
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    switch (candleType) {
      case CandleTypeEnum.Candle:
        drawCandle(curPoint, canvas, curX);
        break;

      case CandleTypeEnum.Area:
        drawArea(lastPoint.close, curPoint.close, canvas, lastX, curX);
        break;

      case CandleTypeEnum.Line:
        drawLineChart(lastPoint.close, curPoint.close, canvas, lastX, curX);
        break;

      default:
    }
  }

  void drawArea(double lastPrice, double curPrice, Canvas canvas, double lastX,
      double curX) {
    final double mAreaLineStrokeWidth = 1.0;
    final Paint mAreaPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..color = ChartColors.kLineColor;
    final Paint mAreaFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    Path mAreaPath = Path();

    if (lastX == curX) lastX = 0; //Start position filling

    mAreaPath.moveTo(lastX, getY(lastPrice));
    mAreaPath.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2,
        getY(curPrice), curX, getY(curPrice));

    //Draw shadows
    Shader mAreaFillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: ChartColors.kLineShadowColor,
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mAreaFillPaint..shader = mAreaFillShader;

    Path mAreaFillPath = Path();

    mAreaFillPath.moveTo(lastX, chartRect.height + chartRect.top);
    mAreaFillPath.lineTo(lastX, getY(lastPrice));
    mAreaFillPath.cubicTo((lastX + curX) / 2, getY(lastPrice),
        (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    mAreaFillPath.lineTo(curX, chartRect.height + chartRect.top);
    mAreaFillPath.close();

    canvas.drawPath(mAreaFillPath, mAreaFillPaint);
    mAreaFillPath.reset();

    canvas.drawPath(
        mAreaPath,
        mAreaPaint
          ..strokeWidth = (mAreaLineStrokeWidth / scaleX).clamp(0.3, 1.0));
    mAreaPath.reset();
  }

  void drawLineChart(double lastPrice, double curPrice, Canvas canvas,
      double lastX, double curX) {
    final double mLineStrokeWidth = 1.0;
    final Paint mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..color = ChartColors.kLineColor;
    final Paint mLineFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    Path mLinePath = Path();

    if (lastX == curX) lastX = 0; //Start position filling

    mLinePath.moveTo(lastX, getY(lastPrice));
    mLinePath.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2,
        getY(curPrice), curX, getY(curPrice));

    Path mLineFillPath = Path();

    mLineFillPath.moveTo(lastX, chartRect.height + chartRect.top);

    mLineFillPath.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath.close();

    canvas.drawPath(mLineFillPath, mLineFillPaint);
    mLineFillPath.reset();

    canvas.drawPath(mLinePath,
        mLinePaint..strokeWidth = (mLineStrokeWidth / scaleX).clamp(0.3, 1.0));
    mLinePath.reset();
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = mCandleWidth / 2;
    double lineR = mCandleLineWidth / 2;

    //Prevent the line from being too thin and force the thinnest 1px
    if ((open - close).abs() < 1) {
      if (open > close) {
        open += 0.5;
        close -= 0.5;
      } else {
        open -= 0.5;
        close += 0.5;
      }
    }
    if (open > close) {
      chartPaint.color = ChartColors.upColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else {
      chartPaint.color = ChartColors.dnColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawRightText(canvas, textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      double position = 0;
      if (i == 0) {
        position = (gridRows - i) * rowSpace - _contentPadding / 2;
      } else if (i == gridRows) {
        position = (gridRows - i) * rowSpace + _contentPadding / 2;
      } else {
        position = (gridRows - i) * rowSpace;
      }
      var value = position / scaleY + minValue;
      TextSpan span = TextSpan(text: "${format(value)}", style: textStyle);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      double y;
      if (i == 0 || i == gridRows) {
        y = getY(value) - tp.height / 2;
      } else {
        y = getY(value) - tp.height;
      }
      tp.paint(canvas, Offset(chartRect.width - tp.width, y));
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + topPadding),
          Offset(chartRect.width, rowSpace * i + topPadding), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, topPadding / 3),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}
