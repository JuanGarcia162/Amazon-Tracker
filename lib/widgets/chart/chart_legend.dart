import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

/// Leyenda del gráfico de precios
class ChartLegend extends StatelessWidget {
  final bool showTargetPrice;

  const ChartLegend({
    super.key,
    this.showTargetPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _ChartLegendItem(
          label: 'Actual',
          color: AppColors.discountGreen,
          dashArray: [6, 3],
        ),
        _ChartLegendItem(
          label: 'Mínimo',
          color: AppColors.primaryBlueLight.withOpacity(0.6),
          dashArray: [4, 4],
        ),
        _ChartLegendItem(
          label: 'Máximo',
          color: AppColors.alertRed.withOpacity(0.6),
          dashArray: [4, 4],
        ),
        if (showTargetPrice)
          _ChartLegendItem(
            label: 'Objetivo',
            color: AppColors.chartTargetLine,
            dashArray: [8, 4],
          ),
      ],
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final List<int> dashArray;

  const _ChartLegendItem({
    required this.label,
    required this.color,
    required this.dashArray,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(24, 2),
          painter: _DashedLinePainter(color: color, dashArray: dashArray),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.resolveTextPrimary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Painter para líneas punteadas en la leyenda
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final List<int> dashArray;

  _DashedLinePainter({required this.color, required this.dashArray});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final dashWidth = dashArray[0].toDouble();
    final dashSpace = dashArray[1].toDouble();

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
