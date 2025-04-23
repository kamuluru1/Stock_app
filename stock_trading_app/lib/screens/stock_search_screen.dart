import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/firestore_service.dart';

class StockSearchScreen extends StatefulWidget {
  @override
  _StockSearchScreenState createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<_Symbol> _results = [];
  bool _loading = false;
  String? _selected;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _results = [];
    });

    final token = dotenv.env['FINNHUB_API_KEY'];
    final uri = Uri.https(
      'finnhub.io',
      '/api/v1/search',
      {'q': query, 'token': token},
    );

    try {
      final resp = await http.get(uri);
      final data = json.decode(resp.body);
      final List hits = data['result'] ?? [];
      setState(() {
        _results = hits
            .map((e) => _Symbol(e['symbol'] as String, e['description'] as String))
            .toList();
      });
    } catch (e) {
      print("Search error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

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
                labelText: 'Enter company name or symbol',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            if (_loading) ...[
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ] else if (_results.isNotEmpty) ...[
              SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (_, i) {
                    final s = _results[i];
                    return ListTile(
                      title: Text(s.symbol),
                      subtitle: Text(s.description),
                      onTap: () {
                        setState(() {
                          _selected = s.symbol;
                          _results = [];
                          _controller.text = s.symbol;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            if (_selected != null) ...[
              SizedBox(height: 20),
              Text("Selected: $_selected", style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await FirestoreService().addFavoriteStock(_selected!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Added $_selected to favorites")),
                  );
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

class _Symbol {
  final String symbol;
  final String description;
  _Symbol(this.symbol, this.description);
}
