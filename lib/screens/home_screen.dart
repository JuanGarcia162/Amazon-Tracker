import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../config/app_colors.dart';
import 'tabs/explore_screen.dart';
import 'tabs/favorites_screen.dart';
import 'tabs/discounts_screen.dart';
import 'tabs/alerts_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProductProvider? _productProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productProvider = context.read<ProductProvider>();
      _productProvider!.loadProducts(); // Load user favorites
      _productProvider!.loadAllSharedProducts(); // Load all shared products for explore
      _productProvider!.loadCollections(); // Load user collections
      _productProvider!.initializeRealtimeSubscriptions(); // Enable realtime updates
    });
  }

  @override
  void dispose() {
    // Clean up realtime subscriptions
    _productProvider?.disposeRealtimeSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: AppColors.resolveBarBackground(context),
        activeColor: AppColors.primaryBlue,
        inactiveColor: AppColors.tabInactive,
        height: 56,
        border: Border(
          top: BorderSide(
            color: AppColors.resolveSeparator(context),
            width: 0.5,
          ),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(CupertinoIcons.search, size: 26),
            ),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(CupertinoIcons.star_fill, size: 26),
            ),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(CupertinoIcons.tag_fill, size: 26),
            ),
            label: 'Ofertas',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(CupertinoIcons.bell_fill, size: 26),
            ),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(CupertinoIcons.gear_alt_fill, size: 26),
            ),
            label: 'Ajustes',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            switch (index) {
              case 0:
                return const ExploreScreen();
              case 1:
                return const FavoritesScreen();
              case 2:
                return const DiscountsScreen();
              case 3:
                return const AlertsScreen();
              case 4:
                return const SettingsScreen();
              default:
                return const ExploreScreen();
            }
          },
        );
      },
    );
  }
}
