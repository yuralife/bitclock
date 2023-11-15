import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:wakelock/wakelock.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _binanceApiUrl =
      'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT';

  late Timer _timer;

  DateTime? _lastBtcPriceUpdate;
  int? btcPrice;
  bool loading = false;
  bool syncError = false;

  @override
  void initState() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() {});

      if (loading) {
        debugPrint('loading: $loading');
        return;
      }

      if (_lastBtcPriceUpdate == null ||
          DateTime.now().difference(_lastBtcPriceUpdate!).inMinutes > 0) {
        var newPrice = await _getBitcoinPrice();
        if (newPrice != null) {
          btcPrice = newPrice;
          _lastBtcPriceUpdate = DateTime.now();
          syncError = false;
        } else {
          syncError = true;
        }
      }
    });

    Wakelock.enable();

    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    children.add(_clockWidget());
    if (btcPrice != null) {
      children.addAll([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 64, vertical: 16),
          child: Divider(),
        ),
        _btcPrice(btcPrice!),
        const SizedBox(height: 4),
        _btcPriceLastUpdate(),
      ]);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateUI,
        backgroundColor: Colors.white.withOpacity(0.1),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _clockWidget() {
    var now = DateTime.now();

    return Text(
      DateFormat('HH:mm:ss').format(now),
      style: Theme.of(context).textTheme.headline1?.copyWith(fontSize: 192),
    );
  }

  Widget _btcPrice(int price) {
    return Text(
      '1 BTC = \$$price',
      style: Theme.of(context).textTheme.headline1?.copyWith(fontSize: 112),
    );
  }

  Widget _btcPriceLastUpdate() {
    if (_lastBtcPriceUpdate == null) {
      return const SizedBox();
    }

    var durationMinutes =
        DateTime.now().difference(_lastBtcPriceUpdate!).inMinutes;
    var durationSeconds =
        DateTime.now().difference(_lastBtcPriceUpdate!).inSeconds;

    late String result;
    if (durationMinutes <= 0) {
      result = '$durationSeconds sec ago';
    } else {
      result = '$durationMinutes min ago';
    }
    return Text(
      'Sync $result',
      style: const TextStyle(fontSize: 16, color: Colors.white38),
    );
  }

  Future<int?> _getBitcoinPrice() async {
    loading = true;

    var url = Uri.parse(_binanceApiUrl);
    var response = await http.get(url);
    debugPrint('Response status: ${response.body}');

    late int? priceInt;
    try {
      var responseMap = jsonDecode(response.body);
      var priceStr = responseMap['price'];
      var price = double.parse(priceStr);
      priceInt = price.toInt();
    } catch (e) {
      debugPrint(e.toString());
      priceInt = null;
    }

    loading = false;
    return priceInt;
  }

  void _updateUI() {
    _getBitcoinPrice();
  }
}
