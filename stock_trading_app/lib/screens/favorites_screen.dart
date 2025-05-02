import 'package:flutter/material.dart';
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
                                  return Container(
                                    width: 140,
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
                                    child: Center(
                                      child: Text(
                                        symbol,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
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
