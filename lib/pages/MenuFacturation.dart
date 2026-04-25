import 'package:beni_newlook/PageCommande.dart';
import 'package:beni_newlook/pages/facturationAutreServices.dart';
import 'package:beni_newlook/pages/facturationChambreEspace.dart';
import 'package:flutter/material.dart';

class Menufacturation extends StatefulWidget {
  final int idEntreprise;
  final String titreMenuFacturation;
  const Menufacturation({super.key, required this.idEntreprise, required this.titreMenuFacturation});

  @override
  State<Menufacturation> createState() => _MenufacturationState();
}

class _MenufacturationState extends State<Menufacturation> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0D47A1);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
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
                    Icons.receipt_long_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titreMenuFacturation,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gérez la facturation de vos différents services',
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
          
          // Content Grid
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.start,
                  children: [
                    _buildSmartCard(
                      context,
                      index: 0,
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Nourriture et boisson',
                      description: 'Ventes restaurant et bar',
                      color: const Color(0xFF1976D2),
                      onTap: () {
                        showAboutDialog(context: context, children: [
                          SizedBox(
                            width: 850,
                            height: 650,
                            child: CommandePage(
                              idEntreprise: widget.idEntreprise,
                            ),
                          ),
                        ]);
                      },
                    ),
                    _buildSmartCard(
                      context,
                      index: 1,
                      icon: Icons.bedroom_parent_rounded,
                      title: 'Facture Espace/Chambre',
                      description: 'Règlements des réservations',
                      color: const Color(0xFF388E3C),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              child: SizedBox(
                                width: 850,
                                height: 650,
                                child: FacturationchambreEspace(
                                  identreprise: widget.idEntreprise,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    _buildSmartCard(
                      context,
                      index: 2,
                      icon: Icons.miscellaneous_services_rounded,
                      title: 'Facture autres services',
                      description: 'Services auxiliaires',
                      color: const Color(0xFFF57C00),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              child: SizedBox(
                                width: 650,
                                height: 500,
                                child: FactureAutreServices(
                                  idEntreprise: widget.idEntreprise,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    _buildSmartCard(
                      context,
                      index: 3,
                      icon: Icons.account_balance_rounded,
                      title: 'Facture globale',
                      description: 'Synthèse de facturation globale',
                      color: const Color(0xFF7B1FA2),
                      onTap: () {
                        // Action for Global Billing
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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