import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/coin_model.dart';
import '../utils/formatters.dart';

class CoinListItem extends StatelessWidget {
  final CoinModel coin;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;

  const CoinListItem({
    super.key,
    required this.coin,
    required this.isFavourite,
    required this.onTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = coin.priceChangePercentage24h >= 0;
    final changeColor = isPositive ? AppTheme.positive : AppTheme.negative;
    final changeIcon = isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Coin image
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: coin.image.isEmpty
                    ? const _CoinImageFallback()
                    : Image.network(
                        coin.image,
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) => const _CoinImageFallback(),
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : const _CoinImageFallback(),
                      ),
              ),
              const SizedBox(width: 12),
              // Name + symbol
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coin.name,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(coin.symbol.toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              // Price + change
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.price(coin.currentPrice),
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, color: changeColor, size: 16),
                      Text(
                        '${coin.priceChangePercentage24h.abs().toStringAsFixed(2)}%',
                        style: TextStyle(color: changeColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Favourite button
              GestureDetector(
                onTap: onFavouriteTap,
                child: Icon(
                  isFavourite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFavourite ? Colors.amber : AppTheme.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinImageFallback extends StatelessWidget {
  const _CoinImageFallback();

  @override
  Widget build(BuildContext context) => const CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.divider,
        child: Icon(Icons.currency_bitcoin, color: AppTheme.textSecondary),
      );
}
