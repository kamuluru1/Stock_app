import 'package:flutter/material.dart';
import 'package:stock_trading_app/firebase_options.dart';
import 'package:stock_trading_app/screens/favorites_screen.dart';
import 'screens/stock_search_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
