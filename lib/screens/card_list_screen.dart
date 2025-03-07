import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pokemon_card.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<PokemonCard> cards = [];
  List<PokemonCard> filteredCards = [];
  String searchQuery = '';
  String? selectedExpansion;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('pokemon_cards')
          .select()
          .order('expansion_number', ascending: true);

      if (response.isEmpty) {
        print('No data returned from Supabase');
      }

      setState(() {
        cards =
            (response as List)
                .map((json) => PokemonCard.fromJson(json))
                .toList();
        filteredCards = cards;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching cards: $e'); // Log dell'errore
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading cards: $e')));
      }
      setState(() => isLoading = false);
    }
  }

  void _filterCards() {
    setState(() {
      filteredCards =
          cards.where((card) {
            final matchesSearch = card.name.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            final matchesExpansion =
                selectedExpansion == null ||
                card.expansion == selectedExpansion;
            return matchesSearch && matchesExpansion;
          }).toList();
    });
  }

  Future<void> _toggleTradeStatus(PokemonCard card, bool isWanted) async {
    try {
      await supabase.from('pokemon_trades').upsert({
        'user_id': supabase.auth.currentUser?.id,
        'card_id': card.id,
        'is_wanted': isWanted,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Trade status updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating trade: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon TCG Trade'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildGroupedCardList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedCardList() {
    // Raggruppa le carte per codice espansione estratto dall'id
    Map<String, List<PokemonCard>> groupedCards = {};
    Map<String, String> codeToExpansionName =
        {}; // Mappa codice -> nome espansione
    for (var card in filteredCards) {
      String expansionCode =
          card.id.split('-')[0]; // Estrai il codice dall'id (es. "a1")
      groupedCards.putIfAbsent(expansionCode, () => []).add(card);
      // Associa il codice al nome dell'espansione (assume che sia lo stesso per tutte le carte del gruppo)
      codeToExpansionName[expansionCode] = card.expansion;
    }

    // Ottieni la lista dei codici espansione e ordinala
    List<String> sortedExpansions =
        groupedCards.keys.toList()
          ..sort((a, b) => a.compareTo(b)); // Ordinamento naturale per codice

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedExpansions.length,
      itemBuilder: (context, index) {
        String expansionCode = sortedExpansions[index];
        List<PokemonCard> expansionCards = groupedCards[expansionCode]!;
        String expansionName =
            codeToExpansionName[expansionCode]!; // Nome dell'espansione

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titolo dell'espansione (usiamo il nome)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                expansionName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Griglia delle carte per questa espansione
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: expansionCards.length,
              itemBuilder:
                  (context, cardIndex) =>
                      _buildCardItem(expansionCards[cardIndex]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search cards...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              searchQuery = value;
              _filterCards();
            },
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: selectedExpansion,
            hint: const Text('Select Expansion'),
            isExpanded: true,
            items:
                cards
                    .map((e) => e.expansion)
                    .toSet()
                    .map(
                      (expansion) => DropdownMenuItem(
                        value: expansion,
                        child: Text(expansion),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              selectedExpansion = value;
              _filterCards();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(PokemonCard card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          // L'immagine come sfondo che riempie tutta la card
          Positioned.fill(
            child: Image.network(
              card.imageUrl,
              fit: BoxFit.cover,
              // Immagine che copre tutta la card senza essere tagliata
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),

          // Informazioni sovrapposte sopra l'immagine
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                // Trasparenza per migliorare la leggibilità
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Non mostriamo più il nome
                  Text(
                    '${card.expansion} - #${card.expansionNumber}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                        ),
                        onPressed: () => _toggleTradeStatus(card, true),
                        tooltip: 'I want this',
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz, color: Colors.white),
                        onPressed: () => _toggleTradeStatus(card, false),
                        tooltip: 'I have this',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
