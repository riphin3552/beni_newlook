import 'package:beni_newlook/ReservationChambreEspace.dart';
import 'package:beni_newlook/pages/AjouterClient.dart';
import 'package:beni_newlook/pages/ChambreEspace.dart';
import 'package:beni_newlook/pages/facturationChambreEspace.dart';
import 'package:flutter/material.dart';

class MenuGestionlogement extends StatefulWidget {
    final String titreMenuGestionLogement;
    final int identreprise;
  const MenuGestionlogement({super.key, required this.titreMenuGestionLogement, required this.identreprise});

  @override
  State<MenuGestionlogement> createState() => _MenuGestionlogementState();
}

class _MenuGestionlogementState extends State<MenuGestionlogement> {
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
                    Icons.inventory_2,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titreMenuGestionLogement,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gérez vos logements et réservations efficacement',
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
                    icon: Icons.bedroom_parent_rounded,
                    title: 'Chambre/Espace',
                    description: 'Créer et gérer',
                    color: Color(0xFF1976D2),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 670,
                              height: 560,
                              child: Chambreespace(
                                identreprise: widget.identreprise,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 1,
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Ajouter client',
                    description: 'Créer un nouveau client',
                    color: Color(0xFF388E3C),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 650,
                              height: 500,
                              child: AjouterClient(
                                identreprise: widget.identreprise,
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
                    icon: Icons.bookmark_add_rounded,
                    title: 'Nouvelle réservation',
                    description: 'Prets à réserver',
                    color: Color(0xFFF57C00),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 720,
                              height: 580,
                              child: Reservation(
                                identreprise: widget.identreprise,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 6,
                    icon: Icons.receipt_long_rounded,
                    title: 'Facturation',
                    description: 'Facturation de reservation',
                    color: Color(0xFF00796B),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 720,
                              height: 580,
                              child: FacturationchambreEspace(
                                identreprise: widget.identreprise,
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
                    icon: Icons.room_service_rounded,
                    title: 'C/E occupés',
                    description: 'En cours d\'occupation',
                    color: Color(0xFF7B1FA2),
                    onTap: () {
                      // code
                  //     showDialog(
                  //       context: context,
                  //       builder: (BuildContext context) {
                  //         return Dialog(
                  //           child: SizedBox(
                  //             width: 650,
                  //             height: 520,
                  //             child: TypeStock(
                  //               identreprise: widget.identreprise,
                  //             ),
                  //           ),
                  //         );
                  //   },
                  // );
                },
                  ),
                  _buildSmartCard(
                    context,
                    index: 4,
                    icon: Icons.check_circle_outline_rounded,
                    title: 'C/E disponibles',
                    description: 'Prêts à être occupés',
                    color: Color(0xFFD32F2F),
                    onTap: () {
                      // code
                      // showDialog(
                      //   context: context,
                      //   builder: (BuildContext context) {
                      //     return Dialog(
                      //       child: SizedBox(
                      //         width: 880,
                      //         height: 600,
                      //         child: Entreestock(
                      //           identreprise: widget.identreprise,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // );
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 5,
                    icon: Icons.inventory,
                    title: 'Liste des reservations',
                    description: 'nos reservations',
                    color: Color(0xFF0097A7),
                    onTap: () {
                      // code
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => PdfPreviewPAGE(idEse: widget.identreprise),
                      //   )
                      //   );
                    },
                  ),
                  
                  _buildSmartCard(
                    context,
                    index: 7,
                    icon: Icons.bar_chart,
                    title: 'SECTIONS',
                    description: 'sections principales',
                    color: Color(0xFF5E35B1),
                    onTap: () {
                      // code
                      // showDialog(
                      //   context: context,
                      //   builder: (BuildContext context) {
                      //     return Dialog(
                      //       child: SizedBox(
                      //         width: 650,
                      //         height: 520,
                      //         child: BridgeSection(
                      //           identreprise: widget.identreprise,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // );
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
                  // Animated Icon Container
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
                  
                  // Title
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
                  
                  // Description
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