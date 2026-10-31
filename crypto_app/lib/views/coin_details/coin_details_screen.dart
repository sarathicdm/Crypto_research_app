import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../models/coin_detail_model.dart';
import '../../viewmodels/coin_details_viewmodel.dart';
import '../../viewmodels/watchlist_viewmodel.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../utils/formatters.dart';

class CoinDetailsScreen extends ConsumerWidget {
  final String coinId;
  final String coinName;

  const CoinDetailsScreen({
    super.key,
    required this.coinId,
    required this.coinName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coinDetailsViewModelProvider(coinId));
    final vm = ref.read(coinDetailsViewModelProvider(coinId).notifier);
    final isFav = ref
        .watch(watchlistViewModelProvider)
        .watchlistIds
        .contains(coinId);
    final watchlistVm = ref.read(watchlistViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: state.coin == null
            ? Text(coinName)
            : _AppBarTitle(coin: state.coin!),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFav ? Colors.amber : AppTheme.textSecondary,
            ),
            onPressed: () => watchlistVm.toggle(coinId),
          ),
        ],
      ),
      body: _buildBody(state, vm),
    );
  }

  Widget _buildBody(CoinDetailsState state, CoinDetailsViewModel vm) {
    if (state.isLoading && state.coin == null) return const LoadingWidget();
    if (state.error != null && state.coin == null) {
      return AppErrorWidget(message: state.error!, onRetry: vm.load);
    }
    if (state.coin == null) return const LoadingWidget();

    final coin = state.coin!;
    final isPositive = coin.priceChangePercentage24h >= 0;
    final changeColor = isPositive ? AppTheme.positive : AppTheme.negative;

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.card,
      onRefresh: vm.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Text(
                        Formatters.price(coin.currentPrice),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 2),

                      Icon(
                        isPositive
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: changeColor,
                        size: 20,
                      ),
                      Text(
                        '${coin.priceChangePercentage24h.abs().toStringAsFixed(2)}%  (24H)',
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              child: SizedBox(
                height: 220,
                child: state.isLoading
                    ? const LoadingWidget()
                    : state.chart != null
                    ? PriceChart(chart: state.chart!, isPositive: isPositive)
                    : const SizedBox.shrink(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              child: _PeriodSelector(state: state, vm: vm),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _InfoCard(coin: coin),
            ),

            if (coin.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AboutSection(description: coin.description),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  final CoinDetailModel coin;

  const _AppBarTitle({required this.coin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: coin.imageUrl.isEmpty
              ? const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.divider,
                  child: Icon(
                    Icons.currency_bitcoin,
                    color: AppTheme.textSecondary,
                    size: 14,
                  ),
                )
              : Image.network(
                  coin.imageUrl,
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.divider,
                    child: Icon(
                      Icons.currency_bitcoin,
                      color: AppTheme.textSecondary,
                      size: 14,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          coin.symbol.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}


class _PeriodSelector extends StatelessWidget {
  final CoinDetailsState state;
  final CoinDetailsViewModel vm;

  const _PeriodSelector({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    final periods = [(1, '1D'), (7, '1W'), (30, '1M'), (90, '3M')];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration:  BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppTheme.card
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = state.selectedDays == p.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => vm.changeChartPeriod(p.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  p.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class _InfoCard extends StatelessWidget {
  final CoinDetailModel coin;

  const _InfoCard({required this.coin});

  @override
  Widget build(BuildContext context) {
    final fdv = coin.totalSupply != null
        ? coin.currentPrice * coin.totalSupply!
        : coin.marketCap;
    final fdvRatio = fdv > 0 ? (coin.marketCap / fdv) : 1.0;

    final items = [
      ('Market Cap', Formatters.compactCurrency(coin.marketCap)),
      ('Circulating Supply', _supplyLabel(coin.circulatingSupply)),
      ('Fully Diluted Val.', Formatters.compactCurrency(fdv)),
      (
        'Total Supply',
        coin.totalSupply != null ? _supplyLabel(coin.totalSupply!) : '∞',
      ),
      ('Market Cap / FDV', fdvRatio.toStringAsFixed(2)),
      (
        'Max Supply',
        coin.totalSupply != null ? _supplyLabel(coin.totalSupply!) : '∞',
      ),
      ('Trading Volume', Formatters.compactCurrency(coin.totalVolume)),
      ('24H High', Formatters.price(coin.high24h)),
      ('24H Low', Formatters.price(coin.low24h)),
      ('', ''),
    ];

    final filtered = items
        .where((e) => e.$1.isNotEmpty || items.indexOf(e) < items.length - 1)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Info',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${coin.symbol.toUpperCase()} Stats',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider, width: 0.8),
          ),
          child: _InfoGrid(items: filtered),
        ),
      ],
    );
  }

  String _supplyLabel(double value) {
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(1)} Billion';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)} Million';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)} Thousand';
    return value.toStringAsFixed(0);
  }
}

class _InfoGrid extends StatelessWidget {
  final List<(String, String)> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final rows = <List<(String, String)>>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add([items[i], i + 1 < items.length ? items[i + 1] : ('', '')]);
    }

    return Column(
      children: rows.asMap().entries.map((entry) {
        final isLast = entry.key == rows.length - 1;
        final pair = entry.value;
        return Container(

          child: Row(
            children: [
              Expanded(
                child: _InfoCell(label: pair[0].$1, value: pair[0].$2),
              ),
              // Container(width: 0.6, height: 72, color: AppTheme.divider),
              Expanded(
                child: _InfoCell(label: pair[1].$1, value: pair[1].$2),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox(height: 72);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class _AboutSection extends StatefulWidget {
  final String description;

  const _AboutSection({required this.description});

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            widget.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          secondChild: Text(
            widget.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Read more',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
