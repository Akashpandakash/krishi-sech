import 'package:flutter/material.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/core/localization/app_language.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/core/network/api_config.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/features/market/data/datasources/remote_mandi_price_data_source.dart';
import 'package:krishi_sech/features/market/data/datasources/remote_market_data_source.dart';
import 'package:krishi_sech/features/market/data/repositories/mandi_price_repository_impl.dart';
import 'package:krishi_sech/features/market/data/repositories/market_repository_impl.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';
import 'package:krishi_sech/features/market/domain/repositories/mandi_price_repository.dart';
import 'package:krishi_sech/features/market/domain/repositories/market_repository.dart';
import 'package:krishi_sech/features/market/presentation/market_product_text.dart';
import 'package:krishi_sech/features/market/presentation/widgets/mandi_prices_view.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key, this.repository, this.mandiRepository});

  final MarketRepository? repository;
  final MandiPriceRepository? mandiRepository;

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.krishiMarket,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                key: const Key('market_mandi_tab'),
                text: context.l10n.mandiPrices,
              ),
              Tab(
                key: const Key('market_shop_tab'),
                text: context.l10n.marketShop,
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MandiPricesView(
                  repository:
                      widget.mandiRepository ??
                      MandiPriceRepositoryImpl(
                        RemoteMandiPriceDataSource(
                          baseUrl: ApiConfig.baseUrl,
                          accessTokenProvider:
                              ({bool forceRefresh = false}) => AuthScope.of(
                                context,
                              ).getAccessToken(forceRefresh: forceRefresh),
                        ),
                      ),
                  location: LocationScope.of(context).location,
                ),
                ShopCatalogView(repository: widget.repository),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShopCatalogView extends StatefulWidget {
  const ShopCatalogView({super.key, this.repository});

  final MarketRepository? repository;

  @override
  State<ShopCatalogView> createState() => _ShopCatalogViewState();
}

class _ShopCatalogViewState extends State<ShopCatalogView> {
  MarketRepository? _repository;
  final _searchController = TextEditingController();
  List<MarketProduct> _products = const [];
  MarketCategory? _category;
  Object? _error;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Built here rather than in initState because the catalogue call needs an
    // access token and the app's language, both of which live above us.
    if (_repository != null) return;
    _repository =
        widget.repository ??
        MarketRepositoryImpl(
          RemoteMarketDataSource(
            baseUrl: ApiConfig.baseUrl,
            accessTokenProvider: ({bool forceRefresh = false}) =>
                AuthScope.of(
                  context,
                ).getAccessToken(forceRefresh: forceRefresh),
            languageProvider: () => AppLanguageCatalog.serviceCodeFor(
              LocaleScope.of(context).locale.languageCode,
            ),
          ),
        );
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _repository!.getProducts();
      if (!mounted) return;
      setState(() => _products = products);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MarketProduct> _filteredProducts(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    return _products
        .where((product) {
          final matchesCategory =
              _category == null || product.category == _category;
          final matchesQuery =
              query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              product.categoryName(context).toLowerCase().contains(query);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts(context);
    return SafeArea(
      child: CustomScrollView(
        key: const Key('market_scroll_view'),
        slivers: [
          SliverToBoxAdapter(
            child: ResponsiveContent(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('market_search_field'),
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: context.l10n.searchMarket,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: context.l10n.all,
                          selected: _category == null,
                          onSelected: () => setState(() => _category = null),
                        ),
                        for (final category in MarketCategory.values)
                          _CategoryChip(
                            key: Key('market_category_${category.name}'),
                            label: _categoryLabel(context, category),
                            selected: _category == category,
                            onSelected: () =>
                                setState(() => _category = category),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _MarketMessage(
                icon: Icons.cloud_off_outlined,
                message: _error is MarketRemoteFailure &&
                        (_error! as MarketRemoteFailure).type ==
                            MarketRemoteFailureType.offline
                    ? context.l10n.marketOffline
                    : context.l10n.marketLoadError,
                actionLabel: context.l10n.retry,
                onAction: _load,
              ),
            )
          else if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _MarketMessage(
                key: const Key('market_empty_state'),
                icon: _products.isEmpty
                    ? Icons.storefront_outlined
                    : Icons.search_off,
                // An empty catalogue is not a failed search: no seller has
                // listed anything yet, and telling a farmer to refine their
                // search would send them looking for something that is not there.
                message: _products.isEmpty
                    ? context.l10n.marketCatalogueEmpty
                    : context.l10n.noMarketProducts,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 600
                      ? 3
                      : 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) => _ProductCard(
                  product: products[index],
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.marketProductDetails,
                    arguments: products[index],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _categoryLabel(BuildContext context, MarketCategory category) =>
      switch (category) {
        MarketCategory.seeds => context.l10n.seeds,
        MarketCategory.fertilizers => context.l10n.fertilizers,
        MarketCategory.tools => context.l10n.tools,
      };
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AppPressable(
        haptic: AppPressableHaptic.selection,
        child: FilterChip(
          selected: selected,
          onSelected: (_) => onSelected(),
          label: Text(label),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final MarketProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: AppPressable(
        key: Key('market_product_${product.id}'),
        onTap: onTap,
        semanticLabel: product.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.lightGreen,
                child: Icon(product.icon, size: 58, color: AppColors.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.priceLabel(context),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketMessage extends StatelessWidget {
  const _MarketMessage({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
