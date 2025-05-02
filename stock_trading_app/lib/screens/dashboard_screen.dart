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

    final List<Map<String, dynamic>> allArticles = [];

    if (symbols.isNotEmpty) {
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
    } else {
      final url = Uri.parse(
        'https://finnhub.io/api/v1/news?category=general&token=$token',
      );
      try {
        final res = await http.get(url);
        final data = json.decode(res.body);
        final articles = List<Map<String, dynamic>>.from(data);
        articles.sort((a, b) => b['datetime'].compareTo(a['datetime']));
        allArticles.addAll(
          articles.take(10).map((a) => {...a, 'symbol': 'GENERAL'}),
        );
      } catch (e) {
        print("Error fetching general news: $e");
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
                      onPressed: () => Navigator.pushNamed(context, '/search'),
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
                      onPressed:
                          () => Navigator.pushNamed(context, '/favorites'),
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
            if (_newsArticles.isEmpty)
              Text(
                "No news available.",
                style: TextStyle(color: Colors.white70),
              )
            else
              ..._newsArticles.map(
                (article) => SizedBox(
                  height: 200,
                  child: Container(
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
                          'Symbol: ${article['symbol']}',
                          style: TextStyle(color: Colors.greenAccent),
                        ),
                        SizedBox(height: 4),
                        if (article['datetime'] != null)
                          Text(
                            'Published: ${DateTime.fromMillisecondsSinceEpoch(article['datetime'] * 1000).toLocal().toString().split('.')[0]}',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
