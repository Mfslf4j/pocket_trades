import 'package:flutter/material.dart';

import '../models/pokemon_card.dart';
import '../services/trade_service.dart';
import '../widgets/pokemon_card_widget.dart';
import 'trade_list_screen.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  final TradeService tradeService = TradeService();
  List<PokemonCard> cards = [];
  List<PokemonCard> filteredCards = [];
  bool isLoading = false;
  late String currentUserId;
  String searchQuery = '';
  String? selectedExpansion;

  @override
  void initState() {
    super.initState();
    final user = tradeService.supabase.auth.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    currentUserId = user.id.toString();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    setState(() => isLoading = true);
    try {
      cards = await tradeService.fetchCardsWithTradeCounts(currentUserId);
      _filterCards();
      setState(() => isLoading = false);
    } catch (e) {
      print('Errore in _fetchCards: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel caricamento delle carte. Riprova più tardi.')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  void _filterCards() {
    filteredCards = cards.where((card) {
      final matchesSearch = card.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesExpansion = selectedExpansion == null || card.expansion == selectedExpansion;
      return matchesSearch && matchesExpansion;
    }).toList();
  }

  Future<void> _addTrade(String cardId, bool isWanted) async {
    try {
      await tradeService.addTrade(cardId, isWanted, currentUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isWanted ? 'Carta aggiunta ai cercati' : 'Carta aggiunta agli offerti'),
        ));
      }
      await _fetchCards();
    } catch (e) {
      print('Errore in _addTrade: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nell\'aggiunta del trade: $e')));
      }
    }
  }

  Future<void> _removeTrade(String cardId) async {
    try {
      final tradeResponse = await tradeService.supabase
          .from('pokemon_trades')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('card_id', cardId)
          .single();
      final tradeId = tradeResponse['id'].toString();
      await tradeService.removeTrade(tradeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trade rimosso con successo')));
      }
      await _fetchCards();
    } catch (e) {
      print('Errore in _removeTrade: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nella rimozione del trade: $e')));
      }
    }
  }

  Future<void> _signOut() async {
    await tradeService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final expansions = cards.map((card) => card.expansion).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon TCG Trade', style: TextStyle(fontSize: 18)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TradeListScreen())),
                  child: const Row(
                    children: [
                      Icon(Icons.list_alt, size: 20),
                      SizedBox(width: 4),
                      Text('Tutti i Trades', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: _signOut,
                  tooltip: 'Esci',
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cerca carte...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _filterCards();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              hint: const Text('Seleziona espansione'),
              value: selectedExpansion,
              isExpanded: true,
              items: expansions.map((expansion) => DropdownMenuItem(value: expansion, child: Text(expansion))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedExpansion = value;
                  _filterCards();
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCards.isEmpty
                ? const Center(child: Text('Nessuna carta disponibile.', style: TextStyle(fontSize: 16)))
                : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filteredCards.length,
              itemBuilder: (context, index) {
                final card = filteredCards[index];
                return PokemonCardWidget(
                  imageUrl: card.imageUrl,
                  name: card.name,
                  isOfferedByUser: card.isOffered,
                  isWantedByUser: card.isWanted,
                  offeredCount: card.offeredCount ?? 0,
                  wantedCount: card.wantedCount ?? 0,
                  onOfferPressed: () async => await _addTrade(card.id, false),
                  onWantPressed: () async => await _addTrade(card.id, true),
                  onRemoveOfferPressed: () async => await _removeTrade(card.id),
                  onRemoveWantPressed: () async => await _removeTrade(card.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}