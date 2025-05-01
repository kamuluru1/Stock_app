import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StockDetailDialog extends StatefulWidget {
  final String symbol;

  const StockDetailDialog({super.key, required this.symbol});

  @override
  State<StockDetailDialog> createState() => _StockDetailDialogState();
}

class _StockDetailDialogState extends State<StockDetailDialog> {
  String _selectedRange = '1D';
  final List<String> _ranges = ['1D', '1W', '1M', '3M', 'YTD', 'Max'];

  Map<String, dynamic>? _quote;
  Map<String, dynamic>? _metrics;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final token = dotenv.env['FINNHUB_API_KEY'];
    final symbol = widget.symbol;

    try {
      final quoteResp = await http.get(
        Uri.https('finnhub.io', '/api/v1/quote', {
          'symbol': symbol,
          'token': token,
        }),
      );

      final metricsResp = await http.get(
        Uri.https('finnhub.io', '/api/v1/stock/metric', {
          'symbol': symbol,
          'metric': 'all',
          'token': token,
        }),
      );

      setState(() {
        _quote = json.decode(quoteResp.body);
        _metrics = json.decode(metricsResp.body)['metric'];
      });
    } catch (e) {
      print("Error fetching stock data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(20),
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.symbol,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),

              // Chart Placeholder
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Chart Placeholder",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              SizedBox(height: 10),

              // Timeline buttons
              Wrap(
                spacing: 6,
                children:
                    _ranges.map((range) {
                      final isSelected = _selectedRange == range;
                      return TextButton(
                        onPressed: () => setState(() => _selectedRange = range),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isSelected ? Colors.black : Colors.greenAccent,
                          backgroundColor:
                              isSelected
                                  ? Colors.greenAccent
                                  : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(range),
                      );
                    }).toList(),
              ),
              SizedBox(height: 16),

              // Stock Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Open", _quote?['o']?.toStringAsFixed(2) ?? "—"),
                  _infoRow("High", _quote?['h']?.toStringAsFixed(2) ?? "—"),
                  _infoRow("Low", _quote?['l']?.toStringAsFixed(2) ?? "—"),
                  _infoRow(
                    "Mkt Cap",
                    _formatBigNumber(_metrics?['marketCapitalization']),
                  ),
                  _infoRow(
                    "P/E Ratio",
                    _metrics?['peBasicExclExtraTTM']?.toStringAsFixed(2) ?? "—",
                  ),
                  _infoRow(
                    "Div Yield",
                    _metrics?['dividendYieldIndicatedAnnual']?.toStringAsFixed(
                          2,
                        ) ??
                        "—",
                  ),
                  _infoRow(
                    "52-wk High",
                    _metrics?['52WeekHigh']?.toStringAsFixed(2) ?? "—",
                  ),
                  _infoRow(
                    "52-wk Low",
                    _metrics?['52WeekLow']?.toStringAsFixed(2) ?? "—",
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Add to Favorites
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Add to favorites functionality
                },
                icon: Icon(Icons.star),
                label: Text("Add to Favorites"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  String _formatBigNumber(dynamic number) {
    if (number == null) return "—";
    final n = double.tryParse(number.toString());
    if (n == null) return "—";
    if (n >= 1e12) return "${(n / 1e12).toStringAsFixed(2)}T";
    if (n >= 1e9) return "${(n / 1e9).toStringAsFixed(2)}B";
    if (n >= 1e6) return "${(n / 1e6).toStringAsFixed(2)}M";
    return n.toStringAsFixed(2);
  }
}
