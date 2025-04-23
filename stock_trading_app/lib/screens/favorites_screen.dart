import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Favorites")),
      body: StreamBuilder<List<String>>(
        stream: firestore.getFavoriteStocks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          final favorites = snapshot.data!;
          return favorites.isEmpty
              ? Center(child: Text("No favorites yet"))
              : ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(favorites[index]));
                },
              );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/search'),
        child: Icon(Icons.search),
      ),
    );
  }
}
