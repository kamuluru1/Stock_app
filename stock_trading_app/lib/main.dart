import 'package:flutter/material.dart';
import 'package:stock_trading_app/screens/favorites_screen.dart';
import 'screens/stock_search_screen.dart';

void main() {
  runApp(StockApp());
}

class StockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Trading App',
      theme: ThemeData.dark(),
      home: FavoritesScreen(),
      routes: {'/search': (context) => StockSearchScreen()},
    );
  }
}
