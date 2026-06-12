import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BridgeStatistiques extends StatefulWidget {
  final int identreprise;
  const BridgeStatistiques({super.key, required this.identreprise});

  @override
  State<BridgeStatistiques> createState() => _BridgeStatistiquesState();
}

class _BridgeStatistiquesState extends State<BridgeStatistiques> {
  int _hoveredIndex = -1;
  late Future<Map<String, dynamic>> _statsFuture;
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialisation des dates sur les 7 derniers jours par défaut
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    _dateFinController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _dateDebutController.text = "${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}";
    
    _statsFuture = fetchRoomStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = fetchRoomStats();
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
      _refreshStats();
    }
  }

  Future<Map<String, dynamic>> fetchRoomStats() async {
    try {
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/StatistiquesOccupationChambre.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "entreprise": widget.identreprise,
          "date_debut": _dateDebutController.text, // Corrected key to match PHP API
          "date_fin": _dateFinController.text,     // Corrected key to match PHP API
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('statistiques_chambres_jours')) {
          return data['statistiques_chambres_jours'];
        }
      }
      // Return default values if API call fails or data is not as expected
      return {
        "total_existantes_jours": 0,
        "total_occupees_jours": 0,
        "total_maintenance_jours": 0,
        "total_bloquees_jours": 0,
        "total_disponibles_jours": 0,
        "total_non_occupees_jours": 0,
        "taux_occupation_reel_pourcent": 0.0
      };
    } catch (e) {
      print("Error fetching room stats: $e"); // Log the error for debugging
      return {
        "total_existantes_jours": 0,
        "total_occupees_jours": 0,
        "total_maintenance_jours": 0,
        "total_bloquees_jours": 0,
        "total_disponibles_jours": 0,
        "total_non_occupees_jours": 0,
        "taux_occupation_reel_pourcent": 0.0
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0D47A1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Chambres'),
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
                        'Statistiques mensuelles d\'occupation',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aperçu en temps réel de l\'état de vos chambres',
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
            // Filtres de date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateDebutController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Date Début",
                            prefixIcon: const Icon(Icons.calendar_today, size: 20, color: Color.fromARGB(255, 121, 169, 240)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onTap: () => _selectDate(context, _dateDebutController),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _dateFinController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Date Fin",
                            prefixIcon: const Icon(Icons.event, size: 20, color: Color.fromARGB(255, 121, 169, 240)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onTap: () => _selectDate(context, _dateFinController),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final stats = snapshot.data ?? {};
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildOccupancyRateHeader(context, stats['taux_occupation_reel_pourcent'] ?? 0),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildSmartCard(
                                context,
                                index: 0,
                                icon: Icons.bedroom_parent_outlined,
                                title: 'Total des chambres',
                                value: stats['total_existantes_jours']?.toString() ?? '0',
                                color: const Color(0xFF0D47A1),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 1,
                                icon: Icons.door_front_door,
                                title: 'Chambres occupées',
                                value: stats['total_occupees_jours']?.toString() ?? '0',
                                color: const Color(0xFF7B1FA2),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 2,
                                icon: Icons.check_circle_outline,
                                title: 'Chambres disponibles',
                                value: stats['total_disponibles_jours']?.toString() ?? '0',
                                color: const Color(0xFF388E3C),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 3,
                                icon: Icons.build_outlined,
                                title: 'Chambres en maintenance',
                                value: stats['total_maintenance_jours']?.toString() ?? '0',
                                color: const Color(0xFFF57C00),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 4,
                                icon: Icons.block_outlined,
                                title: 'Chambres bloquées',
                                value: stats['total_bloquees_jours']?.toString() ?? '0',
                                color: const Color(0xFFD32F2F),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 5,
                                icon: Icons.meeting_room_outlined,
                                title: 'Chambres non occupées',
                                value: stats['total_non_occupees_jours']?.toString() ?? '0',
                                color: const Color(0xFF455A64),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyRateHeader(BuildContext context, dynamic rate) {
    final double percentage = (rate is num) ? rate.toDouble() : 0.0;
    
    Color getProgressColor(double p) {
      if (p >= 70) return Colors.green;
      if (p >= 40) return Colors.orange;
      return Colors.red;
    }

    return Container(
      width: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Taux d'occupation réel",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(percentage)),
                ),
              ),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
    required String value,
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
          width: 165,
          height: 165,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isHovered ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: isHovered ? 36 : 32,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                            fontSize: 13,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color,
                            fontSize: 20,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
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