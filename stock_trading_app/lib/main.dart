import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stock_trading_app/firebase_options.dart';
import '/screens/welcome_screen.dart';
import '/screens/dashboard_screen.dart';
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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.greenAccent,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent,
          ),
          iconTheme: IconThemeData(color: Colors.greenAccent),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white70,
          displayColor: Colors.greenAccent,
        ),
      ),

      home: WelcomeLoginScreen(),
      routes: {
        '/dashboard': (context) => DashboardScreen(),
        '/search': (context) => StockSearchScreen(),
        '/favorites': (context) => FavoritesScreen(),
      },
    );
  }
}
