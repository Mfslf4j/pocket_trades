class PokemonCard {
  final String id;
  final String name;
  final String imageUrl;
  final String expansion;
  bool isOffered;
  bool isWanted;
  int? offeredCount;
  int? wantedCount;

  PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.expansion,
    this.isOffered = false,
    this.isWanted = false,
    this.offeredCount,
    this.wantedCount,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    return PokemonCard(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      expansion: json['expansion'],
    );
  }
}