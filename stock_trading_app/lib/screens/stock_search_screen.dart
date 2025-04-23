import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class StockSearchScreen extends StatefulWidget {
  @override
  _StockSearchScreenState createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _searchResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Stocks")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter stock symbol (e.g., AAPL)',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchResult = _controller.text.toUpperCase();
                });
              },
              child: Text("Search"),
            ),
            if (_searchResult != null) ...[
              SizedBox(height: 20),
              Text("Result: $_searchResult"),
              ElevatedButton(
                onPressed: () async {
                  await FirestoreService().addFavoriteStock(_searchResult!);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Added to favorites")));
                },
                child: Text("Add to Favorites"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
