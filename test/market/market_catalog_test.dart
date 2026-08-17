import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/app/router/app_router.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';
import 'package:krishi_sech/features/market/domain/repositories/mandi_price_repository.dart';
import 'package:krishi_sech/features/market/domain/repositories/market_repository.dart';
import 'package:krishi_sech/features/market/presentation/pages/market_page.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';

/// Shaped like real AGMARKNET rows: commodity names as published in English,
/// prices per quintal, and a trend only where an earlier day exists.
final _mandiFixtures = [
  MandiPrice(
    id: 'west bengal|purba bardhaman|burdwan krishak bazar|wheat|',
    commodity: 'Wheat',
    variety: 'Dara',
    state: 'West Bengal',
    district: 'Purba Bardhaman',
    marketName: 'Burdwan Krishak Bazar',
    minPrice: 2350,
    maxPrice: 2520,
    modalPrice: 2440,
    unit: 'quintal',
    arrivalDate: DateTime(2026, 8, 14),
    trend: PriceTrend.up,
    previousModalPrice: 2390,
  ),
  MandiPrice(
    id: 'west bengal|kolkata|koley market|potato|',
    commodity: 'Potato',
    state: 'West Bengal',
    district: 'Kolkata',
    marketName: 'Koley Market',
    minPrice: 1450,
    maxPrice: 1650,
    modalPrice: 1550,
    unit: 'quintal',
    arrivalDate: DateTime(2026, 8, 14),
    // No earlier price held yet, so no direction is claimed.
    trend: PriceTrend.unknown,
  ),
];

const _productFixtures = [
  MarketProduct(
    id: 'seed-lot-1',
    name: 'Premium Wheat Seeds',
    description: 'Certified HD-2967 wheat seed, 40 kg bag.',
    category: MarketCategory.seeds,
    price: 1250,
    unit: MarketUnit.bag,
    stockQuantity: 48,
    vendor: 'Burdwan Seeds Cooperative',
  ),
  MarketProduct(
    id: 'fert-lot-1',
    name: 'Organic Compost',
    description: 'Vermicompost for soil conditioning.',
    category: MarketCategory.fertilizers,
    price: 680,
    unit: MarketUnit.pack,
    stockQuantity: 32,
    vendor: 'Green Soil Organics',
  ),
];

void main() {
  testWidgets('Mandi Prices is the default Market tab', (tester) async {
    await _pumpMarket(tester);

    expect(find.byKey(const Key('mandi_prices_list')), findsOneWidget);
    expect(find.text('Wheat'), findsOneWidget);
    expect(find.text('Burdwan Krishak Bazar'), findsOneWidget);
    expect(find.text('Premium Wheat Seeds'), findsNothing);
  });

  testWidgets('Market switches between Mandi Prices and Shop', (tester) async {
    await _pumpMarket(tester);

    await _openShop(tester);
    expect(find.text('Premium Wheat Seeds'), findsOneWidget);

    await tester.tap(find.byKey(const Key('market_mandi_tab')));
    await tester.pumpAndSettle();
    expect(find.text('Burdwan Krishak Bazar'), findsOneWidget);
  });

  testWidgets('mandi prices show the arrival date, not the fetch time', (
    tester,
  ) async {
    await _pumpMarket(tester);

    expect(find.text('Price date: 14 Aug 2026'), findsNWidgets(2));
  });

  testWidgets('a price with no earlier day shows no trend arrow', (
    tester,
  ) async {
    await _pumpMarket(tester);

    // Wheat rose against a known previous day; Potato has no comparison, so
    // exactly one arrow is on screen.
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
    expect(find.byIcon(Icons.trending_flat), findsNothing);
    expect(find.byIcon(Icons.trending_down), findsNothing);
  });

  testWidgets('crop filter narrows mandi prices', (tester) async {
    await _pumpMarket(tester);

    await tester.tap(find.byKey(const Key('mandi_crop_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wheat').last);
    await tester.pumpAndSettle();

    expect(find.text('Burdwan Krishak Bazar'), findsOneWidget);
    expect(find.text('Koley Market'), findsNothing);
  });

  testWidgets('district filter narrows mandi prices', (tester) async {
    await _pumpMarket(tester);

    await tester.tap(find.byKey(const Key('mandi_district_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kolkata').last);
    await tester.pumpAndSettle();

    expect(find.text('Koley Market'), findsOneWidget);
    expect(find.text('Burdwan Krishak Bazar'), findsNothing);
  });

  testWidgets('no published prices reads differently from a filter miss', (
    tester,
  ) async {
    await _pumpMarket(tester, mandiPrices: const []);

    expect(find.byKey(const Key('mandi_empty_state')), findsOneWidget);
    expect(
      find.text('No mandi prices have been published for your state today.'),
      findsOneWidget,
    );
  });

  testWidgets('a degraded list is labelled as incomplete', (tester) async {
    await _pumpMarket(tester, mandiIsLive: false);

    // The rows are real and still shown — they are just not the whole market.
    expect(find.byKey(const Key('mandi_partial_notice')), findsOneWidget);
    expect(find.text('Burdwan Krishak Bazar'), findsOneWidget);
    expect(
      find.textContaining('not the full market today'),
      findsOneWidget,
    );
  });

  testWidgets('a live list carries no incompleteness warning', (tester) async {
    await _pumpMarket(tester);

    expect(find.byKey(const Key('mandi_partial_notice')), findsNothing);
  });

  testWidgets('an empty live response is not labelled partial', (tester) async {
    // count 0 with live true means the feed answered and there were no
    // arrivals — a different thing from a degraded answer.
    await _pumpMarket(tester, mandiPrices: const []);

    expect(find.byKey(const Key('mandi_partial_notice')), findsNothing);
    expect(
      find.text('No mandi prices have been published for your state today.'),
      findsOneWidget,
    );
  });

  testWidgets('without a farm location the mandi tab asks for one', (
    tester,
  ) async {
    await _pumpMarket(tester, location: null);

    expect(find.byKey(const Key('mandi_location_missing')), findsOneWidget);
    expect(
      find.text('Set your farm location to see mandi prices from your state.'),
      findsOneWidget,
    );
  });

  testWidgets('Mandi Prices fits a small physical-phone layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpMarket(tester);

    expect(find.byKey(const Key('mandi_prices_list')), findsOneWidget);
    expect(find.byKey(const Key('mandi_crop_filter')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product card opens Product Details and back returns to Market', (
    tester,
  ) async {
    await _pumpMarket(tester);
    await _openShop(tester);

    await tester.tap(find.byKey(const Key('market_product_seed-lot-1')));
    await tester.pumpAndSettle();

    expect(find.text('Product Details'), findsOneWidget);
    expect(find.text('Premium Wheat Seeds'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Krishi Market'), findsOneWidget);
  });

  testWidgets('Product Details renders complete catalog information', (
    tester,
  ) async {
    await _pumpMarket(tester);
    await _openShop(tester);
    await tester.tap(find.byKey(const Key('market_product_seed-lot-1')));
    await tester.pumpAndSettle();

    expect(find.text('Seeds'), findsOneWidget);
    expect(find.text('₹1250 / bag'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(
      find.text('Certified HD-2967 wheat seed, 40 kg bag.'),
      findsOneWidget,
    );
    expect(find.text('In stock (48 available)'), findsOneWidget);
    expect(find.text('Burdwan Seeds Cooperative'), findsOneWidget);
    expect(
      find.byKey(const Key('market_product_image_placeholder')),
      findsOneWidget,
    );
  });

  testWidgets('search filters the product catalog', (tester) async {
    await _pumpMarket(tester);
    await _openShop(tester);

    await tester.enterText(
      find.byKey(const Key('market_search_field')),
      'compost',
    );
    await tester.pump();

    expect(find.text('Organic Compost'), findsOneWidget);
    expect(find.text('Premium Wheat Seeds'), findsNothing);
  });

  testWidgets('category chip filters the product catalog', (tester) async {
    await _pumpMarket(tester);
    await _openShop(tester);

    await tester.tap(find.byKey(const Key('market_category_fertilizers')));
    await tester.pump();

    expect(find.text('Organic Compost'), findsOneWidget);
    expect(find.text('Premium Wheat Seeds'), findsNothing);
  });

  testWidgets('an empty catalogue is not reported as a failed search', (
    tester,
  ) async {
    await _pumpMarket(tester, products: const []);
    await _openShop(tester);

    expect(find.byKey(const Key('market_empty_state')), findsOneWidget);
    expect(
      find.text('No products have been listed yet. Please check back soon.'),
      findsOneWidget,
    );
    expect(find.text('No products match your search.'), findsNothing);
  });

  testWidgets('a search that matches nothing keeps the search wording', (
    tester,
  ) async {
    await _pumpMarket(tester);
    await _openShop(tester);

    await tester.enterText(
      find.byKey(const Key('market_search_field')),
      'tractor',
    );
    await tester.pump();

    expect(find.text('No products match your search.'), findsOneWidget);
  });
}

Future<void> _openShop(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('market_shop_tab')));
  await tester.pumpAndSettle();
}

Future<void> _pumpMarket(
  WidgetTester tester, {
  List<MarketProduct>? products,
  List<MandiPrice>? mandiPrices,
  bool mandiIsLive = true,
  FarmLocation? location = const FarmLocation(
    city: 'Burdwan',
    district: 'Purba Bardhaman',
    state: 'West Bengal',
  ),
}) async {
  final locationController = LocationController.inMemory(location: location);
  addTearDown(locationController.dispose);
  await tester.pumpWidget(
    LocationScope(
      controller: locationController,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: Scaffold(
          body: MarketPage(
            repository: _FakeMarketRepository(products ?? _productFixtures),
            mandiRepository: _FakeMandiPriceRepository(
              mandiPrices ?? _mandiFixtures,
              isLive: mandiIsLive,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeMarketRepository implements MarketRepository {
  const _FakeMarketRepository(this._products);

  final List<MarketProduct> _products;

  @override
  Future<List<MarketProduct>> getProducts() async => _products;

  @override
  Future<MarketProduct> getProduct(String id) async =>
      _products.firstWhere((product) => product.id == id);
}

class _FakeMandiPriceRepository implements MandiPriceRepository {
  const _FakeMandiPriceRepository(this._prices, {this.isLive = true});

  final List<MandiPrice> _prices;
  final bool isLive;

  @override
  Future<MandiPriceBoard> getPrices({
    required String state,
    String? district,
    String? commodity,
  }) async => MandiPriceBoard(prices: _prices, isLive: isLive);
}
