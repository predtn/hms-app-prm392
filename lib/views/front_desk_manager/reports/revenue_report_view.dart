import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hms_app/models/dtos/revenue_report.dart';
import 'package:hms_app/repositories/report_repository.dart';
import 'package:hms_app/utils/format_vnd.dart';

class RevenueReportView extends StatefulWidget {
  const RevenueReportView({super.key});

  @override
  State<RevenueReportView> createState() => _RevenueReportViewState();
}

class _RevenueReportViewState extends State<RevenueReportView> {
  final _reportRepository = ReportRepository();
  late DateTime _fromDate;
  late DateTime _toDate;
  _RevenueChartRange _chartRange = _RevenueChartRange.oneMonth;
  late Future<RevenueReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate = DateTime(now.year, now.month, now.day);
    _fromDate = _toDate.subtract(
      Duration(days: _chartRange.days! - 1),
    );
    _reportFuture = _loadReport();
  }

  Future<RevenueReport> _loadReport() {
    return _reportRepository.getRevenueReport(
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  void _reloadReport() {
    setState(() {
      _reportFuture = _loadReport();
    });
  }

  void _applyChartRange(_RevenueChartRange range) {
    if (range == _chartRange) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _chartRange = range;
      _toDate = today;
      _fromDate = range.days == null
          ? DateTime(2020)
          : today.subtract(Duration(days: range.days! - 1));
      _reportFuture = _loadReport();
    });
  }

  Future<void> _refreshReport() async {
    setState(() {
      _reportFuture = _loadReport();
    });
    await _reportFuture;
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (range == null || !mounted) return;

    setState(() {
      _chartRange = _RevenueChartRange.max;
      _fromDate = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      _toDate = DateTime(range.end.year, range.end.month, range.end.day);
      _reportFuture = _loadReport();
    });
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo doanh thu'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _reloadReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<RevenueReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải báo cáo: ${snapshot.error}'));
          }

          final report = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshReport,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _DateRangeCard(
                  label:
                      '${_formatDate(report.fromDate)} - ${_formatDate(report.toDate)}',
                  onTap: _pickDateRange,
                ),
                const SizedBox(height: 16),
                _MetricCard(
                  title: 'Tổng doanh thu',
                  value: '${formatVND(report.totalRevenue)} đ',
                  icon: Icons.payments_outlined,
                  prominent: true,
                ),
                const SizedBox(height: 12),
                _RevenueTrendCard(
                  points: report.dailyPoints,
                  selectedRange: _chartRange,
                  onRangeChanged: _applyChartRange,
                ),
                const SizedBox(height: 12),
                _MetricGrid(
                  children: [
                    _MetricCard(
                      title: 'Tiền phòng',
                      value: '${formatVND(report.roomRevenue)} đ',
                      icon: Icons.bed_outlined,
                    ),
                    _MetricCard(
                      title: 'Dịch vụ',
                      value: '${formatVND(report.serviceRevenue)} đ',
                      icon: Icons.room_service_outlined,
                    ),
                    _MetricCard(
                      title: 'Phụ thu',
                      value: '${formatVND(report.extraRevenue)} đ',
                      icon: Icons.receipt_long_outlined,
                    ),
                    _MetricCard(
                      title: 'Booking checkout',
                      value: report.checkedOutBookingCount.toString(),
                      icon: Icons.logout_outlined,
                    ),
                    _MetricCard(
                      title: 'No-show',
                      value: report.noShowCount.toString(),
                      icon: Icons.event_busy_outlined,
                    ),
                    _MetricCard(
                      title: 'Tỷ lệ đang sử dụng',
                      value: _formatPercent(report.occupancyRate),
                      icon: Icons.hotel_outlined,
                      subtitle:
                          '${report.occupiedRoomCount}/${report.totalRoomCount} phòng',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _RevenueChartRange {
  sevenDays('7d', 7),
  oneMonth('1m', 30),
  threeMonths('3m', 90),
  sixMonths('6m', 180),
  oneYear('1y', 365),
  max('max', null);

  final String label;
  final int? days;

  const _RevenueChartRange(this.label, this.days);
}

class _RevenueTrendCard extends StatelessWidget {
  final List<RevenueDailyPoint> points;
  final _RevenueChartRange selectedRange;
  final ValueChanged<_RevenueChartRange> onRangeChanged;

  const _RevenueTrendCard({
    required this.points,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxRevenue = points.fold<int>(
      0,
      (max, point) => point.totalRevenue > max ? point.totalRevenue : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Xu hướng doanh thu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Icon(
                  Icons.download_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RevenueRangeSelector(
              selectedRange: selectedRange,
              onChanged: onRangeChanged,
            ),
            const SizedBox(height: 16),
            if (maxRevenue == 0)
              SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'Chưa có doanh thu trong khoảng này',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              _RevenueLineChart(
                points: points,
                maxRevenue: maxRevenue,
              ),
          ],
        ),
      ),
    );
  }
}

class _RevenueRangeSelector extends StatelessWidget {
  final _RevenueChartRange selectedRange;
  final ValueChanged<_RevenueChartRange> onChanged;

  const _RevenueRangeSelector({
    required this.selectedRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Khoảng hiển thị',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        for (final range in _RevenueChartRange.values)
          ChoiceChip(
            label: Text(range.label),
            selected: range == selectedRange,
            onSelected: (_) {
              if (range != selectedRange) {
                onChanged(range);
              }
            },
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  final List<RevenueDailyPoint> points;
  final int maxRevenue;

  const _RevenueLineChart({
    required this.points,
    required this.maxRevenue,
  });

  List<FlSpot> get _spots {
    if (points.length == 1) {
      final value = points.first.totalRevenue.toDouble();
      return [FlSpot(0, value), FlSpot(1, value)];
    }

    return [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].totalRevenue.toDouble()),
    ];
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _formatAxisRevenue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}m';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  bool _shouldShowBottomTitle(double value) {
    if (points.length <= 7) {
      return value % 1 == 0;
    }

    final interval = (points.length - 1) / 5;
    if (interval == 0) return value == 0;

    return (value / interval).roundToDouble() == value / interval ||
        value.round() == points.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spots = _spots;
    final maxY = (maxRevenue * 1.18).clamp(1, double.infinity).toDouble();
    final maxX = points.length == 1 ? 1.0 : (points.length - 1).toDouble();
    final gridColor = colorScheme.outlineVariant.withValues(alpha: 0.45);
    final mutedTextColor = colorScheme.onSurfaceVariant;

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: 0,
              maxY: maxY,
              backgroundColor: colorScheme.surface,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: maxY / 4,
                verticalInterval: points.length <= 7 ? 1 : points.length / 6,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: gridColor,
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: gridColor.withValues(alpha: 0.32),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: gridColor),
                  left: BorderSide(color: gridColor),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Text(
                      _formatAxisRevenue(value),
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: points.length <= 7 ? 1 : points.length / 6,
                    getTitlesWidget: (value, meta) {
                      if (!_shouldShowBottomTitle(value)) {
                        return const SizedBox.shrink();
                      }

                      final index = value.round();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatShortDate(points[index].date),
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.inverseSurface,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.round().clamp(0, points.length - 1);
                      final point = points[index];
                      return LineTooltipItem(
                        '${_formatShortDate(point.date)}\n'
                        '${formatVND(point.totalRevenue)} đ',
                        TextStyle(
                          color: colorScheme.onInverseSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.18,
                  barWidth: 2,
                  color: colorScheme.primary,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.22),
                        colorScheme.primary.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: 0,
              maxY: maxY,
              backgroundColor: colorScheme.surfaceContainerHighest,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 1,
                  color: colorScheme.primary,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: colorScheme.secondary.withValues(alpha: 0.24),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RevenueChartLegendDot(
              color: colorScheme.primary,
              label: 'Doanh thu',
            ),
            const SizedBox(width: 16),
            _RevenueChartLegendDot(
              color: colorScheme.secondary,
              label: 'Overview',
            ),
          ],
        ),
      ],
    );
  }
}

class _RevenueChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _RevenueChartLegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: 11),
        ),
      ],
    );
  }
}

class _DateRangeCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateRangeCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.date_range_outlined),
        title: const Text('Khoảng thời gian'),
        subtitle: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<Widget> children;

  const _MetricGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
        final childAspectRatio = constraints.maxWidth >= 720 ? 1.28 : 1.05;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final bool prominent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: prominent ? colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: prominent
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.primary,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    color: prominent
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            prominent ? colorScheme.onPrimaryContainer : null,
                      ),
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
