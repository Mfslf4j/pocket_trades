import 'package:flutter/material.dart';

class PokemonCardWidget extends StatelessWidget {
  final String imageUrl;
  final String name;
  final bool isOfferedByUser;
  final bool isWantedByUser;
  final int offeredCount;
  final int wantedCount;
  final VoidCallback? onTap;
  final VoidCallback? onOfferPressed;
  final VoidCallback? onWantPressed;
  final VoidCallback? onRemoveOfferPressed;
  final VoidCallback? onRemoveWantPressed;

  const PokemonCardWidget({
    super.key,
    required this.imageUrl,
    required this.name,
    this.isOfferedByUser = false,
    this.isWantedByUser = false,
    this.offeredCount = 0,
    this.wantedCount = 0,
    this.onTap,
    this.onOfferPressed,
    this.onWantPressed,
    this.onRemoveOfferPressed,
    this.onRemoveWantPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6, // Ombra più pronunciata
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordi più stondati
        clipBehavior: Clip.antiAlias, // Ritaglia il contenuto per rispettare i bordi stondati
        child: Stack(
          children: [
            // Immagine di sfondo
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) =>
                loadingProgress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 40, color: Colors.grey),
              ),
            ),
            // Gradiente sopra l'immagine per un effetto visivo
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Pulsanti in alto a sinistra
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    if (!isOfferedByUser && !isWantedByUser) ...[
                      IconButton(
                        icon: const Icon(Icons.swap_horiz, size: 20, color: Colors.green),
                        onPressed: onOfferPressed,
                        tooltip: 'Segna come offerto',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, size: 20, color: Colors.red),
                        onPressed: onWantPressed,
                        tooltip: 'Segna come cercato',
                      ),
                    ],
                    if (isOfferedByUser)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: onRemoveOfferPressed,
                        tooltip: 'Rimuovi dagli offerti',
                      ),
                    if (isWantedByUser)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: onRemoveWantPressed,
                        tooltip: 'Rimuovi dai cercati',
                      ),
                  ],
                ),
              ),
            ),
            // Conteggi in alto a destra
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.swap_horiz, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '$offeredCount',
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.add_shopping_cart, size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '$wantedCount',
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Nome in basso con design migliorato
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}