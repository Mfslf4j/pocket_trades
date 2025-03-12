import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pokemon_card.dart';

class TradeService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetch all cards for CardListScreen
  Future<List<PokemonCard>> fetchCards(String userId) async {
    try {
      final response = await supabase.from('pokemon_cards').select();
      final tradesResponse = await supabase
          .from('pokemon_trades')
          .select('card_id, is_wanted')
          .eq('user_id', userId);

      final List<PokemonCard> fetchedCards = (response as List).map((card) => PokemonCard.fromJson(card)).toList();
      final trades = (tradesResponse as List).map((trade) => {'card_id': trade['card_id'], 'is_wanted': trade['is_wanted']}).toList();

      for (var card in fetchedCards) {
        final trade = trades.firstWhere((t) => t['card_id'] == card.id, orElse: () => {});
        if (trade.isNotEmpty) {
          card.isWanted = trade['is_wanted'] as bool;
          card.isOffered = !trade['is_wanted'] as bool;
        }
      }
      return fetchedCards;
    } catch (e) {
      print('Errore nel caricamento delle carte: $e');
      rethrow;
    }
  }

  Future<List<PokemonCard>> fetchCardsWithTradeCounts(String userId) async {
    try {
      // Recupera tutte le carte e i relativi trades
      final response = await supabase.from('pokemon_cards').select('''
      id, name, image_url, expansion,
      pokemon_trades!card_id(is_wanted, user_id)
    ''');

      return response.map((data) {
        final card = PokemonCard.fromJson(data);
        final trades = data['pokemon_trades'] as List<dynamic>? ?? [];
        card.offeredCount = trades.where((t) => !t['is_wanted']).length;
        card.wantedCount = trades.where((t) => t['is_wanted']).length;
        card.isOffered = trades.any((t) => !t['is_wanted'] && t['user_id'] == userId);
        card.isWanted = trades.any((t) => t['is_wanted'] && t['user_id'] == userId);
        return card;
      }).toList();
    } catch (e) {
      print('Errore in fetchCardsWithTradeCounts: $e');
      rethrow;
    }
  }

  // Fetch trades for TradeListScreen
  Future<List<Map<String, dynamic>>> fetchTrades() async {
    try {
      final response = await supabase
          .from('pokemon_trades')
          .select('''
            id, 
            user_id, 
            card_id, 
            is_wanted, 
            created_at, 
            pokemon_cards (id, name, image_url, expansion, expansion_number)
          ''')
          .order('card_id', ascending: true);

      final tradesList = (response as List).map((trade) {
        return {
          'id': trade['id'].toString(),
          'user_id': trade['user_id'].toString(),
          'card_id': trade['card_id'].toString(),
          'is_wanted': trade['is_wanted'] as bool,
          'created_at': trade['created_at'] as String,
          'pokemon_cards': trade['pokemon_cards'] as Map<String, dynamic>,
          'nickname': '',
        };
      }).toList();

      final userIds = tradesList.map((trade) => trade['user_id'] as String).toSet().toList();
      final nicknameResponses = await Future.wait(
        userIds.map((userId) async {
          final response = await supabase.rpc('get_nickname', params: {'user_id': userId});
          return {'user_id': userId, 'nickname': response ?? 'Unknown User'};
        }),
      );
      final nicknameMap = {for (var item in nicknameResponses) item['user_id'] as String: item['nickname'] as String};

      for (var trade in tradesList) {
        trade['nickname'] = nicknameMap[trade['user_id']] ?? 'Unknown User';
      }

      final cardMap = <String, Map<String, dynamic>>{};
      for (var trade in tradesList) {
        final cardId = trade['card_id'] as String;
        if (!cardMap.containsKey(cardId)) {
          cardMap[cardId] = {
            'card': trade['pokemon_cards'],
            'offered_count': 0,
            'wanted_count': 0,
            'offers': [],
            'wants': [],
          };
        }

        final cardData = cardMap[cardId]!;
        if (trade['is_wanted'] as bool) {
          cardData['wanted_count'] = (cardData['wanted_count'] as int) + 1;
          cardData['wants'].add({
            'nickname': trade['nickname'],
            'trade_id': trade['id'],
            'user_id': trade['user_id'],
          });
        } else {
          cardData['offered_count'] = (cardData['offered_count'] as int) + 1;
          cardData['offers'].add({
            'nickname': trade['nickname'],
            'trade_id': trade['id'],
            'user_id': trade['user_id'],
          });
        }
      }

      return cardMap.values.toList();
    } catch (e) {
      print('Errore nel caricamento dei trades: $e');
      rethrow;
    }
  }

  // Fetch available trades for AvailableTradesScreen
  Future<List<Map<String, dynamic>>> fetchAvailableTrades(String userId) async {
    try {
      final response = await supabase.rpc('get_available_trades', params: {'current_user_id': userId});
      final trades = (response as List).cast<Map<String, dynamic>>();
      final cardMap = <String, Map<String, dynamic>>{};

      for (var trade in trades) {
        final wantedCard = trade['wanted_card'] as Map<String, dynamic>;
        final cardId = wantedCard['id'].toString();

        if (!cardMap.containsKey(cardId)) {
          cardMap[cardId] = {
            'card': wantedCard,
            'wanted_by': [],
          };
        }

        final cardData = cardMap[cardId]!;
        cardData['wanted_by'].add({
          'user_nickname': trade['other_user_nickname'],
          'offered_card': trade['offered_card'],
        });
      }

      return cardMap.values.toList();
    } catch (e) {
      print('Errore nel caricamento dei trades disponibili: $e');
      rethrow;
    }
  }

  // Fetch count of available trades
  Future<int> fetchAvailableTradesCount(String userId) async {
    try {
      final response = await supabase.rpc('get_available_trades_count', params: {'current_user_id': userId});
      return response as int? ?? 0;
    } catch (e) {
      print('Errore nel conteggio dei trades disponibili: $e');
      return 0;
    }
  }

  // Add a trade
  Future<void> addTrade(String cardId, bool isWanted, String userId) async {
    try {
      await supabase.from('pokemon_trades').insert({
        'user_id': userId,
        'card_id': cardId,
        'is_wanted': isWanted,
      });
    } catch (e) {
      print('Errore nell\'aggiunta del trade: $e');
      rethrow;
    }
  }

  // Remove a trade
  Future<void> removeTrade(String tradeId) async {
    try {
      final response = await supabase.from('pokemon_trades').delete().eq('id', tradeId).select();
      if (response.isEmpty) {
        throw Exception('Nessun trade rimosso: ID non trovato');
      }
    } catch (e) {
      print('Errore nella rimozione del trade: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}