import 'package:flutter/material.dart';

import '../services/trade_service.dart';
import '../widgets/pokemon_card_widget.dart';
import 'available_trades_screen.dart';

class TradeListScreen extends StatefulWidget {
  const TradeListScreen({super.key});

  @override
  State<TradeListScreen> createState() => _TradeListScreenState();
}

class _TradeListScreenState extends State<TradeListScreen> {
  final TradeService tradeService = TradeService();
  List<Map<String, dynamic>> uniqueCards = [];
  bool isLoading = false;
  int availableTradesCount = 0;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = tradeService.supabase.auth.currentUser!.id.toString();
    _fetchTrades();
    _fetchAvailableTradesCount();
  }

  Future<void> _fetchTrades() async {
    setState(() => isLoading = true);
    try {
      uniqueCards = await tradeService.fetchTrades();
      setState(() => isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nel caricamento dei trades: $e')));
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAvailableTradesCount() async {
    availableTradesCount = await tradeService.fetchAvailableTradesCount(currentUserId);
    if (mounted) setState(() {});
  }

  Future<void> _addTrade(String cardId, bool isWanted) async {
    try {
      await tradeService.addTrade(cardId, isWanted, currentUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isWanted ? 'Carta aggiunta ai cercati' : 'Carta aggiunta agli offerti'),
        ));
      }
      await _fetchTrades();
      await _fetchAvailableTradesCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nell\'aggiunta del trade: $e')));
      }
    }
  }

  Future<void> _removeTrade(String tradeId) async {
    try {
      await tradeService.removeTrade(tradeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trade rimosso con successo')));
      }
      await _fetchTrades();
      await _fetchAvailableTradesCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nella rimozione del trade: $e')));
      }
    }
  }

  void _navigateToAvailableTrades() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AvailableTradesScreen()));
  }

  void _showCardDetails(Map<String, dynamic> cardData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cardData['card']['name'], style: const TextStyle(fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(cardData['card']['image_url'] ?? '', width: 150, fit: BoxFit.contain),
              const SizedBox(height: 12),
              Text('Offerti (${cardData['offered_count']}):', style: const TextStyle(fontSize: 16)),
              ...cardData['offers'].map<Widget>((offer) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(offer['nickname'], style: const TextStyle(fontSize: 14)),
                    if (offer['user_id'] == currentUserId)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                        onPressed: () async {
                          await _removeTrade(offer['trade_id']);
                          if (mounted) Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Text('Cercati (${cardData['wanted_count']}):', style: const TextStyle(fontSize: 16)),
              ...cardData['wants'].map<Widget>((want) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(want['nickname'], style: const TextStyle(fontSize: 14)),
                    if (want['user_id'] == currentUserId)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                        onPressed: () async {
                          await _removeTrade(want['trade_id']);
                          if (mounted) Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutti i Trades', style: TextStyle(fontSize: 18)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _navigateToAvailableTrades,
                  child: const Text('Trades Possibili', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 4),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.swap_horizontal_circle, size: 30),
                      onPressed: _navigateToAvailableTrades,
                      tooltip: 'Visualizza Trades Possibili',
                    ),
                    if (availableTradesCount > 0)
                      Positioned(
                        left: 0,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            '$availableTradesCount',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : uniqueCards.isEmpty
          ? const Center(child: Text('Nessun trade disponibile al momento.', style: TextStyle(fontSize: 16)))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: uniqueCards.length,
        itemBuilder: (context, index) {
          final cardData = uniqueCards[index];
          final card = cardData['card'] as Map<String, dynamic>;
          final userOffers = cardData['offers'].where((o) => o['user_id'] == currentUserId).toList();
          final userWants = cardData['wants'].where((w) => w['user_id'] == currentUserId).toList();

          return PokemonCardWidget(
            imageUrl: card['image_url'] ?? '',
            name: card['name'] ?? 'Sconosciuto',
            isOfferedByUser: userOffers.isNotEmpty,
            isWantedByUser: userWants.isNotEmpty,
            offeredCount: cardData['offered_count'],
            wantedCount: cardData['wanted_count'],
            onTap: () => _showCardDetails(cardData),
            onOfferPressed: () async => await _addTrade(card['id'], false),
            onWantPressed: () async => await _addTrade(card['id'], true),
            onRemoveOfferPressed: userOffers.isNotEmpty
                ? () async => await _removeTrade(userOffers.first['trade_id'])
                : null,
            onRemoveWantPressed: userWants.isNotEmpty
                ? () async => await _removeTrade(userWants.first['trade_id'])
                : null,
          );
        },
      ),
    );
  }
}