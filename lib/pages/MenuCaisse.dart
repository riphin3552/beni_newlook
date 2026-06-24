import 'package:beni_newlook/pages/EntreeCaisse.dart';
import 'package:beni_newlook/pages/LivreCaisse.dart';
import 'package:beni_newlook/pages/SortieCaisse.dart';
import 'package:flutter/material.dart';

class MenuCaisse extends StatefulWidget {
  final String titreMenuCaisse;
  final int identreprise;
  final int idUtilisateur;

  const MenuCaisse({
    super.key,
    required this.titreMenuCaisse,
    required this.identreprise,
    required this.idUtilisateur,
  });

  @override
  State<MenuCaisse> createState() => _MenuCaisseState();
}

class _MenuCaisseState extends State<MenuCaisse> {
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
                    Icons.account_balance_wallet,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titreMenuCaisse,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gérez les flux financiers et le suivi de caisse',
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
                  children: [
                  _buildSmartCard(
                    context,
                    index: 0,
                    icon: Icons.add_circle_outline,
                    title: 'Entree en caisse',
                    description: 'Enregistrer une entrée',
                    color: const Color(0xFF388E3C),
                    onTap: () {
                      // Action pour Entree en caisse
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Entreecaisse(identreprise: widget.identreprise, idUtilisateur: widget.idUtilisateur)
                        ),
                      );
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 1,
                    icon: Icons.remove_circle_outline,
                    title: 'Sortie de caisse',
                    description: 'Gérer les dépenses',
                    color: const Color(0xFFD32F2F),
                    onTap: () {
                      // Action pour Sortie de caisse
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SortieCaisse(identreprise: widget.identreprise, idUtilisateur: widget.idUtilisateur)
                        ),
                      );
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 2,
                    icon: Icons.payments_outlined,
                    title: 'Recouvrement creances',
                    description: 'Suivi des paiements',
                    color: const Color(0xFF1976D2),
                    onTap: () {
                      // Action pour Recouvrement creances
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 3,
                    icon: Icons.auto_stories_outlined,
                    title: 'Livre de caisse',
                    description: 'Journal des opérations',
                    color: const Color(0xFFF57C00),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LivreCaisse(
                            identreprise: widget.identreprise,
                            idUtilisateur: widget.idUtilisateur,
                          ),
                        ),
                      );
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