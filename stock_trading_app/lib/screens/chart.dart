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
  List<DateTime> _dates = [];
  bool _loading = true;
  String _timeframe = '1M';

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    setState(() => _loading = true);
    final apiKey = dotenv.env['ALPHA_VANTAGE_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('⚠️ Missing ALPHA_VANTAGE_KEY in .env');
      setState(() => _loading = false);
      return;
    }

    String function;
    String seriesKey;
    int limit;
    switch (_timeframe) {
      case '6M':
        function = 'TIME_SERIES_WEEKLY';
        seriesKey = 'Weekly Time Series';
        limit = 26;
        break;
      case '1Y':
        function = 'TIME_SERIES_MONTHLY';
        seriesKey = 'Monthly Time Series';
        limit = 12;
        break;
      case '1M':
      default:
        function = 'TIME_SERIES_DAILY';
        seriesKey = 'Time Series (Daily)';
        limit = 30;
    }

    final uri = Uri.https(
      'www.alphavantage.co',
      '/query',
      {
        'function': function,
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
      final series = body[seriesKey] as Map<String, dynamic>?;

      if (series != null && series.isNotEmpty) {
        final entries = series.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final selected = entries.takeLast(limit);
        final spots = <FlSpot>[];
        final dates = <DateTime>[];
        for (var i = 0; i < selected.length; i++) {
          final date = DateTime.parse(selected[i].key);
          final close = double.parse(selected[i].value['4. close']);
          spots.add(FlSpot(i.toDouble(), close));
          dates.add(date);
        }
        setState(() {
          _spots = spots;
          _dates = dates;
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
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['1M', '6M', '1Y'].map((tf) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ChoiceChip(
                  label: Text(tf),
                  selected: _timeframe == tf,
                  onSelected: (selected) {
                    if (selected && _timeframe != tf) {
                      setState(() => _timeframe = tf);
                      _fetchChartData();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        if (_loading)
          SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
        else if (_spots.isEmpty)
          SizedBox(height: 200, child: Center(child: Text('No chart data available')))
        else
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _dates.length) return Container();
                        final date = _dates[index];
                        String formatted;
                        switch (_timeframe) {
                          case '6M':
                          case '1Y':
                            formatted = '${date.month}/${date.year}';
                            break;
                          case '1M':
                          default:
                            formatted = '${date.month}/${date.day}';
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(formatted, style: TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (_spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) -
                          _spots.map((s) => s.y).reduce((a, b) => a < b ? a : b)) / 5,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(value.toStringAsFixed(2), style: TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
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
              ),
            ),
          ),
      ],
    );
  }
}

// helper to grab the last N items of a list
extension<T> on List<T> {
  List<T> takeLast(int n) => sublist(length - n < 0 ? 0 : length - n);
}
