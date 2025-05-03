import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/firestore_service.dart';
import './chart.dart';

class StockSearchScreen extends StatefulWidget {
  @override
  _StockSearchScreenState createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<_Symbol> _results = [];
  bool _loading = false;
  Timer? _timer;

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
    setState(() {
      _loading = true;
      _results = [];
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
            SizedBox(height: 16),
            if (_loading)
              CircularProgressIndicator()
            else if (_results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final s = _results[index];
                    return ListTile(
                      title: Text(s.symbol),
                      subtitle: Text(s.description),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StockDetailScreen(symbol: s.symbol),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children:
                      _trendingSymbols.map((s) {
                        final price = _trendingPrices[s.symbol];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => StockDetailScreen(symbol: s.symbol),
                              ),
                            );
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
              ),
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

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({Key? key, required this.symbol}) : super(key: key);

  @override
  _StockDetailScreenState createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _quote;
  String? _error;

  final firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final token = dotenv.env['FINNHUB_API_KEY'];
    try {
      final profileUri = Uri.https('finnhub.io', '/api/v1/stock/profile2', {
        'symbol': widget.symbol,
        'token': token,
      });
      final quoteUri = Uri.https('finnhub.io', '/api/v1/quote', {
        'symbol': widget.symbol,
        'token': token,
      });
      final profileResp = await http.get(profileUri);
      final quoteResp = await http.get(quoteUri);
      final profileData = json.decode(profileResp.body);
      final quoteData = json.decode(quoteResp.body);
      if (!mounted) return;
      setState(() {
        _profile = profileData;
        _quote = quoteData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showCategoryDialog() async {
    final categories = ['Tech', 'Energy', 'Crypto', 'Finance', 'Other'];
    final selected = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('Select Category'),
            children:
                categories.map((category) {
                  return SimpleDialogOption(
                    child: Text(category),
                    onPressed: () => Navigator.pop(context, category),
                  );
                }).toList(),
          ),
    );
    if (selected != null) {
      try {
        await firestore.addFavoriteStock(widget.symbol, selected);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.symbol} added to $selected favorites'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add favorite: \$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol),
        actions: [
          IconButton(
            icon: Icon(Icons.star_border),
            tooltip: 'Add to Favorites',
            onPressed: _showCategoryDialog,
          ),
        ],
      ),
      body:
          _loading
              ? Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_profile?['logo'] != null) ...[
                      Image.network(_profile!['logo'], height: 80),
                      SizedBox(height: 12),
                    ],
                    Text(
                      _profile?['name'] ?? widget.symbol,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(widget.symbol, style: TextStyle(fontSize: 18)),
                    SizedBox(height: 16),
                    Text('Industry: ${_profile?['finnhubIndustry'] ?? 'N/A'}'),
                    SizedBox(height: 8),
                    Text(
                      'Market Cap: \$${_profile?['marketCapitalization']?.toStringAsFixed(2)} M',
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Current Price: \$${_quote?['c']?.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Open: \$${_quote?['o']?.toStringAsFixed(2)}'),
                    Text('High: \$${_quote?['h']?.toStringAsFixed(2)}'),
                    Text('Low: \$${_quote?['l']?.toStringAsFixed(2)}'),
                    SizedBox(height: 24),
                    StockPriceChart(symbol: widget.symbol),
                  ],
                ),
              ),
    );
  }
}
