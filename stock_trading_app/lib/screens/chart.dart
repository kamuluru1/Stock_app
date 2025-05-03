import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StockPriceChart extends StatefulWidget {
  final String symbol;
  const StockPriceChart({Key? key, required this.symbol}) : super(key: key);

  @override
  _StockPriceChartState createState() => _StockPriceChartState();
}

class _StockPriceChartState extends State<StockPriceChart> {
  List<FlSpot> _spots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    final apiKey = dotenv.env['ALPHA_VANTAGE_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('⚠️ Missing ALPHA_VANTAGE_KEY in .env');
      setState(() => _loading = false);
      return;
    }

    final uri = Uri.https(
      'www.alphavantage.co',
      '/query',
      {
        'function': 'TIME_SERIES_DAILY',
        'symbol': widget.symbol,
        'outputsize': 'compact',
        'apikey': apiKey,
      },
    );
    debugPrint('📈 AlphaV req → $uri');

    try {
      final resp = await http.get(uri);
      debugPrint('📈 AlphaV status → ${resp.statusCode}');
      final body = json.decode(resp.body) as Map<String, dynamic>;
      final series = body['Time Series (Daily)'] as Map<String, dynamic>?;

      if (series != null && series.isNotEmpty) {
        // take the last 30 days
        final entries = series.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final last30 = entries.takeLast(30).toList();
        final spots = <FlSpot>[];
        for (var i = 0; i < last30.length; i++) {
          final close = double.parse(last30[i].value['4. close']);
          spots.add(FlSpot(i.toDouble(), close));
        }
        setState(() {
          _spots = spots;
          _loading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('❌ AlphaV error: $e');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    if (_spots.isEmpty) return SizedBox(height: 200, child: Center(child: Text('No chart data available')));
    return SizedBox(
      height: 200,
      child: LineChart(LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.secondary,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            ),
          ),
        ],
      )),
    );
  }
}

// helper to grab the last N items of a list
extension<T> on List<T> {
  List<T> takeLast(int n) => sublist(length - n < 0 ? 0 : length - n);
}
