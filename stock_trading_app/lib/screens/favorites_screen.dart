import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/firestore_service.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final firestore = FirestoreService();
  final List<String> sampleCategories = [
    'Tech',
    'Energy',
    'Crypto',
    'Finance',
    'Other',
  ];
  final Map<String, double> _prices = {};

  @override
  void initState() {
    super.initState();
    _fetchAllPricesPeriodically();
  }

  Future<void> _fetchAllPricesPeriodically() async {
    while (mounted) {
      await _fetchAllPrices();
      await Future.delayed(Duration(seconds: 15));
    }
  }

  Future<void> _fetchAllPrices() async {
    final token = dotenv.env['FINNHUB_API_KEY'];
    final categorized = await firestore.getCategorizedFavorites().first;
    final symbols = categorized.values.expand((e) => e).toSet().toList();

    for (String symbol in symbols) {
      try {
        final uri = Uri.https('finnhub.io', '/api/v1/quote', {
          'symbol': symbol,
          'token': token,
        });
        final response = await http.get(uri);
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _prices[symbol] = (data['c'] as num?)?.toDouble() ?? 0;
        });
      } catch (e) {
        print('Failed to fetch price for $symbol: $e');
      }
    }
  }

  void _showDetails(String symbol) {
    final price = _prices[symbol];
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(symbol),
            content: Text(
              price != null
                  ? 'Current price: \$${price.toStringAsFixed(2)}'
                  : 'Price unavailable.',
            ),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Watchlist", style: TextStyle(color: Colors.greenAccent)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.greenAccent),
      ),
      body: StreamBuilder<Map<String, List<String>>>(
        stream: firestore.getCategorizedFavorites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final data = snapshot.data!;

          return ListView(
            padding: EdgeInsets.all(16),
            children:
                sampleCategories.map((category) {
                  final stocks = data[category] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                      SizedBox(height: 8),
                      stocks.isEmpty
                          ? Text(
                            "No favorites in this category yet.",
                            style: TextStyle(color: Colors.white54),
                          )
                          : Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children:
                                stocks.map((symbol) {
                                  final price = _prices[symbol];

                                  return GestureDetector(
                                    onTap: () => _showDetails(symbol),
                                    child: Container(
                                      width: 150,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.greenAccent,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            symbol,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            price != null
                                                ? '\$${price.toStringAsFixed(2)}'
                                                : 'Loading...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () async {
                                              await firestore
                                                  .deleteFavoriteStock(symbol);
                                              setState(() {
                                                _prices.remove(symbol);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                      SizedBox(height: 28),
                    ],
                  );
                }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/search'),
        backgroundColor: Colors.purple,
        child: Icon(Icons.search),
      ),
    );
  }
}
