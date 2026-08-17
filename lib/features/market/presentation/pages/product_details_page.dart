import 'package:flutter/material.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';
import 'package:krishi_sech/features/market/presentation/market_product_text.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key, required this.product});

  final MarketProduct product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.productDetails)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Container(
                    key: const Key('market_product_image_placeholder'),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      product.icon,
                      size: 96,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  product.categoryName(context),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.priceLabel(context),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 22),
                _DetailSection(
                  title: context.l10n.marketDescription,
                  value: product.description,
                ),
                _DetailSection(
                  title: context.l10n.marketAvailability,
                  value: product.isAvailable
                      ? context.l10n.marketInStock(product.stockQuantity)
                      : context.l10n.marketOutOfStock,
                  valueColor: product.isAvailable
                      ? AppColors.primary
                      : Colors.red,
                ),
                _DetailSection(
                  title: context.l10n.marketSeller,
                  value: product.vendor,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.marketCheckoutComingSoon,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.value,
    this.valueColor,
  });

  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: valueColor, height: 1.45)),
        ],
      ),
    );
  }
}
