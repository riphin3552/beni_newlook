import 'package:beni_newlook/Rapports/EspacesChambresDisponibles.dart';
import 'package:beni_newlook/Rapports/FicheDeStock.dart';
import 'package:beni_newlook/Rapports/EspacesChambresOccupes.dart';
import 'package:beni_newlook/Rapports/EvoltionReservations.dart';
import 'package:beni_newlook/Rapports/ListeProduits.dart';
import 'package:beni_newlook/Rapports/RapportDepensesCharges.dart';
import 'package:beni_newlook/Rapports/RapportEntreesEncaissements.dart';
import 'package:beni_newlook/Rapports/RapportStatistiqueHebergement.dart';
import 'package:beni_newlook/Rapports/RapportStocks.dart';
import 'package:beni_newlook/session_utilisateur.dart';
import 'package:flutter/material.dart';

class MenuRapports extends StatefulWidget {
  final String titreMenuRapports;
  final int identreprise;
  final int idUtilisateur;

  const MenuRapports({
    super.key,
    required this.titreMenuRapports,
    required this.identreprise,
    required this.idUtilisateur,
  });

  @override
  State<MenuRapports> createState() => _MenuRapportsState();
}

class _MenuRapportsState extends State<MenuRapports> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0D47A1);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du menu
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  // ignore: deprecated_member_use
                  color: primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titreMenuRapports,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consultez et exportez les rapports de votre établissement',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Grille d'options
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.start,
                  children: _buildCartesPourRole(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Le Serveur ne voit que la Fiche de Stock (filtree a sa section cote serveur).
  // Gerant/Comptable/Caissier voient tous les rapports.
  List<Widget> _buildCartesPourRole(BuildContext context) {
    final ficheDeStock = _buildSmartCard(
      context,
      index: 8,
      icon: Icons.table_chart_outlined,
      title: 'Fiche de Stock',
      description: 'Mouvements stock par section',
      color: const Color(0xFF1565C0),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FicheDeStock(identreprise: widget.identreprise),
          ),
        );
      },
    );

    if (SessionUtilisateur.isServeur) {
      return [ficheDeStock];
    }

    return [
      _buildSmartCard(
        context,
        index: 0,
        icon: Icons.inventory_2_outlined,
        title: 'Rapport Stocks',
        description: 'État des stocks disponibles',
        color: const Color(0xFF1976D2),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PdfPreviewPage(idEse: widget.identreprise),
            ),
          );
        },
      ),
      _buildSmartCard(
        context,
        index: 1,
        icon: Icons.list_alt_outlined,
        title: 'Liste des produits',
        description: 'Catalogue des produits',
        color: const Color(0xFF388E3C),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PdfPreviewPAGE(idEse: widget.identreprise),
            ),
          );
        },
      ),
      _buildSmartCard(
        context,
        index: 2,
        icon: Icons.bedroom_parent_outlined,
        title: 'Chambres disponibles',
        description: 'Espaces et chambres libres',
        color: const Color(0xFF00897B),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EspacesDisponiblesReportPage(idEse: widget.identreprise),
            ),
          );
        },
      ),
      _buildSmartCard(
        context,
        index: 3,
        icon: Icons.hotel_outlined,
        title: 'Chambres occupées',
        description: 'Espaces et chambres en cours',
        color: const Color(0xFFD32F2F),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EspacesOccupesReportPage(idEse: widget.identreprise),
            ),
          );
        },
      ),
      _buildSmartCard(
        context,
        index: 4,
        icon: Icons.trending_up_outlined,
        title: 'Évolution réservations',
        description: 'Historique des réservations',
        color: const Color(0xFF7B1FA2),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EvolutionReservations(identreprise: widget.identreprise),
            ),
          );
        },
      ),
      _buildSmartCard(
        context,
        index: 5,
        icon: Icons.money_off_outlined,
        title: 'Dépenses / Charges',
        description: 'Rapport des sorties de caisse',
        color: const Color(0xFFF57C00),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RapportDepensesCharges(identreprise: widget.identreprise),
            ),
          );
        },
      ),
      _buildSmartCard(
        context,
        index: 6,
        icon: Icons.savings_outlined,
        title: 'Entrées / Encaissements',
        description: 'Rapport des entrées en caisse',
        color: const Color(0xFF388E3C),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RapportEntreesEncaissements(
                  identreprise: widget.identreprise),
            ),
          );
        },
      ),
      _buildSmartCard(
        context,
        index: 7,
        icon: Icons.analytics_outlined,
        title: 'Statistiques Hébergement',
        description: 'Rendement chambres et espaces',
        color: const Color(0xFF0D47A1),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RapportStatistiqueHebergement(
                  identreprise: widget.identreprise),
            ),
          );
        },
      ),
      ficheDeStock,
    ];
  }

  Widget _buildSmartCard(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: color.withOpacity(isHovered ? 0.25 : 0.08),
                blurRadius: isHovered ? 20 : 8,
                offset: Offset(0, isHovered ? 8 : 4),
              ),
            ],
            border: Border.all(
              // ignore: deprecated_member_use
              color: isHovered ? color.withOpacity(0.5) : Colors.grey[200]!,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Transform.scale(
            scale: isHovered ? 1.02 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: color.withOpacity(isHovered ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: isHovered ? 44 : 38,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Flexible(
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isHovered) ...[
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: color,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
