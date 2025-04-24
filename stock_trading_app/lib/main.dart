import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stock_trading_app/firebase_options.dart';
import 'package:stock_trading_app/screens/welcome_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/stock_search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await dotenv.load(fileName: ".env");
    runApp(StockApp());
  } catch (e) {
    print("Firebase init error: $e");
  }
}

class StockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Trading App',
      theme: ThemeData.dark(),
      home: WelcomeLoginScreen(),
      routes: {
        '/search': (context) => StockSearchScreen(),
        '/favorites': (context) => FavoritesScreen(),
      },
    );
  }
}
