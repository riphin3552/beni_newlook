import 'package:beni_newlook/Rapports/SectionsPrincipales.dart';
import 'package:beni_newlook/pages/SectionAuxiliaire.dart';
import 'package:flutter/material.dart';

class BridgeSection extends StatefulWidget {
  final int identreprise;
  const BridgeSection({super.key, required this.identreprise});

  @override
  State<BridgeSection> createState() => _BridgeSectionState();
}

class _BridgeSectionState extends State<BridgeSection> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0D47A1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sections'),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
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
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des Sections',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Organisez vos sections principales et auxiliaires',
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
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSmartCard(
                      context,
                      index: 0,
                      icon: Icons.bar_chart,
                      title: 'Sections Principales',
                      description: 'Gérer les sections principales',
                      color: const Color(0xFF5E35B1),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              child: SizedBox(
                                width: 650,
                                height: 520,
                                child: Sectionsprincipales(
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
                      icon: Icons.splitscreen_outlined,
                      title: 'Sections Auxiliaires',
                      description: 'Gérer les sections auxiliaires',
                      color: const Color(0xFF1976D2),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              child: SizedBox(
                                width: 650,
                                height: 500,
                                child: Sectionauxiliaire(
                                  iDentreprise: widget.identreprise,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isHovered ? 0.25 : 0.08),
                blurRadius: isHovered ? 20 : 8,
                offset: Offset(0, isHovered ? 8 : 4),
              ),
            ],
            border: Border.all(
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isHovered ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: isHovered ? 50 : 44,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isHovered) ...[
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward,
                      size: 20,
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