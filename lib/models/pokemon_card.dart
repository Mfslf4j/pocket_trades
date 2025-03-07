class PokemonCard {
  final String id;
  final String imageUrl;
  final String name;
  final String expansion;
  final String expansionNumber;

  PokemonCard({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.expansion,
    required this.expansionNumber,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    return PokemonCard(
      id: json['id'],
      imageUrl: json['image_url'],
      name: json['name'],
      expansion: json['expansion'],
      expansionNumber: json['expansion_number'].toString(),
    );
  }
}
