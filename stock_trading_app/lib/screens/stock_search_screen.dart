import 'dart:async';
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
  double? _price;
  bool _priceLoading = false;
  String? _priceError;
  Timer? _timer;

  final Map<String, String> _suggestedCategories = {
    'AAPL': 'Tech',
    'GOOGL': 'Tech',
    'TSLA': 'Energy',
    'AMZN': 'Tech',
    'MSFT': 'Tech',
    'NFLX': 'Tech',
    'NVDA': 'Tech',
    'META': 'Tech',
    'BABA': 'Tech',
    'INTC': 'Tech',
  };

  final List<_Symbol> _trendingSymbols = [
    _Symbol('AAPL', 'Apple Inc.'),
    _Symbol('GOOGL', 'Alphabet Inc.'),
    _Symbol('TSLA', 'Tesla Inc.'),
    _Symbol('AMZN', 'Amazon.com Inc.'),
    _Symbol('MSFT', 'Microsoft Corp.'),
    _Symbol('NFLX', 'Netflix Inc.'),
    _Symbol('NVDA', 'NVIDIA Corp.'),
    _Symbol('META', 'Meta Platforms Inc.'),
    _Symbol('BABA', 'Alibaba Group'),
    _Symbol('INTC', 'Intel Corp.'),
  ];
  Map<String, double> _trendingPrices = {};

  @override
  void initState() {
    super.initState();
    _fetchTrendingPrices();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTrendingPrices() async {
    final token = dotenv.env['FINNHUB_API_KEY'];
    for (final stock in _trendingSymbols) {
      final uri = Uri.https('finnhub.io', '/api/v1/quote', {
        'symbol': stock.symbol,
        'token': token,
      });
      try {
        final resp = await http.get(uri);
        final data = json.decode(resp.body);
        final price = (data['c'] as num).toDouble();
        if (!mounted) return;
        setState(() {
          _trendingPrices[stock.symbol] = price;
        });
      } catch (e) {
        print("Trending fetch error for ${stock.symbol}: $e");
      }
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _results = [];
      _selected = null;
      _price = null;
      _priceError = null;
      _timer?.cancel();
    });

    final token = dotenv.env['FINNHUB_API_KEY'];
    final uri = Uri.https('finnhub.io', '/api/v1/search', {
      'q': query,
      'token': token,
    });

    try {
      final resp = await http.get(uri);
      final data = json.decode(resp.body);
      final List hits = data['result'] ?? [];
      if (!mounted) return;
      setState(() {
        _results =
            hits
                .map(
                  (e) => _Symbol(
                    e['symbol'] as String,
                    e['description'] as String,
                  ),
                )
                .toList();
      });
    } catch (e) {
      print("Search error: $e");
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchPrice(String symbol) async {
    if (!mounted) return;
    setState(() {
      _priceLoading = true;
      _priceError = null;
    });
    try {
      final token = dotenv.env['FINNHUB_API_KEY'];
      final uri = Uri.https('finnhub.io', '/api/v1/quote', {
        'symbol': symbol,
        'token': token,
      });
      final resp = await http.get(uri);
      final data = json.decode(resp.body);
      if (!mounted) return;
      setState(() {
        _price = (data['c'] as num).toDouble();
      });
    } catch (e) {
      print("Price fetch error: $e");
      if (!mounted) return;
      setState(() {
        _priceError = 'Failed to fetch price';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _priceLoading = false;
      });
    }
  }

  void _startAutoRefresh(String symbol) {
    _timer?.cancel();
    _fetchPrice(symbol);
    _timer = Timer.periodic(Duration(seconds: 5), (_) => _fetchPrice(symbol));
  }

  Future<void> _showCategoryDialog(String symbol) async {
    String? selectedCategory = _suggestedCategories[symbol] ?? 'Other';
    final categories = ['Tech', 'Energy', 'Crypto', 'Finance', 'Other'];

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Choose Category for $symbol'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return DropdownButton<String>(
                  value: selectedCategory,
                  items:
                      categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCategory != null) {
                    await FirestoreService().addFavoriteStock(
                      symbol,
                      selectedCategory!,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Added $symbol to favorites under $selectedCategory",
                        ),
                      ),
                    );
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Stocks")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
              SizedBox(height: 30),
              Text(
                "Trending Stocks",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children:
                    _trendingSymbols.map((s) {
                      final price = _trendingPrices[s.symbol];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selected = s.symbol;
                            _controller.text = s.symbol;
                            _results = [];
                          });
                          _startAutoRefresh(s.symbol);
                        },
                        child: Container(
                          width: 160,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.greenAccent),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                s.symbol,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                s.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                price != null
                                    ? "\$${price.toStringAsFixed(2)}"
                                    : "Loading...",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
              if (_selected != null) ...[
                SizedBox(height: 20),
                Text("Selected: $_selected", style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                if (_priceLoading)
                  CircularProgressIndicator()
                else if (_price != null)
                  Text(
                    "Price: \$${_price!.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                else if (_priceError != null)
                  Text(_priceError!, style: TextStyle(color: Colors.redAccent)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showCategoryDialog(_selected!),
                  child: Text("Add to Favorites"),
                ),
              ],
            ],
          ),
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
