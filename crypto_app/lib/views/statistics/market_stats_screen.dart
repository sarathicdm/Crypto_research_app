import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../viewmodels/market_stats_viewmodel.dart';
import '../../widgets/market_stat_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../utils/formatters.dart';

class MarketStatsScreen extends ConsumerWidget {
  const MarketStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketStatsViewModelProvider);
    final vm = ref.read(marketStatsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Market Statistics')),
      body: _buildBody(state, vm),
    );
  }

  Widget _buildBody(MarketStatsState state, MarketStatsViewModel vm) {
    if (state.isLoading) return const LoadingWidget();
    if (state.error != null) {
      return AppErrorWidget(message: state.error!, onRetry: vm.load);
    }
    if (state.stats == null) return const LoadingWidget();

    final stats = state.stats!;
    final changeColor =
        stats.marketCapChange24h >= 0 ? AppTheme.positive : AppTheme.negative;

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.card,
      onRefresh: vm.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Global Overview',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          MarketStatCard(
            label: 'Total Market Cap',
            value: Formatters.compactCurrency(stats.totalMarketCap),
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 10),
          MarketStatCard(
            label: '24h Trading Volume',
            value: Formatters.compactCurrency(stats.totalVolume),
            icon: Icons.swap_horiz_rounded,
          ),
          const SizedBox(height: 10),
          MarketStatCard(
            label: 'Market Cap Change (24h)',
            value:
                '${stats.marketCapChange24h >= 0 ? '+' : ''}${stats.marketCapChange24h.toStringAsFixed(2)}%',
            icon: Icons.trending_up_rounded,
            valueColor: changeColor,
          ),
          const SizedBox(height: 10),
          MarketStatCard(
            label: 'Active Cryptocurrencies',
            value: stats.activeCryptocurrencies.toString(),
            icon: Icons.currency_bitcoin_rounded,
          ),
          const SizedBox(height: 28),
          const Text('Market Dominance',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _DominancePieChart(
            btc: stats.btcDominance,
            eth: stats.ethDominance,
          ),
        ],
      ),
    );
  }
}


const _btcColor   = Color(0xFFF7931A);
const _ethColor   = Color(0xFF627EEA);
const _otherColor = Color(0xFF4A5568);

class _DominancePieChart extends StatefulWidget {
  final double btc;
  final double eth;
  const _DominancePieChart({required this.btc, required this.eth});

  @override
  State<_DominancePieChart> createState() => _DominancePieChartState();
}

class _DominancePieChartState extends State<_DominancePieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final other = (100 - widget.btc - widget.eth).clamp(0.0, 100.0);

    final sections = [
      (widget.btc, _btcColor, 'BTC'),
      (widget.eth, _ethColor, 'ETH'),
      (other,      _otherColor, 'Others'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider, width: 0.8),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 70,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touched = -1;
                            return;
                          }
                          _touched = response
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: sections.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      final isTouched = i == _touched;
                      return PieChartSectionData(
                        value: s.$1,
                        color: s.$2,
                        radius: isTouched ? 60 : 50,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _touched >= 0
                          ? sections[_touched].$3
                          : 'Total',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _touched >= 0
                          ? '${sections[_touched].$1.toStringAsFixed(1)}%'
                          : '100%',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: sections.map((s) => _LegendItem(
                  color: s.$2,
                  label: s.$3,
                  value: '${s.$1.toStringAsFixed(1)}%',
                )).toList(),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: sections.map((s) {
                return Flexible(
                  flex: s.$1.round().clamp(1, 100),
                  child: Container(height: 8, color: s.$2),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
