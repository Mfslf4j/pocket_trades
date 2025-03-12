import 'package:flutter/material.dart';

import '../services/trade_service.dart';
import '../widgets/pokemon_card_widget.dart';

class AvailableTradesScreen extends StatefulWidget {
  const AvailableTradesScreen({super.key});

  @override
  State<AvailableTradesScreen> createState() => _AvailableTradesScreenState();
}

class _AvailableTradesScreenState extends State<AvailableTradesScreen> {
  final TradeService tradeService = TradeService();
  List<Map<String, dynamic>> uniqueWantedCards = [];
  bool isLoading = false;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = tradeService.supabase.auth.currentUser!.id.toString();
    _fetchAvailableTrades();
  }

  Future<void> _fetchAvailableTrades() async {
    setState(() => isLoading = true);
    try {
      uniqueWantedCards = await tradeService.fetchAvailableTrades(currentUserId);
      setState(() => isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nel caricamento dei trades: $e')));
      }
      setState(() => isLoading = false);
    }
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
              Image.network(cardData['card']['image_url'] ?? '', width: 120, fit: BoxFit.cover),
              const SizedBox(height: 12),
              Text('Cercata da (${cardData['wanted_by'].length}):', style: const TextStyle(fontSize: 16)),
              ...cardData['wanted_by'].map<Widget>((want) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(want['user_nickname'], style: const TextStyle(fontSize: 14)),
                    Text(
                      'Offre: ${want['offered_card']['name']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        title: const Text('Trades Possibili', style: TextStyle(fontSize: 18)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : uniqueWantedCards.isEmpty
          ? const Center(child: Text('Nessun trade possibile al momento.', style: TextStyle(fontSize: 16)))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: uniqueWantedCards.length,
        itemBuilder: (context, index) {
          final cardData = uniqueWantedCards[index];
          final card = cardData['card'] as Map<String, dynamic>;

          return PokemonCardWidget(
            imageUrl: card['image_url'] ?? '',
            name: card['name'] ?? 'Sconosciuto',
            isOfferedByUser: false,
            isWantedByUser: false,
            offeredCount: 0,
            wantedCount: cardData['wanted_by'].length,
            onTap: () => _showCardDetails(cardData),
            onOfferPressed: null,
            onWantPressed: null,
            onRemoveOfferPressed: null,
            onRemoveWantPressed: null,
          );
        },
      ),
    );
  }
}