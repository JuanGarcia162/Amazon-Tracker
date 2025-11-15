import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/product.dart';
import '../config/app_colors.dart';
import '../utils/format_utils.dart';
import 'chart/chart_legend.dart';
import 'chart/price_stats_card.dart';

enum ChartPeriod {
  threeDays('3 días', 3),
  week('7 días', 7),
  twentyDays('20 días', 20),
  all('Todo', 0);

  final String label;
  final int days;

  const ChartPeriod(this.label, this.days);
}

class InteractivePriceChart extends StatefulWidget {
  final List<PriceHistory> priceHistory;
  final double? targetPrice;
  final double currentPrice;
  final double? originalPrice;

  const InteractivePriceChart({
    super.key,
    required this.priceHistory,
    this.targetPrice,
    required this.currentPrice,
    this.originalPrice,
  });

  @override
  State<InteractivePriceChart> createState() => _InteractivePriceChartState();
}

class _InteractivePriceChartState extends State<InteractivePriceChart> {
  ChartPeriod _selectedPeriod = ChartPeriod.week;
  int? _touchedIndex;

  List<PriceHistory> get _filteredHistory {
    if (_selectedPeriod == ChartPeriod.all) {
      return widget.priceHistory;
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: _selectedPeriod.days));
    return widget.priceHistory
        .where((h) => h.timestamp.isAfter(cutoffDate))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final history = _filteredHistory;
    
    if (history.isEmpty) {
      return Center(
        child: Text(
          'No hay datos para este período',
          style: TextStyle(color: AppColors.resolveTextSecondary(context)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Period selector - iOS Style
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: CupertinoSegmentedControl<ChartPeriod>(
            groupValue: _selectedPeriod,
            selectedColor: AppColors.primaryBlue,
            unselectedColor: AppColors.resolveCardBackground(context),
            borderColor: AppColors.primaryBlue,
            children: {
              for (var period in ChartPeriod.values)
                period: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    period.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: period == _selectedPeriod
                          ? CupertinoColors.white
                          : AppColors.primaryBlue,
                    ),
                  ),
                ),
            },
            onValueChanged: (ChartPeriod value) {
              setState(() {
                _selectedPeriod = value;
                _touchedIndex = null;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        
        // Price Statistics
        _buildPriceStatsCard(history),
        const SizedBox(height: 12),
        
        // Chart
        SizedBox(
          height: 280,
          child: _buildChart(history),
        ),
        
        // Chart Legend (line indicators)
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ChartLegend(showTargetPrice: widget.targetPrice != null),
        ),
        
        // Selected Point Legend
        if (_touchedIndex != null && _touchedIndex! < history.length) ...[
          const SizedBox(height: 16),
          _buildLegend(history[_touchedIndex!]),
        ] else ...[
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildChart(List<PriceHistory> history) {
    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    final prices = history.map((h) => h.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    
    // Ensure minimum range to avoid division by zero
    // Si maxPrice es 0, usar un rango por defecto de 10
    final effectiveRange = priceRange > 0.01 
        ? priceRange 
        : (maxPrice > 0 ? maxPrice * 0.1 : 10.0);
    final padding = effectiveRange * 0.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: effectiveRange / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.resolveSeparator(context),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.resolveSeparator(context),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: effectiveRange / 4,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '\$${value.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.resolveTextSecondary(context),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (history.length / 4).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= history.length) {
                  return const SizedBox();
                }
                final date = history[index].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    FormatUtils.shortDateFormat.format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.resolveTextSecondary(context),
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.resolveCardBorder(context),
            width: 1,
          ),
        ),
        minY: minPrice - padding,
        maxY: maxPrice + padding,
        lineTouchData: LineTouchData(
          enabled: true,
          // Aumentar el área de detección de toque
          touchSpotThreshold: 50, // Aumentado de default (~10) a 50 píxeles
          getTouchLineStart: (data, index) => 0,
          getTouchLineEnd: (data, index) => 0,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            setState(() {
              if (response == null || response.lineBarSpots == null) {
                _touchedIndex = null;
                return;
              }
              _touchedIndex = response.lineBarSpots!.first.spotIndex;
            });
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.primaryBlue,
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.all(12),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex != 0) return null; // Only show for main line
                
                final index = spot.spotIndex;
                final date = history[index].timestamp;
                final price = spot.y;
                
                // Determine special status
                final isMin = price == minPrice;
                final isMax = price == maxPrice;
                final isCurrent = index == history.length - 1;
                
                String label = '';
                if (isCurrent) {
                  label = '🟢 Actual';
                } else if (isMin) label = '🔵 Mínimo';
                else if (isMax) label = '🔴 Máximo';
                
                return LineTooltipItem(
                  '${label.isNotEmpty ? '$label\n' : ''}${FormatUtils.formatPrice(price)}\n${FormatUtils.chartDateFormat.format(date)}',
                  const TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: AppColors.primaryBlue,
                  strokeWidth: 3,
                  dashArray: [5, 5],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 8,
                      color: AppColors.primaryBlue,
                      strokeWidth: 3,
                      strokeColor: CupertinoColors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.chartLine,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isHighlighted = index == _touchedIndex;
                final price = history[index].price;
                
                // Determine if this is a special point
                final isMin = price == minPrice;
                final isMax = price == maxPrice;
                final isCurrent = index == history.length - 1;
                
                Color dotColor;
                double radius;
                double strokeWidth;
                
                if (isHighlighted) {
                  dotColor = AppColors.primaryBlue;
                  radius = 9;
                  strokeWidth = 3;
                } else if (isCurrent) {
                  dotColor = AppColors.discountGreen;
                  radius = 6;
                  strokeWidth = 2.5;
                } else if (isMin) {
                  dotColor = AppColors.primaryBlueLight;
                  radius = 6;
                  strokeWidth = 2.5;
                } else if (isMax) {
                  dotColor = AppColors.alertRed;
                  radius = 6;
                  strokeWidth = 2.5;
                } else {
                  dotColor = CupertinoColors.white;
                  radius = 4.5;
                  strokeWidth = 2;
                }
                
                return FlDotCirclePainter(
                  radius: radius,
                  color: dotColor,
                  strokeWidth: strokeWidth,
                  strokeColor: isHighlighted 
                      ? CupertinoColors.white 
                      : AppColors.primaryBlue,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.15),
                  AppColors.primaryBlue.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Current price line
          LineChartBarData(
            spots: [
              FlSpot(0, widget.currentPrice),
              FlSpot(spots.length - 1, widget.currentPrice),
            ],
            isCurved: false,
            color: AppColors.discountGreen,
            barWidth: 2,
            dashArray: [6, 3],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Min price line
          LineChartBarData(
            spots: [
              FlSpot(0, minPrice),
              FlSpot(spots.length - 1, minPrice),
            ],
            isCurved: false,
            color: AppColors.primaryBlueLight.withOpacity(0.6),
            barWidth: 1.5,
            dashArray: [4, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Max price line
          LineChartBarData(
            spots: [
              FlSpot(0, maxPrice),
              FlSpot(spots.length - 1, maxPrice),
            ],
            isCurved: false,
            color: AppColors.alertRed.withOpacity(0.6),
            barWidth: 1.5,
            dashArray: [4, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Target price line
          if (widget.targetPrice != null)
            LineChartBarData(
              spots: [
                FlSpot(0, widget.targetPrice!),
                FlSpot(spots.length - 1, widget.targetPrice!),
              ],
              isCurved: false,
              color: AppColors.chartTargetLine,
              barWidth: 2,
              dashArray: [8, 4],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceStatsCard(List<PriceHistory> history) {
    // Crear lista con todos los precios disponibles
    final allPrices = <double>[
      widget.currentPrice,
      if (widget.originalPrice != null) widget.originalPrice!,
      ...widget.priceHistory.map((h) => h.price),
    ];
    
    // Mínimo: el precio más bajo del historial (sin incluir originalPrice)
    final historicalPrices = widget.priceHistory.map((h) => h.price).toList();
    final minPrice = historicalPrices.isNotEmpty
        ? historicalPrices.reduce((a, b) => a < b ? a : b)
        : widget.currentPrice;
    
    // Máximo: el precio original (recomendado/tachado) si existe, sino el máximo del historial
    final maxPrice = widget.originalPrice ?? 
        (historicalPrices.isNotEmpty 
            ? historicalPrices.reduce((a, b) => a > b ? a : b)
            : widget.currentPrice);
    
    // Promedio: de todos los precios (historial + actual + original si existe)
    final avgPrice = allPrices.reduce((a, b) => a + b) / allPrices.length;

    return PriceStatsCard(
      currentPrice: widget.currentPrice,
      minPrice: minPrice,
      maxPrice: maxPrice,
      avgPrice: avgPrice,
    );
  }


  Widget _buildLegend(PriceHistory selectedPoint) {
    final history = _filteredHistory;
    final prices = history.map((h) => h.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    
    // Determine special status
    final isMin = selectedPoint.price == minPrice;
    final isMax = selectedPoint.price == maxPrice;
    final isCurrent = history.last.id == selectedPoint.id;
    
    String badge = '';
    Color badgeColor = AppColors.textPrimary;
    if (isCurrent) {
      badge = 'ACTUAL';
      badgeColor = AppColors.discountGreen;
    } else if (isMin) {
      badge = 'MÍNIMO';
      badgeColor = AppColors.primaryBlueLight;
    } else if (isMax) {
      badge = 'MÁXIMO';
      badgeColor = AppColors.alertRed;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.resolveImageBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.resolveCardBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row
          Row(
            children: [
              if (badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const Spacer(),
              Icon(
                CupertinoIcons.chart_bar_circle_fill,
                color: badgeColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Price section
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRECIO',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.resolveTextSecondary(context),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FormatUtils.formatPrice(selectedPoint.price),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.resolveCardBackground(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: AppColors.resolveTextSecondary(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FECHA Y HORA',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.resolveTextTertiary(context),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        FormatUtils.dateTimeFormat.format(selectedPoint.timestamp),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.resolveTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

