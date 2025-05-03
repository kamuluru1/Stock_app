import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService firestore = FirestoreService();
  List<Map<String, dynamic>> _newsArticles = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchWatchlistNews();
  }

  Future<void> _fetchWatchlistNews() async {
    final token = dotenv.env['FINNHUB_API_KEY'];
    final today = DateTime.now();
    final from = today.subtract(Duration(days: 5));
    final fromStr = from.toIso8601String().split('T').first;
    final toStr = today.toIso8601String().split('T').first;

    final watchlist = await firestore.getCategorizedFavorites().first;
    final symbols = watchlist.values.expand((e) => e).toSet();
    print("Watchlist symbols: $symbols");

    final List<Map<String, dynamic>> allArticles = [];

    try {
      final marketUrl = Uri.parse(
        'https://finnhub.io/api/v1/news?category=general&token=$token',
      );
      final res = await http.get(marketUrl);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final articles = List<Map<String, dynamic>>.from(data);
        articles.sort((a, b) => b['datetime'].compareTo(a['datetime']));
        allArticles.addAll(
          articles.take(10).map((a) => {...a, 'symbol': 'MARKET'}),
        );
        print("Loaded general market news (${articles.length} total)");
      } else {
        print("Failed to fetch general news: ${res.statusCode}");
      }
    } catch (e) {
      print("Error fetching market news: $e");
    }

    for (final symbol in symbols) {
      final url = Uri.parse(
        'https://finnhub.io/api/v1/company-news?symbol=$symbol&from=$fromStr&to=$toStr&token=$token',
      );
      try {
        final res = await http.get(url);
        final data = json.decode(res.body);
        final articles = List<Map<String, dynamic>>.from(data);
        articles.sort((a, b) => b['datetime'].compareTo(a['datetime']));
        allArticles.addAll(
          articles.take(2).map((a) => {...a, 'symbol': symbol}),
        );
      } catch (e) {
        print("Error fetching news for $symbol: $e");
      }
    }

    allArticles.sort((a, b) => b['datetime'].compareTo(a['datetime']));
    if (!mounted) return;
    setState(() {
      _newsArticles = allArticles;
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final filterOptions = [
      'All',
      'Market News',
      ..._newsArticles
          .map((a) => a['symbol'])
          .where((s) => s != null && s != 'MARKET')
          .toSet()
          .cast<String>(),
    ];

    final filteredArticles =
        _newsArticles.where((article) {
          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Market News')
            return article['symbol'] == 'MARKET';
          return article['symbol'] == _selectedFilter;
        }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Welcome", style: TextStyle(color: Colors.greenAccent)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.greenAccent),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 340,
                child: Column(
                  children: [
                    Text(
                      "Hello, ${user?.email ?? 'Trader'} 👋",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/search');
                        _fetchWatchlistNews();
                      },
                      icon: Icon(Icons.search),
                      label: Text("Search Stocks"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: Size(320, 50),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/favorites');
                        _fetchWatchlistNews();
                      },
                      icon: Icon(Icons.star),
                      label: Text("View Favorites"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: Size(320, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Your News Feed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            SizedBox(height: 12),
            if (_newsArticles.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    dropdownColor: Colors.black,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    iconEnabledColor: Colors.greenAccent,
                    items:
                        filterOptions.map((symbol) {
                          return DropdownMenuItem<String>(
                            value: symbol,
                            child: Text(
                              symbol == 'MARKET' ? 'Market News' : symbol,
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedFilter = value ?? 'All');
                    },
                  ),
                ),
              ),
            SizedBox(height: 12),
            if (filteredArticles.isEmpty)
              Text(
                "No news available for the selected filter.",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              )
            else
              ...filteredArticles.map(
                (article) => Container(
                  constraints: BoxConstraints(minHeight: 200),
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['headline'] ?? 'No headline',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        article['summary']?.toString().trim().isEmpty ?? true
                            ? 'No summary available.'
                            : article['summary'],
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 6),
                      Text(
                        article['symbol'] == 'MARKET'
                            ? 'Market News'
                            : 'Symbol: ${article['symbol']}',
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                      SizedBox(height: 4),
                      if (article['datetime'] != null)
                        Text(
                          'Published: ${DateTime.fromMillisecondsSinceEpoch(article['datetime'] * 1000).toLocal().toString().split('.')[0]}',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
